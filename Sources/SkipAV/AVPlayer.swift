// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
#if canImport(AVKit)
@_exported import AVKit
#elseif SKIP
import Foundation
import OSLog
import android.content.Context
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer

let logger: Logger = Logger(subsystem: "SkipAV", category: "AVPlayer")

public struct AVAsset: Equatable {
    // SKIP @nobridge
    let mediaItem: MediaItem

    public static func == (lhs: AVAsset, rhs: AVAsset) -> Bool {
        lhs.mediaItem == rhs.mediaItem
    }
}

public struct AVPlayerItem: Equatable {
    public let asset: AVAsset

    public init(asset: AVAsset) {
        self.asset = asset
    }

    public init(url: URL) {
        self.asset = AVAsset(mediaItem: MediaItem.fromUri(url.absoluteString))
    }

    public static func == (lhs: AVPlayerItem, rhs: AVPlayerItem) -> Bool {
        lhs.asset == rhs.asset
    }
}

public class AVPlayer {
    // SKIP @nobridge
    public lazy var mediaPlayer: Player = createMediaPlayer()
    private var mediaPlayerCreated = false

    public var volume: Float {
        get { mediaPlayer.volume }
        set { mediaPlayer.volume = newValue }
    }

    public var rate: Float = Float(1.0) {
        // cannot set to zero or else java.lang.IllegalArgumentException from androidx.media3.common.util.Assertions.checkArgument
        didSet { mediaPlayer.setPlaybackSpeed(max(newValue, Float(0.000000000001))) }
    }

    public var currentItem: AVPlayerItem? {
        guard let mediaItem = mediaPlayer.getCurrentMediaItem() else {
            return nil
        }
        return AVPlayerItem(asset: AVAsset(mediaItem: mediaItem))
    }

    public init() {
    }

    deinit {
        // only deinit if we have created the media player
        if mediaPlayerCreated {
            mediaPlayer.release()
        }
    }

    public init(playerItem: AVPlayerItem?) {
        if let playerItem {
            mediaPlayer.addMediaItem(playerItem.asset.mediaItem)
        }
    }

    public convenience init(url: URL) {
        self.init(playerItem: AVPlayerItem(url: url))
    }

    func prepare(_ ctx: Context) {
    }

    private func createMediaPlayer() -> Player {
        let mediaPlayer = ExoPlayer.Builder(ProcessInfo.processInfo.androidContext).build()
        mediaPlayer.playWhenReady = true
        self.mediaPlayerCreated = true
        return mediaPlayer
    }

    public func play() {
        mediaPlayer.prepare()
        mediaPlayer.play()
    }

    public func pause() {
        mediaPlayer.pause()
    }

    public func seek(to time: CMTime) {
        mediaPlayer.seekTo(time.value)
    }

    public func replaceCurrentItem(with item: AVPlayerItem?) {
        if let item {
            mediaPlayer.replaceMediaItem(mediaPlayer.getCurrentMediaItemIndex(), item.asset.mediaItem)
        }
    }
}

public class AVQueuePlayer : AVPlayer {
    fileprivate var looping: Bool = false {
        didSet { mediaPlayer.repeatMode = looping ? Player.REPEAT_MODE_ALL : Player.REPEAT_MODE_OFF }
    }

    public override init() {
        super.init()
    }

    // SKIP @nobridge
    public override init(playerItem: AVPlayerItem?) {
        super.init(playerItem: playerItem)
    }

    // work around https://github.com/skiptools/skip-bridge/issues/86
    @available(*, deprecated, message: "use version without unusedp flag")
    public init(playerItem: AVPlayerItem?, _ unusedp: Bool = false) {
        super.init(playerItem: playerItem)
    }

    public init(items: [AVPlayerItem]) {
        super.init(playerItem: nil)
        mediaPlayer.addMediaItems(items.map(\.asset.mediaItem).toList())
    }

    public func items() -> [AVPlayerItem] {
        return (0..<mediaPlayer.getMediaItemCount())
            .map { AVPlayerItem(asset: AVAsset(mediaItem: mediaPlayer.getMediaItemAt($0))) }

    }

    public func advanceToNextItem() {
        mediaPlayer.seekToNextMediaItem()
    }

    // SKIP @nobridge
    override func prepare(_ ctx: Context) {
        super.prepare(ctx)
        if looping {
            self.mediaPlayer.repeatMode = Player.REPEAT_MODE_ALL
        }
    }

    public func insert(_ item: AVPlayerItem, after: AVPlayerItem?) {
        if let after {
            for index in 0..<mediaPlayer.getMediaItemCount() {
                let indexItem = mediaPlayer.getMediaItemAt(index)
                if indexItem == after.asset.mediaItem {
                    mediaPlayer.addMediaItem(index + 1, item.asset.mediaItem)
                    return
                }
            }
        }

        // add to the end of the list
        mediaPlayer.addMediaItem(item.asset.mediaItem)
    }

    public func remove(_ item: AVPlayerItem) {
        for index in 0..<mediaPlayer.getMediaItemCount() {
            let indexItem = mediaPlayer.getMediaItemAt(index)
            if indexItem == item.asset.mediaItem {
                mediaPlayer.removeMediaItem(index)
                return
            }
        }
    }

    public func removeAllItems() {
        mediaPlayer.clearMediaItems()
    }
}


public class AVPlayerLooper {
    public let player: AVQueuePlayer
    public let templateItem: AVPlayerItem

    public init(player: AVQueuePlayer, templateItem: AVPlayerItem) {
        self.player = player
        self.templateItem = templateItem
        self.player.looping = true
    }

    deinit {
        // Weird, but this is how AVKit behaves: retain the AVPlayerLooper or else if will stop looping
        self.player.looping = false
    }

    // TODO
    //open var status: AVPlayerLooper.Status { get }
    //open var error: (any Error)? { get }
    //open func disableLooping()
    //open var loopCount: Int { get }
    //open var loopingPlayerItems: [AVPlayerItem] { get }

    public enum Status : Int {
        case unknown = 0
        case ready = 1
        case failed = 2
        case cancelled = 3
    }
}
#endif
#endif
