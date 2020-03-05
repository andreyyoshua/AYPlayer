//
//  LoadingState.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

public final class LoadingState: AYPlayerStateProtocol {
    // MARK: - Input

    public unowned let manager: AYPlayerManager

    // MARK: - Variables

    public let type: AYPlayerManager.State = .loading
    private let media: AYPlayerMediaProtocol
    private var autostart: Bool
    private var position: Double?
    private var itemStatusObserving: AYPlayerStatusObservingService?
    private var interruptionAudioService: AYInterruptionAudioServiceProtocol

    // MARK: - Init

    public init(manager: AYPlayerManager,
                media: AYPlayerMediaProtocol,
                autostart: Bool,
                position: Double? = nil,
                interruptionAudioService: AYInterruptionAudioServiceProtocol = AYPlayerInterruptionAudioService()) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleState)

        self.manager = manager
        self.media = media
        self.autostart = autostart
        self.position = position
        self.interruptionAudioService = interruptionAudioService
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleState)
    }

    public func managerUpdated() {
        setupInterruptionCallback()

        guard let media = manager.currentMedia
        else { assertionFailure("media should exist"); return }
        processMedia(media)
    }

    // MARK: - Shared actions

    public func load(media: AYPlayerMediaProtocol, autostart: Bool, position: Double?) {
        self.position = position
        self.autostart = autostart
        processMedia(media)
    }

    public func pause() {
        cancelMediaLoading()
        manager.changeState(state: PausedState(manager: manager))
    }

    public func play() {
        let debug = "Wait media to be loaded before playing"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .waitLoadedMedia)
    }

    public func seek(position _: Double) {
        let debug = "Wait media to be loaded before seeking"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .waitLoadedMedia)
    }

    public func stop() {
        cancelMediaLoading()
        manager.player.replaceCurrentItem(with: nil)
        manager.changeState(state: StoppedState(manager: manager))
    }

    // MARK: - Private actions

    private func cancelMediaLoading() {
        manager.currentItem?.asset.cancelLoading()
        manager.currentItem?.cancelPendingSeeks()
    }

    private func processMedia(_ media: AYPlayerMediaProtocol) {
        let asset = AVURLAsset(url: media.url, options: media.assetOptions)
        asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: nil) // preloading master playlist

        let playerItem = AVPlayerItem(asset: asset)
        playerItem.audioTimePitchAlgorithm = .spectral // highest audio quality
        
        manager.performanceMeasurement = AYPlayerPerformanceMeasurementsService(playerItem: playerItem)

        startObservingItemStatus(item: playerItem)
        manager.player.replaceCurrentItem(with: playerItem)

        guard position == nil else { return }
        manager.delegate?.playerManager(didCurrentTimeChange: manager.currentTime, withTotalDuration: manager.itemDuration)
    }

    private func startObservingItemStatus(item: AVPlayerItem) {
        itemStatusObserving = AYPlayerStatusObservingService(item: item) { [weak self] status in
            self?.moveToNextState(with: status)
        }
    }

    private func setupInterruptionCallback() {
        interruptionAudioService.onInterruptionBegan = { [weak self] in self?.pause() }
    }

    private func moveToNextState(with status: AVPlayerItem.Status) {
        switch status {
        case .unknown:
            assertionFailure()
        case .failed:
            let state = FailedState(manager: manager, error: .loadingFailed)
            manager.changeState(state: state)
        case .readyToPlay:
            guard let position = self.position else { moveToBufferingState(); return }
            let seekPosition = CMTime(seconds: position, preferredTimescale: manager.config.preferredTimescale)
            manager.player.seek(to: seekPosition) { [weak self] completed in
                guard let self = self else { return }
                self.manager.delegate?.playerManager(didCurrentTimeChange: self.manager.currentTime, withTotalDuration: self.manager.itemDuration)
                guard completed else { return }
                self.moveToBufferingState()
            }
        @unknown default:
            AYPlayerLogger.instance.log(message: "Unknown PlayerItem Status case", domain: .error)
        }
    }

    private func moveToBufferingState() {
        let state = BufferingState(manager: manager)
        if autostart { state.play() }
    }
}
