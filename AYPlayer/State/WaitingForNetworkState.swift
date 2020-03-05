//
//  WaitingForNetworkState.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 05/03/20.
//

import AVFoundation

public final class WaitingNetworkState: AYPlayerStateProtocol {
    // MARK: - Inputs

    public let manager: AYPlayerManager
    private var reachability: AYPlayerReachabilityService

    // MARK: - Variable

    public let type: AYPlayerManager.State = .waitingForNetwork

    // MARK: - Init

    init(manager: AYPlayerManager,
         autostart: Bool,
         error: AYPlayerError,
         reachabilityService: AYPlayerReachabilityService? = nil) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleState)
        self.manager = manager
        reachability = reachabilityService ?? AYPlayerReachabilityService(config: manager.config)
        setupReachabilityCallbacks(autostart: autostart, error: error)
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleState)
    }

    public func managerUpdated() {
        reachability.start()
        guard let media = manager.currentMedia
        else { assertionFailure("media should exist"); return }

        guard let mediaItem = media as? AYPlayerMediaItem
        else { return }
        manager.failedUsedAVPlayerItem.insert(mediaItem.item)
    }

    // MARK: - Reachability

    private func setupReachabilityCallbacks(autostart _: Bool, error: AYPlayerError) {
        reachability.isTimedOut = { [weak self] in
            guard let self = self else { return }

            let failedState = FailedState(manager: self.manager, error: error)
            self.manager.changeState(state: failedState)
        }

        reachability.isReachable = { [weak self] in
            guard let _ = self?.manager.currentMedia else { assertionFailure(); return }
            guard let self = self else { return }
            let state = BufferingState(manager: self.manager)
            self.manager.changeState(state: state)
            state.play()
        }
    }

    private func isDurationItemFinite() -> Bool {
        return manager.itemDuration?.isFinite ?? false
    }

    // MARK: - Shared actions

    public func load(media: AYPlayerMediaProtocol, autostart: Bool, position: Double? = nil) {
        let state = LoadingState(manager: manager, media: media, autostart: autostart, position: position)
        manager.changeState(state: state)
    }

    public func pause() {
        manager.changeState(state: PausedState(manager: manager))
    }

    public func play() {
        let debug = "Reload a media first before playing"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .waitEstablishedNetwork)
    }

    public func seek(position _: Double) {
        let debug = "Reload a media first before seeking"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .waitEstablishedNetwork)
    }

    public func stop() {
        manager.changeState(state: StoppedState(manager: manager))
    }
}
