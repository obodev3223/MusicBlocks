//
//  TuningCounterNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit

class TuningCounterNode: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let primaryFontRatio: CGFloat = 0.15
        static let secondaryFontRatio: CGFloat = 0.10
        static let verticalSpacingRatio: CGFloat = 0.05
        static let inactiveAlpha: CGFloat = 0.5
        static let cornerRadius: CGFloat = 8
        static let containerPadding: CGFloat = 10
        static let backgroundAlpha: CGFloat = 0.15
        static let glowRadius: Float = 8.0
    }
    
    // MARK: - Properties
    private let containerSize: CGSize
    private let frequencyContainer: SKShapeNode
    private let deviationContainer: SKShapeNode
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
        
        // Calcular tamaños de los contenedores
        let boxHeight = (size.height - Layout.containerPadding) / 2
        let boxSize = CGSize(width: size.width, height: boxHeight)
        
        // Inicializar contenedores
        frequencyContainer = SKShapeNode(rectOf: boxSize, cornerRadius: Layout.cornerRadius)
        deviationContainer = SKShapeNode(rectOf: boxSize, cornerRadius: Layout.cornerRadius)
        
        // Inicializar etiquetas
        frequencyLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        frequencyLabel.fontSize = boxHeight * Layout.primaryFontRatio
        frequencyLabel.verticalAlignmentMode = .center
        
        frequencyUnitLabel = SKLabelNode(fontNamed: "Helvetica")
        frequencyUnitLabel.fontSize = boxHeight * Layout.secondaryFontRatio
        frequencyUnitLabel.text = "Hz"
        frequencyUnitLabel.verticalAlignmentMode = .center
        
        deviationLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        deviationLabel.fontSize = boxHeight * Layout.primaryFontRatio
        deviationLabel.verticalAlignmentMode = .center
        
        deviationUnitLabel = SKLabelNode(fontNamed: "Helvetica")
        deviationUnitLabel.fontSize = boxHeight * Layout.secondaryFontRatio
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
        // Configurar contenedores
        frequencyContainer.fillColor = .white
        frequencyContainer.strokeColor = .clear
        frequencyContainer.alpha = Layout.backgroundAlpha
        frequencyContainer.position = CGPoint(x: 0, y: containerSize.height/4)
        
        deviationContainer.fillColor = .white
        deviationContainer.strokeColor = .clear
        deviationContainer.alpha = Layout.backgroundAlpha
        deviationContainer.position = CGPoint(x: 0, y: -containerSize.height/4)
        
        // Añadir contenedores
        addChild(frequencyContainer)
        addChild(deviationContainer)
        
        // Posicionar etiquetas dentro de los contenedores
        frequencyLabel.position = CGPoint(x: -20, y: 0)
        frequencyUnitLabel.position = CGPoint(x: 30, y: 0)
        frequencyContainer.addChild(frequencyLabel)
        frequencyContainer.addChild(frequencyUnitLabel)
        
        deviationLabel.position = CGPoint(x: -20, y: 0)
        deviationUnitLabel.position = CGPoint(x: 30, y: 0)
        deviationContainer.addChild(deviationLabel)
        deviationContainer.addChild(deviationUnitLabel)
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
    
    private func getDeviationColor() -> SKColor {
        guard isActive else { return .gray }
        
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
        let scaleUp = SKAction.scale(to: 1.05, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        
        frequencyLabel.run(sequence)
        deviationLabel.run(sequence)
    }
}
