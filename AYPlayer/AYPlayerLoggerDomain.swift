//
//  AYPlayerLoggerDomain.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import Foundation

public enum AYPlayerLoggerDomain: CustomStringConvertible {
    case state
    case service
    case error
    case lifecycleService
    case lifecycleState
    case remoteCommand
    case unavailableCommand

    public var description: String {
        switch self {
        case .error:
            return "[💉]"
        case .service:
            return "[🔬]"
        case .lifecycleService:
            return "[🔬 🚥]"
        case .state:
            return "[🔈]"
        case .lifecycleState:
            return "[🔈 🚥]"
        case .remoteCommand:
            return "[▶️]"
        case .unavailableCommand:
            return "[🙅‍♂️]"
        }
    }
}
