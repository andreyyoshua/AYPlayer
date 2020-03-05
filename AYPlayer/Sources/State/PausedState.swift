//
//  PauseState.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

public class PausedState: AYPlayerStateProtocol {
    // MARK: - Inputs

    public unowned let manager: AYPlayerManager
    private let interruptionAudioService: AYPlayerInterruptionAudioService

    // MARK: - Output

    var onInterruptionEnded: (() -> Void)? {
        didSet { interruptionAudioService.onInterruptionEnded = onInterruptionEnded }
    }

    // MARK: - Variable

    public let type: AYPlayerManager.State

    // MARK: Init

    init(manager: AYPlayerManager,
         type: AYPlayerManager.State = .paused,
         interruptionAudioService: AYPlayerInterruptionAudioService = AYPlayerInterruptionAudioService()) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleState)
        self.manager = manager
        self.type = type
        self.interruptionAudioService = interruptionAudioService
        self.manager.player.pause()
    }

    public func managerUpdated() {}

    public func load(media: AYPlayerMediaProtocol, autostart: Bool, position: Double?) {
        let state = LoadingState(manager: manager, media: media, autostart: autostart, position: position)
        manager.changeState(state: state)
    }

    public func pause() {
        let debug = "Already paused"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .alreadyPaused)
    }

    public func play() {
        if manager.currentItem?.status == .readyToPlay {
            let state = BufferingState(manager: manager)
            manager.changeState(state: state)
            state.play()
        } else if let media = manager.currentMedia {
            let state = LoadingState(manager: manager, media: media, autostart: true)
            manager.changeState(state: state)
        } else {
            let debug = "Load media before playing"
            AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
            manager.delegate?.playerManager(unavailableActionReason: .loadMediaFirst)
        }
    }

    public func seek(position: Double) {
        let time = CMTime(seconds: position, preferredTimescale: manager.config.preferredTimescale)
        manager.player.seek(to: time) { [weak self] completed in
            guard completed, let manager = self?.manager else { return }
            manager.delegate?.playerManager(didCurrentTimeChange: manager.currentTime, withTotalDuration: manager.itemDuration)
        }
    }

    public func stop() {
        manager.changeState(state: StoppedState(manager: manager))
    }
}
