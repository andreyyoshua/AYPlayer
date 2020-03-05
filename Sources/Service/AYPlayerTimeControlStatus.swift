//
//  AYPlayerTimeControlStatus.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 04/03/20.
//

import AVFoundation

// sourcery: AutoMockable
protocol AYPlayerTimeControlStatusProtocol {
    var onPlay: (() -> Void)? { get set }
    var onPause: (() -> Void)? { get set }
    var onLoading: (() -> Void)? { get set }
}

final class AYPlayerTimeControlStatus: AYPlayerTimeControlStatusProtocol {
    // MARK: - Input

    private let player: AVPlayer

    // MARK: - Outputs

    var onPlay: (() -> Void)?
    var onPause: (() -> Void)?
    var onLoading: (() -> Void)?

    // MARK: - Variables

    private var observer: NSKeyValueObservation!

    // MARK: - Init

    init(player: AVPlayer) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleService)
        self.player = player

        defer {
            observer = player.observe(\.timeControlStatus) { [weak self] player, _ in
                guard let self = self else { return }
                switch player.timeControlStatus {
                case .paused:
                    self.onPause?()
                case .waitingToPlayAtSpecifiedRate:
                    self.onLoading?()
                case .playing:
                    self.onPlay?()
                @unknown default:
                    self.onLoading?()
                }
            }
        }
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleService)
        observer.invalidate()
    }
}
