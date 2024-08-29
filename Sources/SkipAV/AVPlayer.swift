// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

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
    // MediaSession
    private var playerItems: [AVPlayerItem] = []
    #if SKIP
    var mediaPlayer: Player? = nil
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
        // mediaPlayer?.seek(time.timeToSeekTime) // TODO: CMTime
        #endif
    }
}
