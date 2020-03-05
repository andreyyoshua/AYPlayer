//
//  FailedState.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

final class FailedState: AYPlayerStateProtocol {
    // MARK: - Input

    public unowned let manager: AYPlayerManager
    private let error: AYPlayerError

    // MARK: - Variable

    let type: AYPlayerManager.State = .failed

    // MARK: - Init

    init(manager: AYPlayerManager, error: AYPlayerError) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleState)
        self.manager = manager
        self.error = error
    }

    func managerUpdated() {
        guard let media = manager.currentMedia
        else { assertionFailure("media should exist"); return }
        guard let mediaItem = media as? AYPlayerMediaItem
        else { return }
        manager.failedUsedAVPlayerItem.insert(mediaItem.item)
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleState)
    }

    // MARK: - Shared actions

    func load(media: AYPlayerMediaProtocol, autostart: Bool, position: Double? = nil) {
        let state = LoadingState(manager: manager, media: media, autostart: autostart, position: position)
        manager.changeState(state: state)
    }

    func pause() {
        let debug = "Unable to pause, load a media first"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .loadMediaFirst)
    }

    func play() {
        guard let media = manager.currentMedia
        else { assertionFailure("should not possible to be in failed state without load any media"); return }

        let state = LoadingState(manager: manager, media: media, autostart: true)
        manager.changeState(state: state)
    }

    func seek(position _: Double) {
        let debug = "Unable to seek, load a media first"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .loadMediaFirst)
    }

    func stop() {
        let debug = "Unable to stop, load a media first"
        AYPlayerLogger.instance.log(message: debug, domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableActionReason: .loadMediaFirst)
    }
}
