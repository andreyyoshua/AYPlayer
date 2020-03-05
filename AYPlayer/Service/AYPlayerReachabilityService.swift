//
//  ReachabilityService.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 05/03/20.
//

import Foundation

// sourcery: AutoMockable
protocol AYPlayerReachabilityServiceProtocol {
    var isReachable: (() -> Void)? { get set }
    var isTimedOut: (() -> Void)? { get set }

    func start()
}

final class AYPlayerReachabilityService: AYPlayerReachabilityServiceProtocol {
    // MARK: - Inputs

    private let dataTaskFactory: URLSessionDataTaskFactory
    private var remainingNetworkIteration: UInt
    private let timeoutURLSession: TimeInterval
    private let timerFactory: AYTimerFactory
    private let tiNetworkTesting: TimeInterval
    private let url: URL

    // MARK: - Outputs

    var isReachable: (() -> Void)?
    var isTimedOut: (() -> Void)?

    // MARK: - Variables

    private var timer: CustomTimer? {
        didSet { timer?.fire() }
    }

    private var networkTask: CustomURLSessionDataTask? {
        willSet { networkTask?.cancel() }
        didSet { networkTask?.resume() }
    }

    // MARK: - Init

    init(config: AYPlayerConfigurationProtocol,
         dataTaskFactory: URLSessionDataTaskFactory = AYPlayerURLSessionDataTaskFactory(),
         timerFactory: AYTimerFactory = AYPlayerTimerFactory()) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleService)

        self.dataTaskFactory = dataTaskFactory
        self.timerFactory = timerFactory
        url = config.reachabilityNetworkTestingURL
        timeoutURLSession = config.reachabilityURLSessionTimeout
        tiNetworkTesting = config.reachabilityNetworkTestingTickTime
        remainingNetworkIteration = config.reachabilityNetworkTestingIteration
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleService)
        cancelTasks()
    }

    // MARK: - Session & Task

    func start() {
        timer = timerFactory.getTimer(timeInterval: tiNetworkTesting, repeats: true) { [weak self] in
            guard let self = self else { return }

            guard self.remainingNetworkIteration > 0
            else {
                self.cancelTasks()
                self.isTimedOut?()
                return
            }
            self.remainingNetworkIteration -= 1
            self.setNetworkTask()
        }
    }

    private func setNetworkTask() {
        networkTask = dataTaskFactory.getDataTask(with: url, timeout: timeoutURLSession) { [weak self] _, response, error in
            guard
                error == nil,
                let r = response as? HTTPURLResponse,
                r.statusCode >= 200, r.statusCode < 300
            else { AYPlayerLogger.instance.log(message: "Unreachable network", domain: .service); return }

            self?.timer?.invalidate()
            self?.isReachable?()
        }
    }

    private func cancelTasks() {
        networkTask?.cancel()
        timer?.invalidate()
    }
}
