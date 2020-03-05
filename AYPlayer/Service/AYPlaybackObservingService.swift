//
//  AYPlaybackObservingService.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

// sourcery: AutoMockable
protocol AYPlaybackObservingServiceProtocol {
    var onPlaybackStalled: (() -> Void)? { get set }
    var onPlayToEndTime: (() -> Void)? { get set }
    var onFailedToPlayToEndTime: (() -> Void)? { get set }
}

final class AYPlayerPlaybackObservingService: AYPlaybackObservingServiceProtocol {
    // MARK: - Input

    private let player: AVPlayer

    // MARK: - Outputs

    var onPlaybackStalled: (() -> Void)?
    var onPlayToEndTime: (() -> Void)?
    var onFailedToPlayToEndTime: (() -> Void)?

    // MARK: - Init

    init(player: AVPlayer) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleService)
        self.player = player
        NotificationCenter.default.addObserver(self, selector: #selector(AYPlayerPlaybackObservingService.itemPlaybackStalled),
                                               name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AYPlayerPlaybackObservingService.itemPlayToEndTime),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AYPlayerPlaybackObservingService.itemFailedToPlayToEndTime),
                                               name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: nil)
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleService)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
                                                  object: nil)
    }

    private func hasReallyReachedEndTime(player: AVPlayer) -> Bool {
        guard
            let duration = player.currentItem?.duration.seconds
        else { return false }

        /// item current time when receive end time notification
        /// is not so accurate according to duration
        /// added +1 make sure about the computation
        let currentTime = player.currentTime().seconds + 1
        return currentTime >= duration
    }

    @objc
    private func itemPlaybackStalled() {
        AYPlayerLogger.instance.log(message: "Item playback stalled notification", domain: .service)
        onPlaybackStalled?()
    }

    ///
    ///  AVPlayerItemDidPlayToEndTime notification can be triggered when buffer is empty and network is out.
    ///  We manually check if item has really reached his end time.
    ///
    @objc
    private func itemPlayToEndTime() {
        guard hasReallyReachedEndTime(player: player) else { itemFailedToPlayToEndTime(); return }
        AYPlayerLogger.instance.log(message: "Item play to end time notification", domain: .service)
        onPlayToEndTime?()
    }

    @objc
    private func itemFailedToPlayToEndTime() {
        AYPlayerLogger.instance.log(message: "Item failed to play endtime notification", domain: .service)
        onFailedToPlayToEndTime?()
    }
}
