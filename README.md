# SkipAV

The SkipAV framework provides a `SwiftUI.VideoPlayer` component for
Android based on the `androidx.media3` package's ExoPlayer. It can be
used as a drop-in component to provide video playback controls.

A subset of the `AVKit` framework is provided.

## Example

```swift
import SwiftUI
import AVKit

struct PlayerView: View {
    @State var player = AVPlayer(playerItem: AVPlayerItem(url: URL(string: "https://skip.tools/assets/introduction.mov")!))
    @State var isPlaying: Bool = false

    var body: some View {
        VStack {
            Button {
                isPlaying ? player.pause() : player.play()
                isPlaying = !isPlaying
                player.seek(to: .zero)
            } label: {
                Image(systemName: isPlaying ? "stop" : "play")
                    .padding()
            }

            VideoPlayer(player: player)
        }
    }
}
```

This framework also supports the 'AVFoundation.AVAudioRecorder' and 
AVFoundation.AVAudioPlayer' APIs via Android's MediaRecorder and MediaPlayer. 
These APIs can be used for audio recording and playback.

## Example 2

```swift
import SwiftUI
#if SKIP
import SkipAV
#else
import AVFoundation
#endif

struct AudioPlayground: View {
    @State var isRecording: Bool = false
    @State var errorMessage: String? = nil
    
    @State var audioRecorder: AVAudioRecorder?
    @State var audioPlayer: AVAudioPlayer?
    
    var captureURL: URL {
        get {
#if SKIP
            let context = ProcessInfo.processInfo.androidContext
            let file = java.io.File(context.filesDir, "recording.m4a")
            return URL(fileURLWithPath: file.absolutePath)
#else
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
                .first!.appendingPathComponent("recording.m4a")
#endif
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                self.isRecording ? self.stopRecording() : self.startRecording()
            }) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .fontWeight(.bold)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
            .padding()
            .foregroundColor(.white)
            .background(isRecording ? Color.red : Color.green)
            .cornerRadius(10)
            
            Button(action: {
                try? self.playRecording()
            }) {
                Text("Play Recording")
                    .fontWeight(.bold)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
            .shadow(radius: 5)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    func startRecording() {
        do {
            #if !SKIP
            setupAudioSession()
            #endif
            self.audioRecorder = try AVAudioRecorder(url: captureURL, settings: [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1,
                                                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue])
        } catch {
            print(error.localizedDescription)
        }
        audioRecorder?.record()
        isRecording = true
    }
    
    func stopRecording() {
        isRecording = false
        audioRecorder?.stop()
    }
    
    func playRecording() throws {
        do {
            guard FileManager.default.fileExists(atPath: captureURL.path) else {
                errorMessage = "Recording file does not exist."
                return
            }
            audioPlayer = try AVAudioPlayer(contentsOf: captureURL)
            
            audioPlayer?.play()
            
            errorMessage = ""
        } catch {
            logger.error("Could not play audio: \(error.localizedDescription)")
            errorMessage = "Could not play audio: \(error.localizedDescription)"
        }
    }
    
    #if !SKIP
    func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    #endif
}
```
 


## Building

This project is a free Swift Package Manager module that uses the
[Skip](https://skip.tools) plugin to transpile Swift into Kotlin.

Building the module requires that Skip be installed using 
[Homebrew](https://brew.sh) with `brew install skiptools/skip/skip`.
This will also install the necessary build prerequisites:
Kotlin, Gradle, and the Android build tools.

## Testing

The module can be tested using the standard `swift test` command
or by running the test target for the macOS destination in Xcode,
which will run the Swift tests as well as the transpiled
Kotlin JUnit tests in the Robolectric Android simulation environment.

Parity testing can be performed with `skip test`,
which will output a table of the test results for both platforms.
