//
//  AYPlayerConfiguration.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

public protocol AYPlayerConfigurationProtocol {
    /// Rate Observing Service
    /// When buffering, a timer is set to observe current item rate:
    ///
    var rateObservingTimeout: TimeInterval { get }
    var rateObservingTickTime: TimeInterval { get }

    /// General Audio preferences
    /// all CMTime created use the specific preferedTimeScale
    /// currentTime and control center elapsed playback time attributes are set in the periodic block.
    ///
    var preferredTimescale: CMTimeScale { get }
    var periodicPlayingTime: CMTime { get }
    var audioSessionCategory: AVAudioSession.Category { get }

    /// Reachability Service
    /// When buffering or playing and playback stop unexpectedly, a timer is set to check connectivity via URLSession
    ///
    var reachabilityURLSessionTimeout: TimeInterval { get }
    var reachabilityNetworkTestingURL: URL { get }
    var reachabilityNetworkTestingTickTime: TimeInterval { get }
    var reachabilityNetworkTestingIteration: UInt { get }

    /// Remote Command Center
    /// If true, all commands are automatically set from `ModernAVPlayerRemoteCommandFactory`
    /// If false, you have to set player.remoteCommands by yourself if needed.
    ///
    var useDefaultRemoteCommand: Bool { get }

    /// Set allowsExternalPlayback to false to avoid black screen when using AirPlay on Apple TV
    ///
    var allowsExternalPlayback: Bool { get }

    /// Use to feed `automaticallyLoadedAssetKeys` on `AVPlayerItem` initialization
    var itemLoadedAssetKeys: [String] { get }
}

public struct AYPlayerConfiguration: AYPlayerConfigurationProtocol {
    // Buffering State
    public let rateObservingTimeout: TimeInterval = 3
    public let rateObservingTickTime: TimeInterval = 0.3

    // General Audio preferences
    public let preferredTimescale = CMTimeScale(NSEC_PER_SEC)
    public let periodicPlayingTime: CMTime
    public let audioSessionCategory = AVAudioSession.Category.playback

    // Reachability Service
    public let reachabilityURLSessionTimeout: TimeInterval = 3
    // swiftlint:disable:next force_unwrapping
    public let reachabilityNetworkTestingURL = URL(string: "https://www.google.com")!
    public let reachabilityNetworkTestingTickTime: TimeInterval = 3
    public let reachabilityNetworkTestingIteration: UInt = 10

    public var useDefaultRemoteCommand = true

    public let allowsExternalPlayback = false

    public let itemLoadedAssetKeys = ["playable", "duration"]

    public init() {
        periodicPlayingTime = CMTime(seconds: 1, preferredTimescale: preferredTimescale)
    }
}
