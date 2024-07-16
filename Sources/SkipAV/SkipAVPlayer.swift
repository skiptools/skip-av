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
#else
import AVFoundation
#endif

public protocol AVAudioPlayerDelegate: AnyObject {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?)
}

open class AVAudioPlayer: NSObject {
    
    #if SKIP
    private var mediaPlayer: MediaPlayer?
    private let context = ProcessInfo.processInfo.androidContext
    #else
    private var player: AVFoundation.AVAudioPlayer?
    #endif
    
    weak open var delegate: AVAudioPlayerDelegate?
    
    private var _numberOfLoops: Int = 0
    private var _volume: Double = 1.0
    private var _rate: Double = 1.0
    private var _pan: Double = 0.0
    private var _url: URL?
    private var _data: Data?
    
    public init(contentsOf url: URL) throws {
        self._url = url
        #if SKIP
        super.init()
        try initializeMediaPlayer(url: url)
        #else
        super.init()
        self.player = try AVFoundation.AVAudioPlayer(contentsOf: url)
        #endif
    }
    
    // MARK: - Untested implementation.
    public init(data: Data) throws {
        self._data = data
        #if SKIP
        super.init()
        try initializeMediaPlayer(data: data)
        #else
        super.init()
        self.player = try AVFoundation.AVAudioPlayer(data: data)
        #endif
    }
    
    #if SKIP
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
    #endif
    
    open func prepareToPlay() -> Bool {
        #if SKIP
        return mediaPlayer != nil
        #else
//        return player?.prepareToPlay() ?? false
        return true
        #endif
    }
    
    open func play() {
        #if SKIP
        mediaPlayer?.start()
        #else
        player?.play()
        #endif
    }
    
    open func pause() {
        #if SKIP
        mediaPlayer?.pause()
        #else
        player?.pause()
        #endif
    }
    
    open func stop() {
        #if SKIP
        mediaPlayer?.stop()
        mediaPlayer?.reset()
        #else
        player?.stop()
        #endif
    }
    
    open var isPlaying: Bool {
        #if SKIP
        return mediaPlayer?.isPlaying() ?? false
        #else
        return player?.isPlaying ?? false
        #endif
    }
    
    open var duration: TimeInterval {
        #if SKIP
        return TimeInterval(mediaPlayer?.duration ?? 0) / 1000.0
        #else
        return player?.duration ?? 0
        #endif
    }
    
    open var numberOfLoops: Int {
        get { return _numberOfLoops }
        set {
            _numberOfLoops = newValue
            #if SKIP
            if newValue == -1 {
                mediaPlayer?.isLooping = true
            }
            #else
            player?.numberOfLoops = newValue
            #endif
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
    
    open var pan: Double {
        get { return _pan }
        set {
            _pan = newValue
            #if SKIP
            // Android doesn't have a direct equivalent to pan
            #else
            player?.pan = Float(newValue)
            #endif
        }
    }
    
    open var currentTime: TimeInterval {
        get {
            #if SKIP
            return TimeInterval(mediaPlayer?.currentPosition ?? 0) / 1000.0
            #else
            return player?.currentTime ?? 0
            #endif
        }
        set {
            #if SKIP
            mediaPlayer?.seekTo(Int(newValue * 1000))
            #else
            player?.currentTime = newValue
            #endif
        }
    }
    
    open var url: URL? {
        return _url
    }
    
    open var data: Data? {
        return _data
    }
}


//public class AVAudioPlayer {
//#if SKIP
//    private var mediaPlayer: MediaPlayer? = nil
//#else
//    private var player: AVFoundation.AVAudioPlayer?
//#endif
//    
//    public init() {}
//    
//    public func play(url: URL) throws {
//#if SKIP
//        stopPlaying()
//        let context = ProcessInfo.processInfo.androidContext
//        let file = File(context.getExternalFilesDir(nil), "recording.m4a")
//        let filePath = file.absolutePath
//        
//        mediaPlayer = MediaPlayer().apply {
//            setDataSource(filePath) // originally url.path
//            prepare()
//            start()
//        }
//#else
//        player = try AVFoundation.AVAudioPlayer(contentsOf: url)
//        player?.play()
//#endif
//    }
//    
//    public func stopPlaying() {
//#if SKIP
//        mediaPlayer?.apply {
//            stop()
//            release()
//        }
//        mediaPlayer = nil
//#else
//        player?.stop()
//#endif
//    }
//    
//    public func pause() {
//#if SKIP
//        mediaPlayer?.pause()
//#else
//        player?.pause()
//#endif
//    }
//    
//    public func resume() {
//#if SKIP
//        mediaPlayer?.start()
//#else
//        player?.play()
//#endif
//    }
//}

