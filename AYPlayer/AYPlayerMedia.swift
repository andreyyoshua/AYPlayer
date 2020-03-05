//
//  AYPlayerMedia.swift
//  AYPlayer
//
//  Created by Andrey Yoshua on 03/03/20.
//

import AVFoundation.AVPlayerItem

// sourcery: AutoMockable
public protocol AYPlayerMediaProtocol: CustomStringConvertible {

    /// URL set to the AVURLAsset
    var url: URL { get }
    
    /// Asset options use by AVURLAsset
    var assetOptions: [String: Any]? { get }
}

public extension AYPlayerMediaProtocol {
    var description: String {
        return "url: \(url.description)"
    }
}

public protocol AYPlayerMediaItem: AYPlayerMediaProtocol {
    ///
    /// Item used by the player only once.
    /// - Note: If item failed, a fresh new one is created
    ///
    var item: AVPlayerItem { get }
}

public class AYPlayerMedia: AYPlayerMediaProtocol {
    // MARK: - Outputs

    public let url: URL
    public let assetOptions: [String: Any]?

    // MARK: - Init

    public init(url: URL,
                assetOptions: [String: Any]? = nil) {
        self.url = url
        self.assetOptions = assetOptions
    }
}
