// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import SwiftUI
#if SKIP
import android.media.AudioFormat
import android.media.MediaPlayer
import java.io.File

import android.Manifest
import android.content.pm.PackageManager
#endif

#if SKIP
public protocol AVAudioPlayerDelegate: AnyObject {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?)
}

open class AVAudioPlayer: NSObject {
    private var mediaPlayer: MediaPlayer?
    private let context = ProcessInfo.processInfo.androidContext
    
    weak open var delegate: AVAudioPlayerDelegate?
    
    private var _numberOfLoops: Int = 0
    private var _volume: Double = 1.0
    private var _rate: Double = 1.0
    private var _pan: Double = 0.0
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
                setDataSource(context, android.net.Uri.parse(url.absoluteString))
                prepare()
            }
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
        } catch {
            throw NSError(domain: "AudioPlayerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Media Player (Android): \(error.localizedDescription)"])
        }
    }
    
    open func prepareToPlay() -> Bool {
        return mediaPlayer != nil
    }
    
    open func play() {
        mediaPlayer?.start()
    }
    
    open func pause() {
        mediaPlayer?.pause()
    }
    
    open func stop() {
        mediaPlayer?.stop()
        mediaPlayer?.reset()
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
    
    /// NOTE: newValue's Kotlin Float type is confusing the transpiler. Leaving these two properties to be fixed in a future PR.
//    open var volume: Double {
//        get { return _volume }
//        set {
//            _volume = newValue
//            #if SKIP
//            mediaPlayer?.setVolume(newValue, newValue)
//            #else
//            player?.volume = Float(newValue)
//            #endif
//        }
//    }
//    
//    open var rate: Double {
//        get { return _rate }
//        set {
//            _rate = newValue
//            #if SKIP
//            if android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M {
//                mediaPlayer?.playbackParams = mediaPlayer?.playbackParams?.setSpeed(newValue) ?? android.media.PlaybackParams().setSpeed(newValue)
//            }
//            #else
//            player?.rate = Float(newValue)
//            #endif
//        }
//    }
    
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
