//
//  AYPlayerUnavailableActionReason.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import Foundation

public enum AYPlayerUnavailableActionReason {
    case alreadyPaused
    case alreadyPlaying
    case alreadyStopped
    case alreadyTryingToPlay
    case seekPositionNotAvailable
    case loadMediaFirst
    case seekOverstepPosition
    case waitEstablishedNetwork
    case waitLoadedMedia
}
