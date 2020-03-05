//
//  AYInterruptionAudioService.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

// sourcery: AutoMockable
public protocol AYInterruptionAudioServiceProtocol {
    var onInterruptionBegan: (() -> Void)? { get set }
    var onInterruptionEnded: (() -> Void)? { get set }
}

public final class AYPlayerInterruptionAudioService: AYInterruptionAudioServiceProtocol {
    // MARK: - Outputs

    public var onInterruptionBegan: (() -> Void)?
    public var onInterruptionEnded: (() -> Void)?

    // MARK: - Variables

    private let notificationName = AVAudioSession.interruptionNotification

    // MARK: - Init

    public init() {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleService)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(incomingInterruption),
                                               name: notificationName,
                                               object: nil)
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleService)
        NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
    }

    @objc
    private func incomingInterruption(notification: Notification) {
        AYPlayerLogger.instance.log(message: "Audio interruption detected", domain: .service)

        guard
            let userInfo = notification.userInfo,
            let rawInterruptionType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSession.InterruptionType(rawValue: rawInterruptionType)
        else { return }
        switch interruptionType {
        case .began:
            onInterruptionBegan?()
        case .ended:
            onInterruptionEnded?()
        @unknown default:
            AYPlayerLogger.instance.log(message: "Unknown InterruptionType case", domain: .error)
        }
    }
}
