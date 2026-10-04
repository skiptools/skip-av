// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0
#if !SKIP_BRIDGE
#if canImport(AVKit)
@_exported import AVKit
#elseif SKIP
import SwiftUI
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.ui.PlayerView
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.compose.material3.Player
import androidx.media3.ui.compose.modifiers.resizeWithContentScale
import androidx.media3.ui.compose.state.rememberPresentationState
import kotlinx.coroutines.delay

public struct VideoPlayer: View {
    
    let player: AVPlayer
    
    var isFullscreen: Binding<Bool>?

    public init(player: AVPlayer) {
        self.player = player
        self.isFullscreen = nil
    }
    
    /// Android-only API to handle fullscreen button
    public init(player: AVPlayer, isFullscreen: Binding<Bool>) {
        self.player = player
        self.isFullscreen = isFullscreen
    }

    // SKIP @nobridge
    @Composable public override func ComposeContent(context: ComposeContext) {
        ComposeContainer(modifier: context.modifier, fillWidth: true, fillHeight: false) { modifier in
            // the new Compose Player does not auto-hide controls, so we need to manage this manually

            // this technique is based on https://github.com/androidx/media/blob/main/demos/compose/src/main/java/androidx/media3/demo/compose/layout/MainScreen.kt#L121

            /* SKIP INSERT:

            var showControls by remember { mutableStateOf(true) }
            var anyPointerDown by remember { mutableStateOf(false) }
            LaunchedEffect(showControls, anyPointerDown) {
              if (showControls && !anyPointerDown) {
                var CONTROLS_VISIBILITY_TIMEOUT_MS = Long(3000)
                delay(CONTROLS_VISIBILITY_TIMEOUT_MS)
                showControls = false
              }
            }
            */

            Player(player: player.mediaPlayer!,
                   showControls: showControls,
                   // not yet working
                   // we need some modifiers like playerGestures in https://github.com/v-novaltd/androidx-media/blob/ae06ff489eb737bb6141f075e7d602873aeb84b8/demos/compose/src/main/java/androidx/media3/demo/compose/layout/modifiers.kt#L52
                   modifier: modifier
                    //.playerGestures(
                    //onPointerDownChange: { anyPointerDown = it },
                    //onToggleControls: { showControls = !showControls },
                    //playbackSpeedState: playbackSpeedState,
                    //seekBackButtonState: rememberSeekBackButtonState(player),
                    //seekForwardButtonState: rememberSeekForwardButtonState(player),
                    //seekBackActionArea: { offset -> offset.x < size.width / 2 },
                    //seekForwardActionArea: { offset -> offset.x >= size.width / 2 },
                    //onSeek: {
                    //  showControls = false
                    //  seekOverlayState.show(it)
                    //},
                    //fastForwardActionArea: { offset -> offset.x >= size.width / 2 },
                    //onFastForward: {
                    //  showControls = false
                    //  showFastForward = it
                    //},
                    //)
                   )
        }
    }
}

#endif
#endif
