//
//  SpriteViewPreview.swift
//  MusicBlocks
//
//  Created by Jose R. García on 27/2/25.
//

import SwiftUI
import SpriteKit

#if DEBUG
/// Utilidad para mostrar nodos SpriteKit en SwiftUI previews
struct SpriteViewPreview<Scene: SKScene>: UIViewRepresentable {
    let scene: () -> Scene
    
    var showsFPS: Bool = false
    var showsNodeCount: Bool = false
    var showsDrawCount: Bool = false
    
    init(@ViewBuilder scene: @escaping () -> Scene) {
        self.scene = scene
    }
    
    init(
        showsFPS: Bool = false,
        showsNodeCount: Bool = false,
        showsDrawCount: Bool = false,
        @ViewBuilder scene: @escaping () -> Scene
    ) {
        self.showsFPS = showsFPS
        self.showsNodeCount = showsNodeCount
        self.showsDrawCount = showsDrawCount
        self.scene = scene
    }
    
    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        view.preferredFramesPerSecond = 60
        view.showsFPS = showsFPS
        view.showsNodeCount = showsNodeCount
        view.showsDrawCount = showsDrawCount
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ view: SKView, context: Context) {
        view.presentScene(scene())
    }
}

// Helpers para crear escenas
extension SKScene {
    static func createPreviewScene(
        size: CGSize,
        backgroundColor: SKColor = .clear,
        setup: (SKScene) -> Void
    ) -> SKScene {
        let scene = SKScene(size: size)
        scene.backgroundColor = backgroundColor
        setup(scene)
        return scene
    }
}
#endif
