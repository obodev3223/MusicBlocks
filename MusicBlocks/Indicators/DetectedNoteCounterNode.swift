//
//  DetectedNoteCounterNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit

class DetectedNoteCounterNode: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let cornerRadius: CGFloat = 8
        static let glowRadius: Float = 8.0
        static let backgroundAlpha: CGFloat = 0.15
        static let glowAlpha: CGFloat = 0.8
        static let inactiveAlpha: CGFloat = 0.2
        static let animationDuration: TimeInterval = 0.2
        static let fontSize: CGFloat = 24
        static let padding: CGFloat = 10
    }
    
    // MARK: - Properties
    private let containerSize: CGSize
    private let container: SKShapeNode
    private let glowContainer: SKEffectNode
    private let noteLabel: SKLabelNode
    
    var currentNote: String = "-" {
        didSet {
            updateDisplay()
        }
    }
    
    var isActive: Bool = false {
        didSet {
            updateDisplay()
        }
    }
    
    // MARK: - Initialization
    init(size: CGSize) {
        self.containerSize = size
        
        // Inicializar contenedor
        container = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        glowContainer = SKEffectNode()
        
        // Inicializar etiqueta
        noteLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        noteLabel.fontSize = Layout.fontSize
        noteLabel.verticalAlignmentMode = .center
        
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
        glowContainer.filter = CIFilter(name: "CIGaussianBlur",
                                      parameters: ["inputRadius": Layout.glowRadius])
        glowContainer.shouldRasterize = true
        addChild(glowContainer)
        
        // Configurar etiqueta
        noteLabel.position = CGPoint(x: 0, y: 0)
        container.addChild(noteLabel)
    }
    
    // MARK: - Updates
    private func updateDisplay() {
        // Actualizar texto
        noteLabel.text = currentNote
        
        // Actualizar colores según estado
        if isActive {
            noteLabel.fontColor = .black
            container.alpha = Layout.backgroundAlpha
            glowContainer.alpha = Layout.glowAlpha
        } else {
            noteLabel.fontColor = .gray
            container.alpha = Layout.backgroundAlpha * 0.5
            glowContainer.alpha = Layout.inactiveAlpha
        }
        
        // Animar cambio
        animateUpdate()
    }
    
    private func animateUpdate() {
        let scaleUp = SKAction.scale(to: 1.1, duration: Layout.animationDuration / 2)
        let scaleDown = SKAction.scale(to: 1.0, duration: Layout.animationDuration / 2)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        
        noteLabel.run(sequence)
    }
}
