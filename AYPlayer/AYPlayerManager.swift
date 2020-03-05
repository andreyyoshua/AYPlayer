//
//  AYPlayerManager.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVKit
import Foundation

public protocol AYPlayerManagerDelegate: AnyObject {
    func playerManager(didStateChange state: AYPlayerManager.State)
    func playerManager(didCurrentMediaChange media: AYPlayerMediaProtocol?)
    func playerManager(didForwardBufferToDuration duration: Double)
    func playerManager(didCurrentTimeChange currentTime: Double, withTotalDuration totalDuration: Double?)
    func playerManager(unavailableActionReason: AYPlayerUnavailableActionReason)
    func playerManager(didItemPlayToEndTime endTime: Double)
    func playerManager(didFinishPlayingItemWithPerformanceMeasurementData data: VideoPerformanceData)
}

public protocol AYPlayerManagerProtocol: AYPlayerAction {
    var currentMedia: AYPlayerMediaProtocol? { get set }
    var currentItem: AVPlayerItem? { get }
    var config: AYPlayerConfigurationProtocol { get }
    var itemDuration: Double? { get }
    var failedUsedAVPlayerItem: Set<AVPlayerItem> { get set }
    var performanceMeasurement: AYPlayerPerformanceMeasurementsService? { get set }

    func changeState(state: AYPlayerStateProtocol)
}

public class AYPlayerManager: AYPlayerManagerProtocol {
    // MARK: - Inputs

    internal var player = AVPlayer()
    internal weak var delegate: AYPlayerManagerDelegate?
    public let config: AYPlayerConfigurationProtocol

    // MARK: - Variables

    public var currentMedia: AYPlayerMediaProtocol? {
        didSet { delegate?.playerManager(didCurrentMediaChange: currentMedia) }
    }

    public var currentItem: AVPlayerItem? {
        return player.currentItem
    }

    public var currentTime: Double {
        return player.currentTime().seconds
    }

    public var itemDuration: Double? {
        return currentItem?.duration.seconds
    }

    private var state: AYPlayerStateProtocol! {
        didSet {
            AYPlayerLogger.instance.log(message: state.type.description, domain: .state)
            state.managerUpdated()
            delegate?.playerManager(didStateChange: state.type)
        }
    }

    public var loopMode: Bool = false
    public var failedUsedAVPlayerItem: Set<AVPlayerItem> = Set()
    public var performanceMeasurement: AYPlayerPerformanceMeasurementsService? {
        didSet {
            performanceMeasurement?.resultCallback = { [weak self] data in
                self?.delegate?.playerManager(didFinishPlayingItemWithPerformanceMeasurementData: data)
            }
        }
    } // performance measurements

    // MARK: - LifeCycle

    public init(player: AVPlayer = AVPlayer(),
                config: AYPlayerConfigurationProtocol = AYPlayerConfiguration(),
                loggerDomains: [AYPlayerLoggerDomain] = []) {
        AYPlayerLogger.setup.domains = loggerDomains
        self.player = player
        self.config = config

        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleState)
        defer {
            self.state = InitializationState(manager: self)
        }
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleState)
    }

    public func changeState(state: AYPlayerStateProtocol) {
        self.state = state
    }

    // MARK: - Shared Actions

    public func load(media: AYPlayerMediaProtocol, autostart: Bool, position: Double? = nil) {
        currentMedia = media
        state.load(media: media, autostart: autostart, position: position)
    }

    public func pause() {
        state.pause()
    }

    public func play() {
        state.play()
    }

    public func stop() {
        state.stop()
    }

    public func seek(position: Double) {
        guard let item = currentItem
        else { unaivalableCommand(reason: .loadMediaFirst); return }

        let seekService = AYPlayerSeekService(preferredTimescale: config.preferredTimescale)
        let seekPosition = seekService.boundedPosition(position, item: item)
        if let boundedPosition = seekPosition.value {
            state.seek(position: boundedPosition)
        } else if let reason = seekPosition.reason {
            unaivalableCommand(reason: reason)
        } else {
            assertionFailure("boundedPosition should return at least value or reason")
        }
    }

    public func seek(offset: Double) {
        let position = currentTime + offset
        seek(position: position)
    }

    private func unaivalableCommand(reason: AYPlayerUnavailableActionReason) {
        let message: String
        switch reason {
        case .seekOverstepPosition:
            message = "Seek position should not exceed item end position"
        case .seekPositionNotAvailable:
            message = "Seek position not available"
        case .loadMediaFirst:
            message = "Load a media first"
        default:
            assertionFailure("all context cases must be set")
            message = ""
        }
        AYPlayerLogger.instance.log(message: message, domain: .unavailableCommand)
        delegate?.playerManager(unavailableActionReason: reason)
    }
}

extension Notification.Name {
    /// Notification for when a timebase changed rate
    static let TimebaseEffectiveRateChangedNotification = Notification.Name(rawValue: kCMTimebaseNotification_EffectiveRateChanged as String)
}
