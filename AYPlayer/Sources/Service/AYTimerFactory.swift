//
//  AYTimerFactory.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import Foundation

protocol CustomTimer: AnyObject {
    func fire()
    func invalidate()
}

extension Timer: CustomTimer {}

protocol AYTimerFactory {
    func getTimer(timeInterval: TimeInterval, repeats: Bool, block: @escaping () -> Void) -> CustomTimer
}

struct AYPlayerTimerFactory: AYTimerFactory {
    final class TimerAdapter: CustomTimer {
        private let block: (() -> Void)?
        private let repeats: Bool
        private let timeInterval: TimeInterval
        private lazy var innerTimer: CustomTimer = {
            Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(executeBlock), userInfo: nil, repeats: repeats)
        }()

        init(timeInterval: TimeInterval, repeats: Bool, block: @escaping () -> Void) {
            self.block = block
            self.repeats = repeats
            self.timeInterval = timeInterval
            innerTimer.fire()
        }

        @objc
        func executeBlock() {
            block?()
        }

        func fire() {
            innerTimer.fire()
        }

        func invalidate() {
            innerTimer.invalidate()
        }
    }

    func getTimer(timeInterval: TimeInterval, repeats: Bool, block: @escaping () -> Void) -> CustomTimer {
        return TimerAdapter(timeInterval: timeInterval, repeats: repeats, block: block)
    }
}
