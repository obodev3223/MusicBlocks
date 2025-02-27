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
        static let primaryFontRatio: CGFloat = 0.25  // Aumentado para mejor visibilidad
        static let secondaryFontRatio: CGFloat = 0.18
        static let cornerRadius: CGFloat = 8
        static let backgroundAlpha: CGFloat = 0.95
        static let animationDuration: TimeInterval = 0.2
        static let shadowRadius: CGFloat = 4.0
        static let shadowOpacity: Float = 0.2
        static let shadowOffset = CGPoint(x: 0, y: -1)
    }
    
    // MARK: - Properties
    private let containerSize: CGSize
    private let container: SKShapeNode
    private let shadowNode: SKEffectNode
    private let timeLabel: SKLabelNode
    private let unitLabel: SKLabelNode
    
    var duration: TimeInterval = 0 {
        didSet {
            updateDisplay()
        }
    }
    
    // MARK: - Initialization
    init(size: CGSize) {
        self.containerSize = size
        
        // Crear nodo de sombra
        shadowNode = SKEffectNode()
        let shadowShape = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        shadowShape.fillColor = .black
        shadowShape.strokeColor = .clear
        shadowShape.alpha = CGFloat(Layout.shadowOpacity)
        shadowNode.addChild(shadowShape)
        shadowNode.shouldRasterize = true
        shadowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": Layout.shadowRadius])
        shadowNode.position = Layout.shadowOffset
        
        // Inicializar contenedor principal
        container = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        
        // Inicializar etiquetas con tamaños proporcionados
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
        fatalError("init(coder:) has not sido implementado")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        // Añadir sombra primero
        addChild(shadowNode)
        
        // Configurar contenedor principal
        container.fillColor = .white
        container.strokeColor = .clear
        container.alpha = Layout.backgroundAlpha
        addChild(container)
        
        // Posicionar etiquetas
        timeLabel.position = CGPoint(x: -containerSize.width * 0.2, y: 0)  // Ajuste más dinámico
        unitLabel.position = CGPoint(x: containerSize.width * 0.2, y: 0)   // Ajuste más dinámico
        
        // Añadir etiquetas al nodo principal
        addChild(timeLabel)
        addChild(unitLabel)
    }
    
    // MARK: - Updates
    private func updateDisplay() {
        timeLabel.text = String(format: "%.1f", duration)
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
    }
}

// MARK: - Previews
#if DEBUG
import SwiftUI

struct StabilityCounterPreview: PreviewProvider {
    static var previews: some View {
        SpriteView(scene: {
            let scene = SKScene(size: CGSize(width: 300, height: 200))
            scene.backgroundColor = .white
            
            let mediumNode = StabilityCounterNode(size: CGSize(width: 120, height: 60))
            mediumNode.position = CGPoint(x: 150, y: 120)
            mediumNode.duration = 5.5
            scene.addChild(mediumNode)
            
            let maxNode = StabilityCounterNode(size: CGSize(width: 120, height: 60))
            maxNode.position = CGPoint(x: 150, y: 60)
            maxNode.duration = 10.0
            scene.addChild(maxNode)
            
            return scene
        }())
        .frame(width: 300, height: 200)
        .previewLayout(.fixed(width: 300, height: 200))
    }
}
#endif
