// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
import XCTest
import OSLog
import Foundation
import SwiftUI
import AVKit
@testable import SkipAV

let logger: Logger = Logger(subsystem: "SkipAV", category: "Tests")

// Needs to be run on the main thread:
// https://developer.android.com/media/media3/exoplayer/hello-world#a-note-on-threading
//
// or else:
// java.lang.IllegalStateException: Player is accessed on the wrong thread.
// Current thread: 'Instr: androidx.test.runner.AndroidJUnitRunner'
//
// SKIP INSERT: @androidx.test.annotation.UiThreadTest
final class SkipAVTests: XCTestCase {
    let videoURL = URL(string: "http://skip.tools/assets/introduction.mov")!

    public func testSkipAVAPI() throws {
        let _ = AVPlayer(url: videoURL)

        let playerItem = AVPlayerItem(url: videoURL)
        let player = AVPlayer(playerItem: playerItem)
        XCTAssertEqual(playerItem, player.currentItem)
        player.volume = Float(1.0)

        #if SKIP || os(iOS)
        let playerView = VideoPlayer(player: player)
        let _ = playerView
        #endif

        player.replaceCurrentItem(with: playerItem)

        let playerItem1 = AVPlayerItem(url: videoURL)
        let playerItem2 = AVPlayerItem(url: videoURL)
        let playerItem3 = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer(items: [playerItem1])

        let items: [AVPlayerItem] = queuePlayer.items()
        XCTAssertEqual(1, items.count)

        XCTAssertEqual(1, queuePlayer.items().count)
        queuePlayer.insert(playerItem2, after: nil)
        XCTAssertEqual(2, queuePlayer.items().count)
        queuePlayer.insert(playerItem3, after: playerItem2)
        XCTAssertEqual(3, queuePlayer.items().count)
        queuePlayer.remove(playerItem2)
        XCTAssertEqual([playerItem1, playerItem3], queuePlayer.items())
        XCTAssertEqual(2, queuePlayer.items().count)
        queuePlayer.removeAllItems()
        XCTAssertEqual(0, queuePlayer.items().count)
    }
}
