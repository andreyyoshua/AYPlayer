//
//  StoppedState.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

public final class StoppedState: PausedState {
    // MARK: Init

    init(manager: AYPlayerManager) {
        super.init(manager: manager, type: .stopped)

        seek(position: 0)
    }

    public override func managerUpdated() {}

    // MARK: - Shared actions

    public override func pause() {
        manager.changeState(state: PausedState(manager: manager))
    }

    public override func stop() {
        let debug = "Already stopped"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .alreadyStopped)
    }
}
