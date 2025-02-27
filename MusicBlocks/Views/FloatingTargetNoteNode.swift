//
//  FloatingTargetNoteNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit

class FloatingTargetNoteNode: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let cornerRadius: CGFloat = 20
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 15
        static let titleFontSize: CGFloat = 18
        static let noteFontSize: CGFloat = 48
        static let verticalSpacing: CGFloat = 5
        static let containerAlpha: CGFloat = 1.0  // Aseguramos opacidad completa
        static let contentZPosition: CGFloat = 10  // Para asegurar que el contenido esté por encima
        static let backgroundAlpha: CGFloat = 1.0
        static let strokeAlpha: CGFloat = 0.2
    }
    
    // MARK: - Properties
    private let containerWidth: CGFloat
    private let containerNode: SKShapeNode
    
    private let titleLabel: SKLabelNode
    private let noteLabel: SKLabelNode
    
    private var currentScale: CGFloat = 1.0
    private var currentOpacity: CGFloat = 1.0
    
    var targetNote: TunerEngine.Note? {
        didSet {
            updateDisplay()
        }
    }
    
    // MARK: - Initialization
    init(width: CGFloat) {
        self.containerWidth = min(width * 0.4, 200)
        
        // Crear el contenedor principal
        let size = CGSize(
            width: containerWidth + Layout.horizontalPadding * 2,
            height: Layout.noteFontSize + Layout.titleFontSize + Layout.verticalSpacing + Layout.verticalPadding * 2
        )
        containerNode = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        
        titleLabel = SKLabelNode(fontNamed: "Helvetica")
        noteLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        
        super.init()
        
        setupNodes()
        updateDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        // Aseguramos que el nodo principal esté por encima
        zPosition = Layout.contentZPosition
        
        // Configurar contenedor con opacidad completa
        containerNode.fillColor = .white
        containerNode.strokeColor = UIColor.gray.withAlphaComponent(Layout.strokeAlpha)
        containerNode.lineWidth = 1
        containerNode.alpha = Layout.containerAlpha
        
        // Agregar el contenedor directamente al nodo principal (sin sombra)
        addChild(containerNode)
        
        // Configurar título
        titleLabel.fontSize = Layout.titleFontSize
        titleLabel.fontColor = UIColor.gray
        titleLabel.text = "Afina esta nota:"
        titleLabel.position = CGPoint(
            x: 0,
            y: Layout.noteFontSize/2 + Layout.verticalSpacing
        )
        
        // Configurar etiqueta de nota
        noteLabel.fontSize = Layout.noteFontSize
        noteLabel.fontColor = .black
        noteLabel.position = CGPoint(
            x: 0,
            y: -Layout.titleFontSize/2
        )
        
        // Añadir nodos al contenedor
        containerNode.addChild(titleLabel)
        containerNode.addChild(noteLabel)
    }
    
    // MARK: - Updates
    private func updateDisplay() {
        noteLabel.text = targetNote?.fullName ?? "-"
    }
    
    // MARK: - Animation
    func animate(scale: CGFloat, opacity: CGFloat) {
        let scaleAction = SKAction.scale(to: scale, duration: 0.3)
        let fadeAction = SKAction.fadeAlpha(to: opacity, duration: 0.3)
        
        run(SKAction.group([scaleAction, fadeAction]))
    }
}


#if DEBUG
import SwiftUI

extension FloatingTargetNoteNode {
    static func createPreviewScene() -> SKScene {
        // Crear una escena con el tamaño deseado
        let scene = SKScene(size: CGSize(width: 300, height: 200))
        scene.backgroundColor = .white
        
        // Crear una instancia del nodo de nota flotante
        let floatingNoteNode = FloatingTargetNoteNode(width: 300)
        // Opcional: Si tienes un ejemplo o dummy de TunerEngine.Note, asignarlo aquí.
        // floatingNoteNode.targetNote = TunerEngine.Note(ejemplo: "A4")
        
        // Centrar el nodo en la escena
        floatingNoteNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        scene.addChild(floatingNoteNode)
        
        return scene
    }
}

struct FloatingTargetNotePreview: PreviewProvider {
    static var previews: some View {
        SpriteView(scene: FloatingTargetNoteNode.createPreviewScene())
            .frame(width: 300, height: 200)
            .previewLayout(.fixed(width: 300, height: 200))
    }
}
#endif
