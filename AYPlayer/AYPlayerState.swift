//
//  AYPlayerState.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 05/03/20.
//

import Foundation

public protocol AYPlayerStateProtocol: AYPlayerAction {
    var manager: AYPlayerManager { get }
    var type: AYPlayerManager.State { get }

    func managerUpdated()
}
