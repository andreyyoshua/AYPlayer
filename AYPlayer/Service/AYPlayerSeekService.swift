//
//  AYPlayerSeekService.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation
import Foundation

// sourcery: AutoMockable
protocol AYSeekServiceProtocol {
    func boundedPosition(_ position: Double,
                         item: AVPlayerItem) -> (value: Double?, reason: AYPlayerUnavailableActionReason?)
}

struct AYPlayerSeekService: AYSeekServiceProtocol {
    private let preferredTimescale: CMTimeScale

    init(preferredTimescale: CMTimeScale) {
        self.preferredTimescale = preferredTimescale
    }

    private func isPositionInRanges(_ position: Double, _ ranges: [CMTimeRange]) -> Bool {
        let time = CMTime(seconds: position, preferredTimescale: preferredTimescale)
        return !ranges.filter { $0.containsTime(time) }.isEmpty
    }

    private func getItemRangesAvailable(_ item: AVPlayerItem) -> [CMTimeRange] {
        let ranges = item.seekableTimeRanges + item.loadedTimeRanges
        return ranges.map { $0.timeRangeValue }
    }

    func boundedPosition(_ position: Double,
                         item: AVPlayerItem) -> (value: Double?, reason: AYPlayerUnavailableActionReason?) {
        guard position > 0 else { return (0, nil) }

        let duration = item.duration.seconds
        guard duration.isNormal else {
            let ranges = getItemRangesAvailable(item)
            return isPositionInRanges(position, ranges) ? (position, nil) : (nil, .seekPositionNotAvailable)
        }

        guard Int64(position) < Int64(duration)
        else { return (nil, .seekOverstepPosition) }

        return (position, nil)
    }
}
