// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if !SKIP_BRIDGE
import SwiftUI
#if SKIP
import androidx.compose.runtime.Composable
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.ui.PlayerView
import androidx.media3.ui.AspectRatioFrameLayout

public struct VideoPlayer: View {
    let player: AVPlayer

    public init(player: AVPlayer) {
        self.player = player
    }

    @Composable public override func ComposeContent(context: ComposeContext) {
        ComposeContainer(modifier: context.modifier, fillWidth: true, fillHeight: true) { modifier in
            AndroidView(factory: { ctx in
                let playerView = PlayerView(ctx)
                player.prepare(ctx)
                playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
                playerView.controllerAutoShow = false // hide controls initially, like on iOS
                //playerView.controllerHideOnTouch = true
                //playerView.controllerShowTimeoutMs = 0
                //playerView.setKeepContentOnPlayerReset = true
                playerView.player = player.mediaPlayer
                return playerView
            }, modifier: modifier, update: { playerView in
            })
        }
    }
}
#endif
#endif

