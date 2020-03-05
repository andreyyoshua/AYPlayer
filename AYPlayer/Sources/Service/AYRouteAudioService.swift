//
//  AYRouteAudioService.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

final class AYPlayerRouteAudioService {
    // MARK: - Output

    var onRouteChanged: ((AVAudioSession.RouteChangeReason) -> Void)?

    // MARK: - Variable

    private let notificationName = AVAudioSession.routeChangeNotification

    // MARK: - Init

    init() {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleService)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioRouteChanged),
                                               name: notificationName,
                                               object: nil)
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleService)
        NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
    }

    @objc
    private func audioRouteChanged(notification: Notification) {
        AYPlayerLogger.instance.log(message: "Update audio route detected", domain: .service)
        guard
            let info = notification.userInfo,
            let reasonInt = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonInt)
        else { return }

        onRouteChanged?(reason)
    }
}
