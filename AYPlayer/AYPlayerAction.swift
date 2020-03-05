//
//  File.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 05/03/20.
//

import Foundation

public protocol AYPlayerAction {
    func load(media: AYPlayerMediaProtocol, autostart: Bool, position: Double?)
    func pause()
    func play()
    func seek(position: Double)
    func stop()
}
