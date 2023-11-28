// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import XCTest
import OSLog
import Foundation
import SwiftUI
import AVKit
@testable import SkipAV

let logger: Logger = Logger(subsystem: "SkipAV", category: "Tests")

@available(macOS 13, *)
final class SkipAVTests: XCTestCase {
    let videoURL = URL(string: "http://skip.tools/assets/introduction.mov")!

    public func testSkipAVAPI() throws {
        // this doesn't test that it works, just that the API is there
        let player = AVPlayer(url: videoURL)
        let playerItem = AVPlayerItem(url: videoURL)
        let playerView = VideoPlayer(player: player)
    }
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}
