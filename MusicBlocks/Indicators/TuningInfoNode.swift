//
//  TuningInfoNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 13/2/25.
//

import SpriteKit

class TuningInfoNode: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let primaryFontRatio: CGFloat = 0.15
        static let secondaryFontRatio: CGFloat = 0.10
        static let verticalSpacingRatio: CGFloat = 0.05
        static let inactiveAlpha: CGFloat = 0.5
    }
    
    // MARK: - Properties
    private let containerSize: CGSize
    private let frequencyLabel: SKLabelNode
    private let frequencyUnitLabel: SKLabelNode
    private let deviationLabel: SKLabelNode
    private let deviationUnitLabel: SKLabelNode
    
    var frequency: Float = 0 {
        didSet {
            updateDisplay()
        }
    }
    
    var deviation: Double = 0 {
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
        
        // Inicializar etiquetas con tamaños relativos
        frequencyLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        frequencyLabel.fontSize = size.height * Layout.primaryFontRatio
        frequencyLabel.verticalAlignmentMode = .center
        
        frequencyUnitLabel = SKLabelNode(fontNamed: "Helvetica")
        frequencyUnitLabel.fontSize = size.height * Layout.secondaryFontRatio
        frequencyUnitLabel.text = "Hz"
        frequencyUnitLabel.verticalAlignmentMode = .center
        
        deviationLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        deviationLabel.fontSize = size.height * Layout.primaryFontRatio
        deviationLabel.verticalAlignmentMode = .center
        
        deviationUnitLabel = SKLabelNode(fontNamed: "Helvetica")
        deviationUnitLabel.fontSize = size.height * Layout.secondaryFontRatio
        deviationUnitLabel.text = "cents"
        deviationUnitLabel.verticalAlignmentMode = .center
        
        super.init()
        
        setupNodes()
        updateDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        // Añadir todas las etiquetas
        addChild(frequencyLabel)
        addChild(frequencyUnitLabel)
        addChild(deviationLabel)
        addChild(deviationUnitLabel)
        
        // Posicionar etiquetas verticalmente usando proporciones fijas
        frequencyLabel.position = CGPoint(x: 0, y: containerSize.height * 0.25)
        frequencyUnitLabel.position = CGPoint(x: 0, y: containerSize.height * 0.1)
        deviationLabel.position = CGPoint(x: 0, y: -containerSize.height * 0.1)
        deviationUnitLabel.position = CGPoint(x: 0, y: -containerSize.height * 0.25)
    }
    
    // MARK: - Updates
    private func updateDisplay() {
        // Configurar color base según estado activo
        let baseColor: SKColor = isActive ? .black : .gray
        let secondaryColor = baseColor.withAlphaComponent(Layout.inactiveAlpha)
        
        // Actualizar etiqueta de frecuencia
        frequencyLabel.text = String(format: "%.1f", frequency)
        frequencyLabel.fontColor = baseColor
        frequencyUnitLabel.fontColor = secondaryColor
        
        // Actualizar etiqueta de desviación
        deviationLabel.text = String(format: "%+.0f", deviation)
        deviationLabel.fontColor = getDeviationColor()
        deviationUnitLabel.fontColor = secondaryColor
        
        // Animar cambios
        animateUpdate()
    }
    
    // MARK: - Helper Methods
    private func getDeviationColor() -> SKColor {
        guard isActive else {
            return .gray
        }
        
        let absDeviation = abs(deviation)
        if absDeviation < 5 {
            return .green
        } else if absDeviation < 15 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func animateUpdate() {
        // Escala suave al actualizar
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        
        // Aplicar animación a las etiquetas que cambian
        frequencyLabel.run(sequence)
        deviationLabel.run(sequence)
    }
    
    // MARK: - Public Methods
    func setFontSize(primarySize: CGFloat, secondarySize: CGFloat) {
        frequencyLabel.fontSize = primarySize
        deviationLabel.fontSize = primarySize
        frequencyUnitLabel.fontSize = secondarySize
        deviationUnitLabel.fontSize = secondarySize
    }
    
    func updateColors(primary: SKColor, secondary: SKColor) {
        frequencyLabel.fontColor = primary
        deviationLabel.fontColor = primary
        frequencyUnitLabel.fontColor = secondary
        deviationUnitLabel.fontColor = secondary
    }
}
