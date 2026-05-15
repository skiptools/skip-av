// Copyright 2025–2026 Skip
// SPDX-License-Identifier: MPL-2.0
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

    public func testCMTime() throws {
        let zero = CMTime.zero
        XCTAssertEqual(0.0, zero.seconds)
        XCTAssertTrue(zero.isValid)
        XCTAssertFalse(zero.isIndefinite)
        XCTAssertTrue(zero.isNumeric)

        let five = CMTime(seconds: 5.0, preferredTimescale: CMTimeScale(600))
        XCTAssertEqual(5.0, five.seconds)
        XCTAssertEqual(CMTimeValue(3000), five.value)
        XCTAssertEqual(CMTimeScale(600), five.timescale)
        XCTAssertTrue(five.isValid)
        XCTAssertTrue(five.isNumeric)

        let twoSeconds = CMTime(value: CMTimeValue(2000), timescale: CMTimeScale(1000))
        XCTAssertEqual(2.0, twoSeconds.seconds)

        // Comparable-style ordering via CMTimeCompare
        XCTAssertEqual(Int32(-1), CMTimeCompare(twoSeconds, five))
        XCTAssertEqual(Int32(1), CMTimeCompare(five, twoSeconds))
        XCTAssertEqual(Int32(0), CMTimeCompare(twoSeconds, twoSeconds))

        let seven = CMTimeAdd(five, twoSeconds)
        XCTAssertEqual(7.0, seven.seconds)

        let three = CMTimeSubtract(five, twoSeconds)
        XCTAssertEqual(3.0, three.seconds)

        XCTAssertEqual(2.0, CMTimeMinimum(twoSeconds, five).seconds)
        XCTAssertEqual(5.0, CMTimeMaximum(twoSeconds, five).seconds)

        let made = CMTimeMake(value: CMTimeValue(4000), timescale: CMTimeScale(1000))
        XCTAssertEqual(4.0, CMTimeGetSeconds(made))

        let madeWithSeconds = CMTimeMakeWithSeconds(2.5, preferredTimescale: CMTimeScale(600))
        XCTAssertEqual(2.5, madeWithSeconds.seconds)

        let indefinite = CMTime.indefinite
        XCTAssertTrue(indefinite.isIndefinite)
        XCTAssertFalse(indefinite.isNumeric)

        let positiveInf = CMTime.positiveInfinity
        XCTAssertTrue(positiveInf.isPositiveInfinity)
        XCTAssertEqual(Double.infinity, positiveInf.seconds)

        let invalid = CMTime.invalid
        XCTAssertFalse(invalid.isValid)
    }

    public func testCMTimeRange() throws {
        let start = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(1000))
        let duration = CMTime(seconds: 2.0, preferredTimescale: CMTimeScale(1000))
        let range = CMTimeRange(start: start, duration: duration)
        XCTAssertEqual(1.0, range.start.seconds)
        XCTAssertEqual(2.0, range.duration.seconds)
        XCTAssertEqual(3.0, range.end.seconds)
        XCTAssertTrue(range.isValid)

        let middle = CMTime(seconds: 2.0, preferredTimescale: CMTimeScale(1000))
        XCTAssertTrue(range.containsTime(middle))
        XCTAssertTrue(CMTimeRangeContainsTime(range, time: middle))

        let outside = CMTime(seconds: 4.0, preferredTimescale: CMTimeScale(1000))
        XCTAssertFalse(range.containsTime(outside))

        let madeRange = CMTimeRangeMake(start: start, duration: duration)
        XCTAssertEqual(3.0, CMTimeRangeGetEnd(madeRange).seconds)
    }

    public func testAVAsset() throws {
        let asset = AVAsset(url: videoURL)
        // SkipAV's AVAsset exposes `url` and a derived `duration` on Android;
        // iOS plain `AVAsset` does not (use `AVURLAsset` there), so guard them.
        #if SKIP
        XCTAssertEqual(videoURL, asset.url)
        XCTAssertTrue(asset.duration.isIndefinite)
        let item = AVPlayerItem(asset: asset)
        XCTAssertTrue(item.duration.isIndefinite)
        #endif
    }

    public func testAVPlayerAdditions() throws {
        let player = AVPlayer(url: videoURL)

        // currentTime starts at zero before any playback.
        XCTAssertEqual(0.0, player.currentTime().seconds)

        // status starts in a non-failed state without a player error.
        XCTAssertNotEqual(AVPlayer.Status.failed, player.status)
        XCTAssertNil(player.error)

        // isMuted toggling. iOS treats volume and isMuted as independent; on
        // Android we emulate isMuted by saving/restoring the volume, so only
        // assert the toggling here.
        XCTAssertFalse(player.isMuted)
        player.isMuted = true
        XCTAssertTrue(player.isMuted)
        player.isMuted = false
        XCTAssertFalse(player.isMuted)

        // actionAtItemEnd default and round-trip. `.advance` is only legal for
        // AVQueuePlayer on iOS, so only set the AVPlayer-legal `.pause` and `.none` here.
        XCTAssertEqual(AVPlayer.ActionAtItemEnd.pause, player.actionAtItemEnd)
        player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        XCTAssertEqual(AVPlayer.ActionAtItemEnd.none, player.actionAtItemEnd)
        player.actionAtItemEnd = AVPlayer.ActionAtItemEnd.pause
        XCTAssertEqual(AVPlayer.ActionAtItemEnd.pause, player.actionAtItemEnd)

        // automaticallyWaitsToMinimizeStalling default is true.
        XCTAssertTrue(player.automaticallyWaitsToMinimizeStalling)
        player.automaticallyWaitsToMinimizeStalling = false
        XCTAssertFalse(player.automaticallyWaitsToMinimizeStalling)

        // Exercise the seek-with-completion-handler API. On Android the
        // handler runs synchronously; iOS may complete asynchronously, so
        // just verify the call signature compiles and doesn't crash.
        player.seek(to: CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(1000))) { _ in
        }

        // seek with tolerances.
        player.seek(to: CMTime.zero, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        player.seek(to: CMTime.zero, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { _ in
        }
    }
}
