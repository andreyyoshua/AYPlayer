//
//  AYPlayerBufferObservingService.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 04/03/20.
//

import AVFoundation

final class AYPlayerBufferObservingService: NSObject {
    // MARK: - Inputs

    private let item: AVPlayerItem
    private let itemBufferCallback: (Double) -> Void

    // MARK: - Init

    init(item: AVPlayerItem, callback: @escaping (Double) -> Void) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleService)
        self.item = item
        itemBufferCallback = callback
        super.init()

        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: [.new, .initial], context: nil)
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleService)
        item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges))
    }

    // MARK: - Service

    /*
     Fetch only nil values when observe with the new kvo block observe.
     keypath used: \.status
     */
    // swiftlint:disable:next block_based_kvo
    override func observeValue(forKeyPath _: String?,
                               of _: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context _: UnsafeMutableRawPointer?) {
        guard
            let change = change,
            let rawStatus = change[.newKey] as? [CMTimeRange],
            let timeRange = rawStatus.first
        else { return }

        // TODO will be used when percentage duration will be used
//        let totalDuration = CMTimeGetSeconds(item.duration)
//        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
        itemBufferCallback(durationSeconds)
    }
}
