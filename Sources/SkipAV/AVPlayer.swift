// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
import Foundation
#if SKIP
import android.content.Context
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
#endif

public struct AVPlayerItem {
    let url: URL

    public init(url: URL) {
        self.url = url
    }

    #if SKIP
    var mediaItem: MediaItem {
        MediaItem.fromUri(url.absoluteString)
    }
    #endif
}

public class AVPlayer {
    fileprivate var playerItems: [AVPlayerItem] = []
    #if SKIP
    var mediaPlayer: Player? = nil
    public var rate: Float = Float(1.0) {
        // cannot set to zero or else java.lang.IllegalArgumentException from androidx.media3.common.util.Assertions.checkArgument
        didSet { mediaPlayer?.setPlaybackSpeed(max(newValue, Float(0.000000000001))) }
    }
    #endif

    public init() {
    }

    #if SKIP
    deinit {
        mediaPlayer?.release()
    }
    #endif

    public init(playerItem: AVPlayerItem?) {
        if let playerItem = playerItem {
            playerItems.append(playerItem)
        }
    }

    public convenience init(url: URL) {
        self.init(playerItem: AVPlayerItem(url: url))
    }

    #if SKIP
    func prepare(_ ctx: Context) {
        guard mediaPlayer == nil else {
            return
        }
        let mediaPlayer = ExoPlayer.Builder(ctx).build()
        //let mediaSession = MediaSession.Builder(ctx, mediaPlayer).build()
        self.mediaPlayer = mediaPlayer
        for item in self.playerItems {
            mediaPlayer.addMediaItem(item.mediaItem)
        }
        mediaPlayer.playWhenReady = true
        mediaPlayer.prepare()
    }
    #endif

    public func play() {
        #if SKIP
        let _ = mediaPlayer?.play()
        #endif
    }

    public func pause() {
        #if SKIP
        let _ = mediaPlayer?.pause()
        #endif
    }

    public func seek(to time: CMTime) {
        #if SKIP
        mediaPlayer?.seekTo(time.value)
        #endif
    }
}

public class AVQueuePlayer : AVPlayer {
    fileprivate var looping: Bool = false

    public override init(playerItem: AVPlayerItem?) {
        super.init(playerItem: playerItem)
    }

    public init(items: [AVPlayerItem]) {
        super.init(playerItem: nil)
        self.playerItems = items
    }

    #if SKIP
    override func prepare(_ ctx: Context) {
        super.prepare(ctx)
        if looping {
            self.mediaPlayer?.repeatMode = Player.REPEAT_MODE_ALL
        }
    }
    #endif
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

