// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import Foundation
import android.media.MediaRecorder
import android.media.AudioFormat
import android.media.MediaPlayer
import java.io.File
import java.io.FileOutputStream
import android.Manifest
import android.content.pm.PackageManager

public protocol AVAudioRecorderDelegate: AnyObject {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?)
}

public class AVAudioRecorder {
    private var recorder: MediaRecorder?
    private let context = ProcessInfo.processInfo.androidContext
    private var filePath: String?
    
    private var recordingStartTime: Date?
    public weak var delegate: AVAudioRecorderDelegate?
    
    private var _isRecording = false
    private var _url: URL
    private var _settings: [String: Any]
    
    @available(*, unavailable)
    var meteringEnabled = false
    
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
            
            // Ensures that an empty file exists (along with its parent directory) at the path before we attempt to write to it.
            file.parentFile?.mkdirs()
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
        do {
            prepareToRecord()
            recorder?.start()
            _isRecording = true
            recordingStartTime = Date()
        } catch {
            delegate?.audioRecorderEncodeErrorDidOccur(self, error: error)
        }
    }
    
    public func pause() {
        recorder?.pause()
        _isRecording = false
    }
    
    public func stop() {
        do {
            recorder?.stop()
            recorder?.release()
            recorder = nil
            _isRecording = false
            recordingStartTime = nil
            
            delegate?.audioRecorderDidFinishRecording(self, successfully: true)
        } catch {
            delegate?.audioRecorderDidFinishRecording(self, successfully: false)
            delegate?.audioRecorderEncodeErrorDidOccur(self, error: error)
        }
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
        if let startTime = recordingStartTime {
            return startTime.timeIntervalSinceNow
        } else {
            return TimeInterval(0)
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


