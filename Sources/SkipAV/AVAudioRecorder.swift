// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
#if canImport(AVKit)
@_exported import AVKit
#elseif SKIP
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

public class AVAudioRecorder: KotlinConverting<MediaRecorder?> {
    private var recorder: MediaRecorder?
    private let context = ProcessInfo.processInfo.androidContext
    private var filePath: String?

    /// The start of the segment that is currently being recorded, or `nil` when not recording.
    private var recordingStartTime: Date?
    /// The duration of the segments recorded before the most recent `pause()`.
    private var accumulatedTime: TimeInterval = 0.0
    public weak var delegate: AVAudioRecorderDelegate?

    private var _isRecording = false
    /// Set by `pause()` so that the next `record()` resumes instead of restarting.
    private var isPaused = false
    private var _url: URL
    private var _settings: [String: Any]

    /// Turns level metering on or off. Metering is disabled by default, matching AVFoundation.
    public var isMeteringEnabled = false

    /// The amplitude sampled by the most recent `updateMeters()` call.
    private var meterAmplitude: Int = 0

    public init(url: URL, settings: [String: Any]) throws {
        self._url = url
        self._settings = settings

        if context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED {
            throw NSError(domain: "AudioRecorderError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio recording permission not granted"])
        }
        let _ = prepareToRecord()
    }

    // SKIP @nobridge
    public init(platformValue: MediaRecorder, url: URL) {
        self._url = url
        self._settings = [:]
        recorder = platformValue
    }

    // SKIP @nobridge
    public override func kotlin(nocopy: Bool = false) -> MediaRecorder? {
        return recorder
    }

    /// Reads a numeric entry from `settings`.
    ///
    /// AVFoundation's audio settings are documented as `NSNumber` values, so a caller may
    /// legitimately pass `44100`, `44100.0`, or a `Float`. Matching only against `Int` silently
    /// dropped the other two and fell back to the default.
    private func intSetting(_ key: String) -> Int? {
        guard let value = _settings[key] else {
            return nil
        }
        if let intValue = value as? Int {
            return intValue
        }
        if let doubleValue = value as? Double {
            return Int(doubleValue)
        }
        if let floatValue = value as? Float {
            return Int(floatValue)
        }
        return nil
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
                setAudioChannels(intSetting(AVNumberOfChannelsKey) ?? 2)
                setAudioSamplingRate(intSetting(AVSampleRateKey) ?? 44100)
                setAudioEncodingBitRate(intSetting(AVEncoderBitRateKey) ?? 128000)
                setOutputFile(filePath)
                prepare()
            }
            return true
        } catch {
            return false
        }
    }

    @discardableResult public func record() -> Bool {
        if recorder == nil && !prepareToRecord() {
            return false
        }
        do {
            if isPaused {
                recorder?.resume()
                isPaused = false
            } else {
                recorder?.start()
            }
            _isRecording = true
            recordingStartTime = Date()
            return true
        } catch {
            delegate?.audioRecorderEncodeErrorDidOccur(self, error: error)
            return false
        }
    }

    public func pause() {
        guard _isRecording else {
            return
        }
        recorder?.pause()
        if let startTime = recordingStartTime {
            accumulatedTime += Date().timeIntervalSince(startTime)
        }
        recordingStartTime = nil
        isPaused = true
        _isRecording = false
    }

    public func stop() {
        do {
            recorder?.stop()
            recorder?.release()
            recorder = nil
            _isRecording = false
            isPaused = false
            recordingStartTime = nil
            accumulatedTime = 0.0
            meterAmplitude = 0

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
        guard let startTime = recordingStartTime else {
            return accumulatedTime
        }
        return accumulatedTime + Date().timeIntervalSince(startTime)
    }

    /// Refreshes the values returned by `peakPower(forChannel:)` and `averagePower(forChannel:)`.
    ///
    /// `MediaRecorder.getMaxAmplitude()` reports the maximum amplitude sampled since it was last
    /// called and resets on every read, so the value is sampled once here and cached. Reading it
    /// directly from each accessor would make whichever accessor ran second observe silence.
    public func updateMeters() {
        guard isMeteringEnabled else {
            return
        }
        meterAmplitude = recorder?.maxAmplitude ?? 0
    }

    public func peakPower(forChannel channelNumber: Int) -> Float {
        return AVAudioRecorder.amplitudeToDecibels(meterAmplitude)
    }

    public func averagePower(forChannel channelNumber: Int) -> Float {
        // Android doesn't provide average power, so we'll return peak power
        return AVAudioRecorder.amplitudeToDecibels(meterAmplitude)
    }

    /// Converts an `android.media.MediaRecorder` amplitude (0...32767) to the
    /// decibel scale that AVFoundation's power accessors report, where full
    /// scale is 0 dB and silence is -160 dB.
    ///
    /// Exposed for testing; like `init(platformValue:url:)` this has no iOS counterpart.
    // SKIP @nobridge
    public static func amplitudeToDecibels(_ amplitude: Int) -> Float {
        guard amplitude > 0 else {
            return Float(-160.0)
        }
        // SkipLib provides log10(Double) and log10f(Float), but no log10(Float),
        // so the conversion is computed in Double and narrowed afterwards.
        return Float(20.0 * log10(Double(amplitude) / 32767.0))
    }
}
#endif
#endif
