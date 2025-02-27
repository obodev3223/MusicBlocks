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
    /// La escena que se va a mostrar
    let scene: () -> Scene
    
    /// Configuración adicional de la vista
    var showsFPS: Bool = false
    var showsNodeCount: Bool = false
    var showsDrawCount: Bool = false
    
    /// Inicializador con un builder de escena
    init(@ViewBuilder scene: @escaping () -> Scene) {
        self.scene = scene
    }
    
    /// Inicializador con configuración adicional
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
    
    /// Crea la vista de SpriteKit
    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        view.preferredFramesPerSecond = 60
        view.showsFPS = showsFPS
        view.showsNodeCount = showsNodeCount
        view.showsDrawCount = showsDrawCount
        view.backgroundColor = .clear
        return view
    }
    
    /// Actualiza la vista con la escena proporcionada
    func updateUIView(_ view: SKView, context: Context) {
        view.presentScene(scene())
    }
}

extension SpriteViewPreview {
    /// Helper para crear una escena de preview básica
    static func createBasicScene(
        size: CGSize,
        setupNode: (SKNode) -> Void
    ) -> SKScene {
        let scene = SKScene(size: size)
        scene.backgroundColor = .clear
        
        let node = SKNode()
        setupNode(node)
        scene.addChild(node)
        
        return scene
    }
    
    /// Helper para crear una escena de preview con fondo
    static func createSceneWithBackground(
        size: CGSize,
        backgroundColor: UIColor = .systemGray.withAlphaComponent(0.3),
        setupNode: (SKNode) -> Void
    ) -> SKScene {
        let scene = SKScene(size: size)
        scene.backgroundColor = backgroundColor
        
        let node = SKNode()
        setupNode(node)
        scene.addChild(node)
        
        return scene
    }
}

// MARK: - Preview Example
struct SpriteViewPreview_Previews: PreviewProvider {
    static var previews: some View {
        // Ejemplo de uso básico
        SpriteViewPreview {
            let scene = SKScene(size: CGSize(width: 200, height: 200))
            scene.backgroundColor = .clear
            
            let node = SKShapeNode(circleOfRadius: 50)
            node.fillColor = .blue
            node.position = CGPoint(x: 100, y: 100)
            scene.addChild(node)
            
            return scene
        }
        .frame(width: 200, height: 200)
        .background(Color.gray.opacity(0.3))
        .previewDisplayName("Basic Preview")
        
        // Ejemplo con estadísticas
        SpriteViewPreview(
            showsFPS: true,
            showsNodeCount: true,
            showsDrawCount: true
        ) {
            SpriteViewPreview.createSceneWithBackground(
                size: CGSize(width: 200, height: 200)
            ) { parentNode in
                let circle = SKShapeNode(circleOfRadius: 30)
                circle.fillColor = .red
                circle.position = CGPoint(x: 100, y: 100)
                parentNode.addChild(circle)
            }
        }
        .frame(width: 200, height: 200)
        .previewDisplayName("Preview with Stats")
    }
}
#endif