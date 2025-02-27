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
        static let shadowRadius: Float = 3.0
        static let shadowOpacity: Float = 0.2
        static let containerAlpha: CGFloat = 1.0  // Aseguramos opacidad completa
        static let contentZPosition: CGFloat = 10  // Para asegurar que el contenido esté por encima
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let backgroundAlpha: CGFloat = 1.0
        static let strokeAlpha: CGFloat = 0.2
    }
    
    // MARK: - Properties
    private let containerWidth: CGFloat
    private let containerNode: SKShapeNode
    
    private let effectNode: SKEffectNode
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
        
        // Inicializar nodos
        containerNode = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        effectNode = SKEffectNode()
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
        // Asegurarnos que el nodo principal esté por encima
        zPosition = Layout.contentZPosition
        
        // Configurar efecto de sombra con menos desenfoque
        effectNode.filter = CIFilter(
            name: "CIGaussianBlur",
            parameters: ["inputRadius": Layout.shadowRadius]
        )
        effectNode.shouldRasterize = true
        effectNode.shouldEnableEffects = true
        effectNode.zPosition = -1  // Poner la sombra detrás
        addChild(effectNode)
        
        // Configurar contenedor con opacidad completa
        containerNode.fillColor = .white
        containerNode.strokeColor = UIColor.gray.withAlphaComponent(Layout.strokeAlpha)
        containerNode.lineWidth = 1
        containerNode.alpha = Layout.containerAlpha
        effectNode.addChild(containerNode)
        
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
        
        // Añadir nodos
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

// MARK: Previews

#if DEBUG
extension FloatingTargetNoteNode {
    static func createPreviewScene() -> SKScene {
        SKScene.createPreviewScene(size: CGSize(width: 400, height: 200)) { scene in
            // Nodo con nota
            let activeNode = FloatingTargetNoteNode(width: 300)
            activeNode.targetNote = TunerEngine.Note(name: "A", octave: 4, alteration: .none) // Añadido alteration
            activeNode.position = CGPoint(x: 200, y: 120)
            scene.addChild(activeNode)
            
            // Nodo sin nota
            let inactiveNode = FloatingTargetNoteNode(width: 300)
            inactiveNode.animate(scale: 0.95, opacity: 0.7)
            inactiveNode.position = CGPoint(x: 200, y: 50)
            scene.addChild(inactiveNode)
        }
    }
}
#endif
