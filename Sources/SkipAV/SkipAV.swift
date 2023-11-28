// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import SwiftUI
#if SKIP
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.ui.PlayerView
import androidx.media3.exoplayer.ExoPlayer

public struct VideoPlayer: View {
    let player: AVPlayer

    public init(player: AVPlayer) {
        self.player = player
    }

    @Composable public override func ComposeContent(context: ComposeContext) {
        ComposeContainer(modifier: context.modifier, fillWidth: true, fillHeight: true) { modifier in
            AndroidView(factory: { ctx in
                let playerView = PlayerView(ctx)
                player.prepare(ctx)
                playerView.player = player.mediaPlayer
                return playerView
            }, modifier: modifier, update: { playerView in
            })
        }
    }
}
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
    // MediaSession
    var playerItems: [AVPlayerItem] = []
    #if SKIP
    var mediaPlayer: Player? = nil
    #endif

    public init() {
    }

    public init(playerItem: AVPlayerItem?) {
        if let playerItem = playerItem {
            playerItems.append(playerItem)
        }
    }

    public convenience init(url: URL) {
        self.init(playerItem: AVPlayerItem(url: url))
    }

    #if SKIP
    fileprivate func prepare(_ ctx: Context) {
        let mediaPlayer = ExoPlayer.Builder(ctx).build()
        //let mediaSession = MediaSession.Builder(ctx, mediaPlayer).build()
        self.mediaPlayer = mediaPlayer
        for item in self.playerItems {
            mediaPlayer.addMediaItem(item.mediaItem)
        }
        mediaPlayer.prepare()
    }
    #endif

    public func play() {
        #if SKIP
        let x = mediaPlayer?.play()
        _ = x
        #endif
    }

    public func pause() {
        #if SKIP
        let x = mediaPlayer?.pause()
        _ = x
        #endif
    }

    public func seek(to time: CMTime) {
        #if SKIP
        // mediaPlayer?.seek(time.timeToSeekTime) // TODO: CMTime
        #endif
    }
}

public typealias CMTimeValue = Int64
public typealias CMTimeScale = Int32
public typealias CMTimeFlags = UInt32
public typealias CMTimeEpoch = Int64

/// Time as a rational value, with a time value as the numerator and timescale as the denominator. The structure can represent a specific numeric time in the media timeline, and can also represent nonnumeric values like invalid and indefinite times or positive and negative infinity.
public struct CMTime : Hashable { // TODO: Comparable
    public static let zero = CMTime(seconds: 0.0, preferredTimescale: 0)

    public var value: CMTimeValue = CMTimeValue(0)
    public var timescale: CMTimeScale = CMTimeScale(0)
    public var flags: CMTimeFlags = CMTimeFlags(0)
    public var epoch: CMTimeEpoch = CMTimeEpoch(0)

    public init(value: CMTimeValue, timescale: CMTimeScale, flags: CMTimeFlags, epoch: CMTimeEpoch) {
        self.value = value as CMTimeValue
        self.timescale = timescale as CMTimeScale
        self.flags = flags as CMTimeFlags
        self.epoch = epoch as CMTimeEpoch
    }

    public init(seconds: Double, preferredTimescale: CMTimeScale) {
        self.value = CMTimeValue(seconds * 1000.0)
        self.timescale = preferredTimescale
    }

    public init(value: CMTimeValue, timescale: CMTimeScale) {
        self.value = value
        self.timescale = timescale
    }
}
