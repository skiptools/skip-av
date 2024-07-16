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
#endif

#if SKIP
public protocol AVAudioRecorderDelegate: AnyObject {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?)
}

public class AVAudioRecorder {
    private var recorder: MediaRecorder?
    private let context = ProcessInfo.processInfo.androidContext
    private var filePath: String?
    
    private var _isRecording = false
    private var _url: URL
    private var _settings: [String: Any]
    
    public init(url: URL, settings: [String: Any]) throws {
        self._url = url
        self._settings = settings
        
        if context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED {
            throw NSError(domain: "AudioRecorderError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio recording permission not granted"])
        }
        let _ = prepareToRecord()
    }
    
    public func prepareToRecord() -> Bool {
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
    }
    
    public func record() {
        prepareToRecord()
        recorder?.start()
        _isRecording = true
    }
    
    public func pause() {
        recorder?.pause()
        _isRecording = false
    }
    
    public func stop() {
        recorder?.stop()
        recorder?.release()
        recorder = nil
        _isRecording = false
    }
    
    public func deleteRecording() -> Bool {
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
        return TimeInterval(recorder?.maxAmplitude ?? 0) / 32767.0
    }
    
    // MARK: - Metering
    
    private var meteringEnabled = false
    
    public var isMeteringEnabled: Bool {
        get {
            return meteringEnabled
        }
        set {
            meteringEnabled = newValue
        }
    }
    
    public func peakPower(forChannel channelNumber: Int) -> Float {
        return Float(recorder?.maxAmplitude ?? 0) / Float(32767.0)
    }
    
    public func averagePower(forChannel channelNumber: Int) -> Double {
        // Android doesn't provide average power, so we'll return peak power
        return Double(recorder?.maxAmplitude ?? 0) / 32767.0
    }
 
}
#endif


