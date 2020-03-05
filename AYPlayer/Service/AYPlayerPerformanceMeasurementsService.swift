//
//  AYPlayerPerformanceMeasurements.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation
import Foundation
import os.log

public struct VideoPerformanceData {
    public let startupTime: Double
    public let totalNumberOfStalls: Int
    public let timeWeightedIndicatedBitrateInMbps: Double
    public let stallRatePerHour: Double
    public let stallWaitRatio: Double
}

/// - Tag: PerfMeasurements
public class AYPlayerPerformanceMeasurementsService: NSObject {
    /// Time when this class was created.
    private var creationTime: CFAbsoluteTime = 0.0

    /// Time when playback initially started.
    private var playbackStartTime: CFAbsoluteTime = 0.0

    /// Time of last stall event.
    private var lastStallTime: CFAbsoluteTime = 0.0

    /// Duration of all stalls (time waiting for rebuffering).
    private var totalStallTime: CFTimeInterval = 0.0

    /// Stream startup time measured in seconds.
    internal var startupTime: CFTimeInterval {
        return playbackStartTime - creationTime
    }

    /// Total time spent playing, obtained from the AccessLog.
    /// - Tag: TotalDurationWatched
    internal var totalDurationWatched: Double {
        // Compute total duration watched by iterating through the AccessLog events.
        var totalDurationWatched = 0.0
        if accessLog != nil, !accessLog!.events.isEmpty {
            for event in accessLog!.events where event.durationWatched > 0 {
                totalDurationWatched += event.durationWatched
            }
        }
        return totalDurationWatched
    }

    /**
     Time weighted value of the variant indicated bitrate.
     Measure of overall stream quality.
     */
    internal var timeWeightedIBR: Double {
        var timeWeightedIBR = 0.0
        let totalDurationWatched = self.totalDurationWatched

        if accessLog != nil, totalDurationWatched > 0 {
            // Compute the time-weighted indicated bitrate.
            for event in accessLog!.events {
                if event.durationWatched > 0 {
                    let eventTimeWeight = event.durationWatched / totalDurationWatched
                    let indicatedBitrate: Double
                    
                    if event.indicatedBitrate > 0 {
                        indicatedBitrate = event.indicatedBitrate
                    } else if event.observedBitrate > 0 {
                        indicatedBitrate = event.observedBitrate
                    } else {
                        continue
                    }
                    
                    timeWeightedIBR += indicatedBitrate * eventTimeWeight
                }
            }
        }
        return timeWeightedIBR
    }
    
    internal var totalNumberOfStalls: Int {
        var totalNumberOfStalls = 0

        if accessLog != nil, totalDurationWatched > 0 {
            for event in accessLog!.events {
                totalNumberOfStalls += event.numberOfStalls
            }
        }
        return totalNumberOfStalls
    }

    /**
     Stall rate measured in stalls per hour.
     Normalized measure of stream interruptions caused by stream buffer depleation.
     */
    internal var stallRate: Double {
        let totalHoursWatched = totalDurationWatched / 3600
        return Double(totalNumberOfStalls) / totalHoursWatched
    }

    /**
     Stall time measured as duration-stalled / duration-watched.
     Normalized meausre of time waited for the a stream to rebuffer.
     */
    internal var stallWaitRatio: Double {
        return totalStallTime / totalDurationWatched
    }

    // The AccessLog associated to the current player item.
    private var accessLog: AVPlayerItemAccessLog? {
        return playerItem?.accessLog()
    }

    /// The player item monitored.
    private var playerItem: AVPlayerItem?
    
    /// The callback
    internal var resultCallback: ((VideoPerformanceData) -> Void)?

    internal init(playerItem: AVPlayerItem) {
        super.init()
        self.playerItem = playerItem
        creationTime = CACurrentMediaTime()
        
        let notificationCenter = NotificationCenter.default
        // Register for timebase rate change and playback stalled notifications
        notificationCenter.addObserver(self,
                                       selector: #selector(handleTimebaseRateChanged(_:)),
                                       name: .TimebaseEffectiveRateChangedNotification, object: playerItem.timebase)
        notificationCenter.addObserver(self,
                                       selector: #selector(handlePlaybackStalled(_:)),
                                       name: .AVPlayerItemPlaybackStalled, object: playerItem)
        notificationCenter.addObserver(self,
                                       selector: #selector(handlePlaybackEnded(_:)),
                                       name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }

    deinit {
        if let playerItem = playerItem {
            let notificationCenter = NotificationCenter.default
            notificationCenter.removeObserver(self, name: .TimebaseEffectiveRateChangedNotification, object: playerItem.timebase)
            notificationCenter.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            notificationCenter.removeObserver(self, name: .AVPlayerItemPlaybackStalled, object: playerItem)
        }
    }
    /// Called when a timebase rate change occurs.
    internal func rateChanged(rate: Double) {
        if playbackStartTime == 0.0, rate > 0 {
            // First rate change
            playbackStartTime = CACurrentMediaTime()
            os_log("Perf -- Playback started in %.2f seconds", startupTime)
        } else if rate > 0, lastStallTime > 0 {
            // Subsequent rate change
            playbackStallEnded()
            os_log("Perf -- Playback resumed in %.2f seconds", totalStallTime)
        }
    }

    /// Called when playback stalls.
    internal func playbackStalled() {
        os_log("Perf -- Playback stalled")
        lastStallTime = CACurrentMediaTime()
    }

    /// Called after a stall event, when playback resumes.
    internal func playbackStallEnded() {
        if lastStallTime > 0 {
            totalStallTime += CACurrentMediaTime() - lastStallTime
            lastStallTime = 0.0
        }
    }

    /// Called when the player item is released.
    internal func playbackEnded() {
        playbackStallEnded()
        os_log("Perf -- Playback ended")
        os_log("Perf -- Time-weighted Indicated Bitrate: %.2fMbps", timeWeightedIBR / 1_000_000)
        os_log("Perf -- Stall rate: %.2f stalls/hour", stallRate)
        os_log("Perf -- Stall wait ratio: %.2f duration-stalled/duration-watched", stallWaitRatio)
        
        let videoPerformanceData = VideoPerformanceData(
            startupTime: startupTime,
            totalNumberOfStalls: totalNumberOfStalls,
            timeWeightedIndicatedBitrateInMbps: timeWeightedIBR / 1_000_000,
            stallRatePerHour: stallRate,
            stallWaitRatio: stallWaitRatio)
        resultCallback?(videoPerformanceData)
    }
}

extension AYPlayerPerformanceMeasurementsService {
    @objc private func handleTimebaseRateChanged(_ notification: Notification) {
        if CMTimebaseGetTypeID() == CFGetTypeID(notification.object as CFTypeRef) {
            let timebase = notification.object as! CMTimebase
            let rate: Double = CMTimebaseGetRate(timebase)
            rateChanged(rate: rate)
        }
    }

    @objc private func handlePlaybackStalled(_: Notification) {
        playbackStalled()
    }
    
    @objc private func handlePlaybackEnded(_: Notification) {
        playbackEnded()
    }
}
