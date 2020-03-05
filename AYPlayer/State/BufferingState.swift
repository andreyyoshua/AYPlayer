//
//  BufferingState.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

public final class BufferingState: AYPlayerStateProtocol {
    // MARK: - Inputs

    public var manager: AYPlayerManager
    private var rateObservingService: AYRateObservingServiceProtocol
    private var interruptionAudioService: AYInterruptionAudioServiceProtocol
    private var playerCurrentTime: Double { return manager.currentTime }

    // MARK: - Variable

    public let type: AYPlayerManager.State = .buffering

    // MARK: - Init

    init(manager: AYPlayerManager,
         rateObservingService: AYRateObservingService? = nil,
         interruptionAudioService: AYInterruptionAudioServiceProtocol = AYPlayerInterruptionAudioService()) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleState)
        guard let item = manager.currentItem else { fatalError("item should exist") }
        self.manager = manager
        self.rateObservingService = rateObservingService ?? AYRateObservingService(config: manager.config, item: item)
        self.interruptionAudioService = interruptionAudioService

        setupRateObservingCallback()
        setupInterruptionCallback()
    }

    public func managerUpdated() {
        // TODO: Media will be used later
//        guard let media = manager.currentMedia
//        else { assertionFailure("media should exist"); return }
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleState)
    }

    // MARK: - Setup

    private func setupRateObservingCallback() {
        rateObservingService.onTimeout = { [manager] in
            let state = WaitingNetworkState(manager: manager, autostart: true, error: .bufferingFailed)
            manager.changeState(state: state)
        }

        guard let _ = manager.currentMedia
        else { assertionFailure("media should exist"); return }

        rateObservingService.onPlaying = { [manager] in
            let playbackService = AYPlayerPlaybackObservingService(player: manager.player)
            manager.changeState(state: PlayingState(manager: manager, itemPlaybackObservingService: playbackService))
        }
    }

    private func setupInterruptionCallback() {
        interruptionAudioService.onInterruptionBegan = { [weak self] in self?.pause() }
    }

    // MARK: - Player Commands

    func seekCommand(position: Double) {
        manager.currentItem?.cancelPendingSeeks()
        let time = CMTime(seconds: position, preferredTimescale: manager.config.preferredTimescale)
        manager.player.seek(to: time) { [weak self] completed in
            guard completed, let self = self else { return }
            self.manager.delegate?.playerManager(didCurrentTimeChange: self.manager.currentTime, withTotalDuration: self.manager.itemDuration)
            self.play()
        }
    }

    public func load(media: AYPlayerMediaProtocol, autostart: Bool, position: Double?) {
        let state = LoadingState(manager: manager, media: media, autostart: autostart, position: position)
        changeState(state)
    }

    public func pause() {
        changeState(PausedState(manager: manager))
    }

    public func play() {
        rateObservingService.start()
        manager.player.play()
    }

    public func seek(position: Double) {
        seekCommand(position: position)
    }

    public func stop() {
        changeState(StoppedState(manager: manager))
    }

    // MARK: - Private

    private func changeState(_ state: AYPlayerStateProtocol) {
        rateObservingService.stop(clearCallbacks: true)
        manager.currentItem?.cancelPendingSeeks()
        manager.changeState(state: state)
    }
}
