// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
#if canImport(AVKit)
@_exported import AVKit
#elseif SKIP
import SwiftUI
import androidx.compose.runtime.Composable
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.ui.PlayerView
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.compose.PlayerSurface
import androidx.media3.ui.compose.SURFACE_TYPE_SURFACE_VIEW
import androidx.media3.ui.compose.modifiers.resizeWithContentScale
import androidx.media3.ui.compose.state.rememberPresentationState
import androidx.compose.ui.platform.LocalContext

public struct VideoPlayer: View {
    let player: AVPlayer

    public init(player: AVPlayer) {
        self.player = player
    }

    // SKIP @nobridge
    @Composable public override func ComposeContent(context: ComposeContext) {
        ComposeContainer(modifier: context.modifier, fillWidth: true, fillHeight: false) { modifier in
            // we could use the newer Compose PlayerSurface, but unlike the older PlayerView, it doesn't include built-in playback controls, so we would need to create our own
            /*
            player.prepare(LocalContext.current)
            let presentationState = rememberPresentationState(player.mediaPlayer!)
            PlayerSurface(player: player.mediaPlayer!, surfaceType: SURFACE_TYPE_SURFACE_VIEW, modifier: modifier.resizeWithContentScale(ContentScale.Fit, presentationState.videoSizeDp))
             */

            AndroidView(factory: { ctx in
                let playerView = PlayerView(ctx)
                player.prepare(ctx)
                playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
                playerView.controllerAutoShow = false // hide controls initially, like on iOS
                playerView.player = player.mediaPlayer
                return playerView
            }, modifier: modifier, update: { playerView in
            })
        }
    }
}
#endif
#endif
