# SkipAV

Audio/Video functionality for [Skip Lite](https://skip.tools) apps.

See what API is included [here](#api-support).

## About 

The SkipAV framework provides a small subset of the `AVKit` and `AVFoundation` frameworks
as well as a `SwiftUI.VideoPlayer` component for
Android based on the `androidx.media3` package's ExoPlayer.

## Dependencies

SkipAV depends on the [skip](https://source.skip.tools/skip) transpiler plugin and the [SkipUI](https://source.skip.tools/skip-ui) package.

SkipAV is part of the core *SkipStack* and is not intended to be imported directly. The transpiler includes `import skip.av.*` in generated Kotlin for any Swift source that imports the `AVKit` or `AVFoundation` frameworks.

## Contributing

We welcome contributions to SkipAV. The Skip product [documentation](https://skip.tools/docs/contributing/) includes helpful instructions and tips on local Skip library development.

## Examples

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

```swift
import SwiftUI
import AVFoundation

struct AudioPlayground: View {
    @State var isRecording: Bool = false
    @State var errorMessage: String? = nil
    
    @State var audioRecorder: AVAudioRecorder?
    @State var audioPlayer: AVAudioPlayer?

    var body: some View {
        #if SKIP
        let context = androidx.compose.ui.platform.LocalContext.current
        #endif
        return VStack {
            Button(isRecording ? "Stop Recording" : "Start Recording") {
                self.isRecording ? self.stopRecording() : self.startRecording()
            }
            Button("Play Recording") {
                try? self.playRecording()
            }
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
        #if SKIP
        .onAppear {
            requestAudioRecordingPermission(context: context)
        }
        #endif
    }

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
    
    func startRecording() {
        do {
            #if !SKIP
            setupAudioSession()
            #endif
            self.audioRecorder = try AVAudioRecorder(url: captureURL, settings: [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue])
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
    
    #if SKIP
    func requestAudioRecordingPermission(context: android.content.Context) {
        guard let activity = context as? android.app.Activity else {
            return
        }

        // You must also list these permissions in your Manifest.xml
        let permissions = listOf(android.Manifest.permission.RECORD_AUDIO, android.Manifest.permission.READ_EXTERNAL_STORAGE, android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
        androidx.core.app.ActivityCompat.requestPermissions(activity, permissions.toTypedArray(), 1)
    }
    
    #else
    
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
 
## API Support

The following table summarizes SkipAV's API support on Android. Anything not listed here is likely not supported. Note that in your iOS-only code - i.e. code within `#if !SKIP` blocks - you can use any Swift API you want. Additionally:

Support levels:

  - ✅ – Full
  - 🟢 – High
  - 🟡 – Medium 
  - 🟠 – Low
  
<table>
  <thead><th>Support</th><th>API</th></thead>
  <tbody>
    <tr>
      <td>🟢</td>
      <td>
          <details>
              <summary><code>AVAudioPlayer</code></summary>
              <ul>
                  <li><code>init(contentsOf url: URL) throws</code></li>
                  <li><code>init(data: Data) throws</code></li>
                  <li><code>func prepareToPlay() -> Bool</code></li>
                  <li><code>func play()</code></li>
                  <li><code>func pause()</code></li>
                  <li><code>func stop()</code></li>
                  <li><code>var isPlaying: Bool</code></li>
                  <li><code>var duration: TimeInterval</code></li>
                  <li><code>var numberOfLoops: Int</code></li>
                  <li><code>var volume: Double</code></li>
                  <li><code>var rate: Double</code></li>
                  <li><code>var currentTime: TimeInterval</code></li>
                  <li><code>var url: URL?</code></li>
                  <li><code>var data: Data?</code></li>
              </ul>
          </details> 
      </td>
    </tr>
    <tr>
      <td>🟢</td>
      <td>
          <details>
              <summary><code>AVAudioRecorder</code></summary>
              <ul>
                  <li><code>init(url: URL, settings: [String: Any]) throws</code></li>
                  <li><code>func prepareToRecord() -> Bool</code></li>
                  <li><code>func record()</code></li>
                  <li><code>func pause()</code></li>
                  <li><code>func stop()</code></li>
                  <li><code>func deleteRecording() -> Bool</code></li>
                  <li><code>var isRecording: Bool</code></li>
                  <li><code>var url: URL</code></li>
                  <li><code>var settings: [String: Any]</code></li>
                  <li><code>var currentTime: TimeInterval</code></li>
                  <li><code>func peakPower(forChannel channelNumber: Int) -> Float</code></li>
                  <li><code>func averagePower(forChannel channelNumber: Int) -> Double</code></li>
              </ul>
          </details> 
      </td>
    </tr>
    <tr>
      <td>🟠</td>
      <td>
          <details>
              <summary><code>AVPlayer</code></summary>
              <ul>
                  <li><code>init()</code></li>
                  <li><code>init(playerItem: AVPlayerItem?)</code></li>
                  <li><code>init(url: URL)</code></li>
                  <li><code>func play()</code></li>
                  <li><code>func pause()</code></li>
                  <li><code>func seek(to time: CMTime)</code></li>
              </ul>
          </details> 
      </td>
    </tr>
   <tr>
      <td>🟠</td>
      <td>
          <details>
              <summary><code>AVPlayerItem</code></summary>
              <ul>
                  <li><code>init(url: URL)</code></li>
              </ul>
          </details> 
      </td>
    </tr>
   <tr>
      <td>🟡</td>
      <td>
          <details>
              <summary><code>VideoPlayer</code></summary>
              <ul>
                  <li><code>init(player: AVPlayer?)</code></li>
              </ul>
          </details> 
      </td>
    </tr>
  </tbody>
</table>

## License

This software is licensed under the
[GNU Lesser General Public License v3.0](https://spdx.org/licenses/LGPL-3.0-only.html),
with the following
[linking exception](https://spdx.org/licenses/LGPL-3.0-linking-exception.html)
to clarify that distribution to restricted environments (e.g., app stores)
is permitted:

> This software is licensed under the LGPL3, included below.
> As a special exception to the GNU Lesser General Public License version 3
> ("LGPL3"), the copyright holders of this Library give you permission to
> convey to a third party a Combined Work that links statically or dynamically
> to this Library without providing any Minimal Corresponding Source or
> Minimal Application Code as set out in 4d or providing the installation
> information set out in section 4e, provided that you comply with the other
> provisions of LGPL3 and provided that you meet, for the Application the
> terms and conditions of the license(s) which apply to the Application.
> Except as stated in this special exception, the provisions of LGPL3 will
> continue to comply in full to this Library. If you modify this Library, you
> may apply this exception to your version of this Library, but you are not
> obliged to do so. If you do not wish to do so, delete this exception
> statement from your version. This exception does not (and cannot) modify any
> license terms which apply to the Application, with which you must still
> comply.

