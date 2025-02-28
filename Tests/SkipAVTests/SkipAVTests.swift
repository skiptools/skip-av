// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
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
        #if SKIP || os(iOS)
        let playerView = VideoPlayer(player: player)
        #endif
    }
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}
