//
//  AYPlayerStatusObservingService.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation

final class AYPlayerStatusObservingService: NSObject {
    // MARK: - Inputs

    private let item: AVPlayerItem
    private let itemStatusCallback: (AVPlayerItem.Status) -> Void

    // MARK: - Init

    init(item: AVPlayerItem, callback: @escaping (AVPlayerItem.Status) -> Void) {
        AYPlayerLogger.instance.log(message: "Init", domain: .lifecycleService)
        self.item = item
        itemStatusCallback = callback
        super.init()

        item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
    }

    deinit {
        AYPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleService)
        item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
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
            let rawStatus = change[.newKey] as? Int,
            let status = AVPlayerItem.Status(rawValue: rawStatus)
        else { return }

        itemStatusCallback(status)
    }
}
