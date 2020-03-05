//
//  AYRateObservingService.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

protocol AYRateObservingServiceProtocol {
    var onPlaying: (() -> Void)? { get set }
    var onTimeout: (() -> Void)? { get set }

    func start()
    func stop(clearCallbacks: Bool)
}

final class AYRateObservingService: AYRateObservingServiceProtocol {
    // MARK: - Inputs

    private let item: AVPlayerItem
    private let timeInterval: TimeInterval
    private let timeout: TimeInterval
    private let timerFactory: AYTimerFactory

    // MARK: - Outputs

    var onPlaying: (() -> Void)?
    var onTimeout: (() -> Void)?

    // MARK: - Variables

    private weak var timer: CustomTimer?
    private var remainingTime: TimeInterval = 0

    // MARK: - Lifecycle

    init(config: AYPlayerConfigurationProtocol, item: AVPlayerItem, timerFactory: AYTimerFactory = AYPlayerTimerFactory()) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleService)
        timeInterval = config.rateObservingTickTime
        timeout = config.rateObservingTimeout
        self.timerFactory = timerFactory
        self.item = item
    }

    deinit {
        timer?.invalidate()
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleService)
    }

    // MARK: - Rate Service

    func start() {
        AYPlayerLogger.instance.log(message: "Item: \(item)", domain: .service)
        remainingTime = timeout
        timer?.invalidate()
        DispatchQueue.main.async {
            self.timer = self.timerFactory.getTimer(timeInterval: self.timeInterval, repeats: true, block: self.blockTimer)
        }
    }

    func stop(clearCallbacks: Bool) {
        if clearCallbacks { self.clearCallbacks() }
        timer?.invalidate()
        timer = nil
    }

    private func clearCallbacks() {
        onPlaying = nil
        onTimeout = nil
    }

    func blockTimer() {
        guard let timebase = item.timebase else { return }

        remainingTime -= timeInterval
        let rate = CMTimebaseGetRate(timebase)
        if rate != 0 {
            timer?.invalidate()
            onPlaying?()
        } else if remainingTime <= 0 {
            timer?.invalidate()
            onTimeout?()
        } else {
            AYPlayerLogger.instance.log(message: "Remaining time: \(remainingTime)", domain: .service)
        }
    }
}
