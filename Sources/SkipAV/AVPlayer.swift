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
    // SKIP @nobridge
    public static let didPlayToEndTimeNotification = Notification.Name(rawValue: "AVPlayerItemDidPlayToEndTimeNotification")

    @available(*, unavailable)
    public static let failedToPlayToEndTimeNotification = Notification.Name(rawValue: "AVPlayerItemFailedToPlayToEndTimeNotification")

    // SKIP @nobridge
    public static let timeJumpedNotification = Notification.Name(rawValue: "AVPlayerItemTimeJumpedNotification")

    // SKIP @nobridge
    public static let playbackStalledNotification = Notification.Name(rawValue: "AVPlayerItemPlaybackStalledNotification")

    @available(*, unavailable)
    public static let mediaSelectionDidChangeNotification = Notification.Name(rawValue: "AVPlayerItemMediaSelectionDidChangeNotification")

    @available(*, unavailable)
    public static let recommendedTimeOffsetFromLiveDidChangeNotification = Notification.Name(rawValue: "AVPlayerItemRecommendedTimeOffsetFromLiveDidChangeNotification")

    @available(*, unavailable)
    public static let newAccessLogEntryNotification = Notification.Name(rawValue: "AVPlayerItemNewAccessLogEntry")

    @available(*, unavailable)
    public static let newErrorLogEntryNotification = Notification.Name(rawValue: "AVPlayerItemNewErrorLogEntry")

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
    private let playerEventListener = AVPlayerEventListener()

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
    
    /// Indicates whether playback is currently paused indefinitely, suspended while waiting for appropriate conditions, or in progress.
    public var timeControlStatus: TimeControlStatus {
        let playbackState = mediaPlayer.playbackState
        let playWhenReady = mediaPlayer.playWhenReady
        
        // Map Media3 states to AVPlayer.TimeControlStatus
        switch playbackState {
        case Player.STATE_IDLE:
            return .paused
        case Player.STATE_BUFFERING:
            // If playWhenReady is true, we're waiting to play
            return playWhenReady ? .waitingToPlayAtSpecifiedRate : .paused
        case Player.STATE_READY:
            // If playWhenReady is true and playback speed > 0, we're playing
            return playWhenReady ? .playing : .paused
        case Player.STATE_ENDED:
            return .paused
        default:
            return .paused
        }
    }
    
    /// Constants that describe the current time control status.
    public enum TimeControlStatus: Int, Sendable {
        /// Playback is currently paused indefinitely.
        case paused = 0
        
        /// Playback is currently waiting for appropriate network or other conditions before starting.
        case waitingToPlayAtSpecifiedRate = 1
        
        /// Playback is currently in progress.
        case playing = 2
    }
    
    /// The reason the player is waiting for playback to continue.
    ///
    /// This property is only meaningful when timeControlStatus is waitingToPlayAtSpecifiedRate.
    public var reasonForWaitingToPlay: WaitingReason? {
        let playbackState = mediaPlayer.playbackState
        
        if playbackState == Player.STATE_BUFFERING && mediaPlayer.playWhenReady {
            // Check if we're buffering due to network conditions
            return .toMinimizeStalls
        }
        
        return nil
    }
    
    /// Constants that describe why the player is in a waiting state.
    public enum WaitingReason: String, Sendable {
        /// The player is waiting for more data to be buffered before playback can continue.
        case toMinimizeStalls = "AVPlayerWaitingToMinimizeStallsReason"
        
        /// The player is waiting because it requires evaluation of media composition.
        case evaluatingBufferingRate = "AVPlayerWaitingWhileEvaluatingBufferingRateReason"
        
        /// The player is waiting for another item in the queue.
        case noItemToPlay = "AVPlayerWaitingWithNoItemToPlayReason"
    }

    public init() {
    }

    deinit {
        // only deinit if we have created the media player
        if mediaPlayerCreated {
            mediaPlayer.release()
        }
    }

    // This enables direct construction using an underlying MediaController
    // https://developer.android.com/media/media3/session/connect-to-media-app#use-controller : “MediaController implements the Player interface, so you can use the commands defined in the interface to control playback of the connected MediaSession.”
    // SKIP @nobridge
    public init(player: Player) {
        self.mediaPlayer = player
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
        playerEventListener.player = self
        mediaPlayer.addListener(playerEventListener)
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

// https://developer.android.com/reference/androidx/media3/common/Player.Listener
final class AVPlayerEventListener: androidx.media3.common.Player.Listener {
    weak var player: AVPlayer? = nil

    init() {
    }

    override func onMediaItemTransition(mediaItem: androidx.media3.common.MediaItem?, reason: Int) {
        logger.debug("AVPlayerEvenListener.onMediaItemTransition: mediaItem=\(mediaItem) reason=\(reason)")
    }

    // Listen for metadata updates (important for streams)
    override func onMediaMetadataChanged(mediaMetadata: androidx.media3.common.MediaMetadata) {
        logger.debug("AVPlayerEvenListener.onMediaMetadataChanged: title: \(mediaMetadata.title) artist: \(mediaMetadata.artist) albumTitle: \(mediaMetadata.artworkUri) zrtwork URI: \(mediaMetadata.artworkUri)")
    }

    // Listen for playback state changes
    override func onPlaybackStateChanged(playbackState: Int) {
        switch playbackState {
        case androidx.media3.common.Player.STATE_BUFFERING:
            logger.debug("AVPlayerEvenListener.onPlaybackStateChanged: STATE_BUFFERING")
            NotificationCenter.default.post(name: AVPlayerItem.playbackStalledNotification, object: player?.currentItem)
        case androidx.media3.common.Player.STATE_READY:
            logger.debug("AVPlayerEvenListener.onPlaybackStateChanged: STATE_READY")
        case androidx.media3.common.Player.STATE_ENDED:
            logger.debug("AVPlayerEvenListener.onPlaybackStateChanged: STATE_ENDED")
            NotificationCenter.default.post(name: AVPlayerItem.didPlayToEndTimeNotification, object: player?.currentItem)
        }
    }

    // Listen for position updates
    override func onPositionDiscontinuity(oldPosition: androidx.media3.common.Player.PositionInfo, newPosition: androidx.media3.common.Player.PositionInfo, reason: /* @Player.DiscontinuityReason */ Int) {
        logger.debug("AVPlayerEvenListener.onPositionDiscontinuity: oldPosition=\(oldPosition) newPosition=\(newPosition) reason=\(reason)")
        NotificationCenter.default.post(name: AVPlayerItem.timeJumpedNotification, object: player?.currentItem)
    }
}
#endif
#endif
