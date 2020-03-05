//
//  InitializationState.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

public final class InitializationState: AYPlayerStateProtocol {
    // MARK: - Input

    public unowned let manager: AYPlayerManager

    // MARK: - Variables

    public let type: AYPlayerManager.State = .initialization

    // MARK: - Init

    public init(manager: AYPlayerManager) {
        AYPlayerLogger.instance.log(message: "Inititalization", domain: .lifecycleState)
        self.manager = manager
    }

    public func managerUpdated() {
        manager.player.automaticallyWaitsToMinimizeStalling = false
    }

    // MARK: - Shared Actions

    public func load(media: AYPlayerMediaProtocol, autostart: Bool, position: Double? = nil) {
        let state = LoadingState(manager: manager, media: media, autostart: autostart, position: position)
        manager.changeState(state: state)
    }

    public func pause() {
        manager.changeState(state: PausedState(manager: manager))
    }

    public func play() {
        let debug = "Load item before playing"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .loadMediaFirst)
    }

    public func seek(position _: Double) {
        let debug = "Load item before seeking"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .loadMediaFirst)
    }

    public func stop() {
        manager.changeState(state: StoppedState(manager: manager))
    }
}
