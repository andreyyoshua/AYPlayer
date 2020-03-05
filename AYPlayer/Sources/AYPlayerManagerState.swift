//
//  AYPlayerManagerState.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 05/03/20.
//

import Foundation

extension AYPlayerManager {
    public enum State: String, CustomStringConvertible {
        case initialization
        case waitingForNetwork
        case loading
        case buffering
        case playing
        case paused
        case stopped
        case failed

        public var description: String {
            return rawValue.capitalized
        }
    }
}
