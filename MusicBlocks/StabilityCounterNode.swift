//
//  StabilityCounterNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 13/2/25.
//

import SpriteKit

class StabilityCounterNode: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let primaryFontRatio: CGFloat = 0.15
        static let secondaryFontRatio: CGFloat = 0.10
        static let verticalSpacingRatio: CGFloat = 0.05
        static let animationDuration: TimeInterval = 0.2
    }
    
    // MARK: - Properties
    private let containerSize: CGSize
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
        
        // Inicializar etiqueta de tiempo
        timeLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        timeLabel.fontSize = size.height * Layout.primaryFontRatio
        timeLabel.verticalAlignmentMode = .center
        timeLabel.fontColor = .black
        
        // Inicializar etiqueta de unidad
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
        // Añadir etiquetas al nodo
        addChild(timeLabel)
        addChild(unitLabel)
        
        // Posicionar etiquetas verticalmente
        let spacing = containerSize.height * Layout.verticalSpacingRatio
        timeLabel.position = CGPoint(x: 0, y: spacing)
        unitLabel.position = CGPoint(x: 0, y: -spacing)
    }
    
    // MARK: - Updates
    private func updateDisplay() {
        // Formatear el tiempo con un decimal
        timeLabel.text = String(format: "%.1f", duration)
        
        // Animar la actualización
        animateUpdate()
    }
    
    private func animateUpdate() {
        // Crear secuencia de animación
        let scaleUp = SKAction.scale(to: 1.1, duration: Layout.animationDuration / 2)
        let scaleDown = SKAction.scale(to: 1.0, duration: Layout.animationDuration / 2)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        
        // Aplicar animación solo a la etiqueta de tiempo
        timeLabel.run(sequence)
    }
    
    // MARK: - Public Methods
    func setFontSizes(timeSize: CGFloat, unitSize: CGFloat) {
        timeLabel.fontSize = timeSize
        unitLabel.fontSize = unitSize
    }
    
    func setColors(timeColor: SKColor, unitColor: SKColor) {
        timeLabel.fontColor = timeColor
        unitLabel.fontColor = unitColor
    }
    
    func reset() {
        duration = 0
    }
}
