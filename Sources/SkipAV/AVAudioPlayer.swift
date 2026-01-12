// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
#if canImport(AVKit)
@_exported import AVKit
#elseif SKIP
import Foundation
import android.media.AudioFormat
import android.media.MediaPlayer
import java.io.File
import android.Manifest
import android.content.pm.PackageManager

public protocol AVAudioPlayerDelegate: AnyObject {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?)
}

#if SKIP
// Default implementations to make methods optional (matching iOS behavior)
public extension AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {}
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {}
}
#endif

#if SKIP
// Cannot use typealias NSObject = java.lang.Object because it breaks the bridge generation
//public typealias AVObjectBase = NSObject
public protocol AVObjectBase { }
#else
public typealias AVObjectBase = NSObject
#endif

open class AVAudioPlayer: AVObjectBase, KotlinConverting<MediaPlayer?> {
    private var mediaPlayer: MediaPlayer?
    private let context = ProcessInfo.processInfo.androidContext

    public weak var delegate: AVAudioPlayerDelegate?

    private var _numberOfLoops: Int = 0
    private var _volume: Double = 1.0
    private var _rate: Float = Float(1.0)
    private var _url: URL?
    private var _data: Data?

    public init(contentsOf url: URL) throws {
        self._url = url
        super.init()
        try initializeMediaPlayer(url: url)
    }

    // MARK: - Untested implementation.
    public init(data: Data) throws {
        self._data = data
        super.init()
        try initializeMediaPlayer(data: data)
    }

    private func initializeMediaPlayer(url: URL) throws {
        do {
            mediaPlayer = MediaPlayer().apply {
                if url.absoluteString.starts(with: "asset:/") {
                    let assetPath = url.absoluteString.removePrefix("asset:/")
                    let afd = context.assets.openFd(assetPath)
                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                } else {
                    setDataSource(context, android.net.Uri.parse(url.absoluteString))
                }
                prepare()
            }
            setupMediaPlayerListeners()
        } catch {
            throw NSError(domain: "AudioPlayerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Media Player (Android): \(error.localizedDescription)"])
        }
    }

    // MARK: - Untested implementation.
    private func initializeMediaPlayer(data: Data) throws {
        do {
            let tempFile = File.createTempFile("audio", nil, context.cacheDir)
            tempFile.deleteOnExit()
            
            tempFile.writeBytes(data.platformValue)
            
            mediaPlayer = MediaPlayer().apply {
                setDataSource(tempFile.path)
                prepare()
            }
            setupMediaPlayerListeners()
        } catch {
            throw NSError(domain: "AudioPlayerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Media Player (Android): \(error.localizedDescription)"])
        }
    }

    // SKIP @nobridge
    public init(platformValue: MediaPlayer) {
        mediaPlayer = platformValue
        setupMediaPlayerListeners()
    }

    // SKIP @nobridge
    public override func kotlin(nocopy: Bool = false) -> MediaPlayer? {
        return mediaPlayer
    }

    private func setupMediaPlayerListeners() {
        mediaPlayer?.setOnCompletionListener { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.audioPlayerDidFinishPlaying(self, successfully: true)
        }
        mediaPlayer?.setOnErrorListener { [weak self] _, what, extra in
            guard let self = self else { return true }
            self.delegate?.audioPlayerDecodeErrorDidOccur(self, error: NSError(domain: "AVAudioPlayerError", code: what, userInfo: ["extra": extra]))
            return true
        }
    }

    open func prepareToPlay() -> Bool {
        return mediaPlayer != nil
    }

    open func play() {
        do {
            mediaPlayer?.start()
        } catch {
            delegate?.audioPlayerDecodeErrorDidOccur(self, error: error)
        }
    }

    open func pause() {
        mediaPlayer?.pause()
    }

    open func stop() {
        mediaPlayer?.stop()
        mediaPlayer?.reset()
        
        delegate?.audioPlayerDidFinishPlaying(self, successfully: true)
    }

    open var isPlaying: Bool {
        return mediaPlayer?.isPlaying() ?? false
    }

    open var duration: TimeInterval {
        return TimeInterval(mediaPlayer?.duration ?? 0) / 1000.0
    }

    open var numberOfLoops: Int {
        get { return _numberOfLoops }
        set {
            _numberOfLoops = newValue
            if newValue == -1 {
                mediaPlayer?.isLooping = true
            }
        }
    }

    open var volume: Double {
        get { return _volume }
        set {
            _volume = min(max(newValue, 0.0), 1.0)
            mediaPlayer?.setVolume(Float(_volume), Float(_volume))
        }
    }

    open var rate: Float {
        get { return _rate }
        set {
            _rate = newValue
            // Android's setPlaybackParams automatically starts playback when speed is non-zero
            // We need to preserve the playing state and restore it after setting params
            let wasPlaying = mediaPlayer?.isPlaying() ?? false
            mediaPlayer?.playbackParams = mediaPlayer?.playbackParams?.setSpeed(newValue) ?? android.media.PlaybackParams().setSpeed(newValue)
            if !wasPlaying {
                mediaPlayer?.pause()
            }
        }
    }

    open var currentTime: TimeInterval {
        get {
            return TimeInterval(mediaPlayer?.currentPosition ?? 0) / 1000.0
        }
        set {
            mediaPlayer?.seekTo(Int(newValue * 1000))
        }
    }

    open var url: URL? {
        return _url
    }

    open var data: Data? {
        return _data
    }
}
#endif
#endif
