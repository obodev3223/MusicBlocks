//
//  StabilityCounterNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit

class StabilityCounterNode: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let primaryFontRatio: CGFloat = 0.15
        static let secondaryFontRatio: CGFloat = 0.10
        static let cornerRadius: CGFloat = 8
        static let backgroundAlpha: CGFloat = 0.15
        static let animationDuration: TimeInterval = 0.2
        static let glowRadius: Float = 8.0
    }
    
    // MARK: - Properties
    private let containerSize: CGSize
    private let container: SKShapeNode
    private let timeLabel: SKLabelNode
    private let unitLabel: SKLabelNode
    private let glowNode: SKEffectNode
    
    var duration: TimeInterval = 0 {
        didSet {
            updateDisplay()
        }
    }
    
    // MARK: - Initialization
    init(size: CGSize) {
        self.containerSize = size
        
        // Inicializar contenedor
        container = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        glowNode = SKEffectNode()
        
        // Inicializar etiquetas
        timeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        timeLabel.fontSize = size.height * Layout.primaryFontRatio
        timeLabel.verticalAlignmentMode = .center
        timeLabel.fontColor = .black
        
        unitLabel = SKLabelNode(fontNamed: "Helvetica")
        unitLabel.fontSize = size.height * Layout.secondaryFontRatio
        unitLabel.verticalAlignmentMode = .center
        unitLabel.fontColor = .gray
        unitLabel.text = "seg"
        
        super.init()
        
        setupNodes()
        updateDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        // Configurar contenedor
        container.fillColor = .white
        container.strokeColor = .clear
        container.alpha = Layout.backgroundAlpha
        addChild(container)
        
        // Configurar glow
        glowNode.filter = CIFilter(name: "CIGaussianBlur",
                                 parameters: ["inputRadius": Layout.glowRadius])
        glowNode.shouldRasterize = true
        addChild(glowNode)
        
        // Posicionar etiquetas
        timeLabel.position = CGPoint(x: -20, y: 0)
        unitLabel.position = CGPoint(x: 20, y: 0)
        
        // Añadir etiquetas
        container.addChild(timeLabel)
        container.addChild(unitLabel)
    }
    
    // MARK: - Updates
    private func updateDisplay() {
        timeLabel.text = String(format: "%.1f", duration)
        
        // Actualizar glow según la duración
        let normalizedDuration = CGFloat(min(duration, 10.0) / 10.0)
        glowNode.alpha = normalizedDuration * 0.5
        
        animateUpdate()
    }
    
    private func animateUpdate() {
        let scaleUp = SKAction.scale(to: 1.05, duration: Layout.animationDuration / 2)
        let scaleDown = SKAction.scale(to: 1.0, duration: Layout.animationDuration / 2)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        
        timeLabel.run(sequence)
    }
    
    // MARK: - Public Methods
    func reset() {
        duration = 0
        glowNode.alpha = 0
    }
}

// MARK: Previews
#if DEBUG
extension StabilityCounterNode {
    static func createPreviewScene() -> SKScene {
        SKScene.createPreviewScene(size: CGSize(width: 300, height: 200)) { scene in
            // Nodo con valor medio
            let mediumNode = StabilityCounterNode(size: CGSize(width: 120, height: 60))
            mediumNode.position = CGPoint(x: 150, y: 120)
            mediumNode.duration = 5.5
            scene.addChild(mediumNode)
            
            // Nodo con valor máximo
            let maxNode = StabilityCounterNode(size: CGSize(width: 120, height: 60))
            maxNode.position = CGPoint(x: 150, y: 60)
            maxNode.duration = 10.0
            scene.addChild(maxNode)
        }
    }
}

struct StabilityCounterPreview: PreviewProvider {
    static var previews: some View {
        SpriteViewPreview {
            StabilityCounterNode.createPreviewScene()
        }
        .frame(width: 300, height: 200)
        .previewLayout(.fixed(width: 300, height: 200))
    }
}
#endif
