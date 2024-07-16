// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import SwiftUI
#if SKIP
import android.media.MediaRecorder
import android.media.AudioFormat
import android.media.MediaPlayer
import java.io.File
import java.io.FileOutputStream
import android.Manifest
import android.content.pm.PackageManager
#else
import AVFoundation
#endif

public protocol AVAudioRecorderDelegate: AnyObject {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?)
}

public class AVAudioRecorder {
#if SKIP
    private var recorder: MediaRecorder?
    private let context = ProcessInfo.processInfo.androidContext
    private var filePath: String?
#else
    private var recorder: AVFoundation.AVAudioRecorder?
#endif
    
    private var _isRecording = false
    private var _url: URL
    private var _settings: [String: Any]
    
    public init(url: URL, settings: [String: Any]) throws {
        self._url = url
        self._settings = settings
        
#if !SKIP
        let avSettings = settings
        self.recorder = try AVFoundation.AVAudioRecorder(url: url, settings: avSettings)
#else
        if context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED {
            throw NSError(domain: "AudioRecorderError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio recording permission not granted"])
        }
#endif
        let _ = prepareToRecord()
    }
    
    public func prepareToRecord() -> Bool {
#if SKIP
        do {
            let file = File(_url.path)
            filePath = file.absolutePath
            
            file.parentFile?.mkdirs()
            FileOutputStream(file, false).close()
            
            file.createNewFile()
            
            recorder = MediaRecorder(context).apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioChannels(2)
                setAudioSamplingRate(settings["AVSampleRateKey"] as? Int ?? 44100)
                setAudioEncodingBitRate(settings["AVEncoderBitRateKey"] as? Int ?? 128000)
                setOutputFile(filePath)
                prepare()
            }
            return true
        } catch {
            return false
        }
#else
        // already executed in record() implementation.
//        return recorder?.prepareToRecord() ?? false
        return false
#endif
    }
    
    public func record() {
#if SKIP
        prepareToRecord()
        recorder?.start()
        _isRecording = true
#else
        let recordingSession = AVAudioSession.sharedInstance()
        try! recordingSession.setCategory(.playAndRecord, mode: .default)
        try! recordingSession.setActive(true)
        
        recorder = try! AVFoundation.AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
#endif
    }
    
    public func pause() {
#if SKIP
        recorder?.pause()
#else
        recorder?.pause()
#endif
        _isRecording = false
    }
    
    public func stop() {
#if SKIP
        recorder?.stop()
        recorder?.release()
        recorder = nil
#else
        recorder?.stop()
        recorder = nil
#endif
        _isRecording = false
    }
    
    public func deleteRecording() -> Bool {
#if SKIP
        stop()
        if let path = filePath {
            let file = File(path)
            if file.exists() {
                return file.delete()
            } else {
                return false
            }
        } else {
            return false
        }
#else
        return recorder?.deleteRecording() ?? false
#endif
    }
    
    public var isRecording: Bool {
        return self._isRecording
    }
    
    public var url: URL {
        return self._url
    }
    
    public var settings: [String: Any] {
        return self._settings
    }
    
    public var currentTime: TimeInterval {
#if SKIP
        return TimeInterval(recorder?.maxAmplitude ?? 0) / 32767.0
#else
        return recorder?.currentTime ?? 0
#endif
    }
    
    // MARK: - Metering
    
    private var meteringEnabled = false
    
    public var isMeteringEnabled: Bool {
        get {
            return meteringEnabled
        }
        set {
            meteringEnabled = newValue
#if !SKIP
            recorder?.isMeteringEnabled = newValue
#endif
        }
    }
    
    public func updateMeters() {
#if !SKIP
        recorder?.updateMeters()
#endif
    }
    
    public func peakPower(forChannel channelNumber: Int) -> Float {
#if SKIP
        return Float(recorder?.maxAmplitude ?? 0) / Float(32767.0)
#else
        return recorder?.peakPower(forChannel: channelNumber) ?? 0
#endif
    }
    
    public func averagePower(forChannel channelNumber: Int) -> Double {
#if SKIP
        // Android doesn't provide average power, so we'll return peak power
        return Double(recorder?.maxAmplitude ?? 0) / 32767.0
#else
        return Double(recorder?.averagePower(forChannel: channelNumber) ?? 0)
#endif
    }
}




