//
//  TuningIndicatorNode.swift
//  FrikiTuner
//
//  Created by Jose R. García on 13/2/25.
//

import SpriteKit

class TuningIndicatorNode: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let barWidthRatio: CGFloat = 0.8
        static let markingWidthRatio: CGFloat = 0.6
        static let indicatorSizeRatio: CGFloat = 0.15
        static let glowRadius: Float = 10.0
        static let glowAlpha: CGFloat = 0.3
        static let inactiveAlpha: CGFloat = 0.1
        static let animationDuration: TimeInterval = 0.1
        static let indicatorPadding: CGFloat = 0.1
    }
    
    // MARK: - Properties
    private let containerSize: CGSize
    private let backgroundBar: SKShapeNode
    private let indicatorNode: SKShapeNode
    private let markings: [SKShapeNode]
    private let glowNode: SKEffectNode
    private let blurNode: SKShapeNode
    
    var deviation: Double = 0 {
        didSet {
            updateIndicator()
        }
    }
    
    var isActive: Bool = false {
        didSet {
            updateIndicator()
        }
    }
    
    // MARK: - Initialization
    init(size: CGSize) {
        self.containerSize = size
        
        // Calcular dimensiones basadas en el contenedor
        let barWidth = size.width * Layout.barWidthRatio
        let barHeight = size.height
        
        // Inicializar nodos
        glowNode = SKEffectNode()
        backgroundBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight))
        blurNode = SKShapeNode(rectOf: CGSize(width: barWidth + 10, height: barHeight + 10))
        indicatorNode = SKShapeNode(circleOfRadius: size.width * Layout.indicatorSizeRatio)
        
        // Inicializar marcas de centésimas
        var marks: [SKShapeNode] = []
        let markValues = [-25, -10, 0, 10, 25]
        
        for cents in markValues {
            let mark = SKShapeNode(rectOf: CGSize(
                width: cents == 0 ? barWidth * 0.8 : barWidth * Layout.markingWidthRatio,
                height: 2
            ))
            mark.fillColor = .gray
            mark.strokeColor = .clear
            marks.append(mark)
        }
        markings = marks
        
        super.init()
        
        setupNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        // Configurar efecto glow
        blurNode.fillColor = .white
        blurNode.strokeColor = .clear
        glowNode.addChild(blurNode)
        glowNode.shouldRasterize = true
        glowNode.shouldEnableEffects = true
        addChild(glowNode)
        
        // Configurar barra de fondo
        backgroundBar.fillColor = .white
        backgroundBar.strokeColor = .gray
        backgroundBar.alpha = 0.3
        addChild(backgroundBar)
        
        // Configurar marcas de centésimas
        for (index, mark) in markings.enumerated() {
            let progress = CGFloat(index) / CGFloat(markings.count - 1)
            let yPosition = -containerSize.height/2 + containerSize.height * progress
            mark.position = CGPoint(x: 0, y: yPosition)
            addChild(mark)
        }
        
        // Configurar indicador
        indicatorNode.fillColor = .green
        indicatorNode.strokeColor = .clear
        addChild(indicatorNode)
        
        updateIndicator()
    }
    
    // MARK: - Updates
    private func updateIndicator() {
           // Calcular posición vertical basada en la desviación con límites
           let normalizedDeviation = CGFloat((deviation + 25) / 50).clamped(to: 0...1)
           
           // Calcular el rango efectivo de movimiento considerando el tamaño del indicador
           let indicatorRadius = containerSize.width * Layout.indicatorSizeRatio
           let effectiveHeight = containerSize.height - (indicatorRadius * 2)
           let minY = -containerSize.height/2 + indicatorRadius
           let maxY = containerSize.height/2 - indicatorRadius
           
           // Calcular la posición final con límites
           let yPosition = minY + (effectiveHeight * normalizedDeviation)
           
           // Animar el movimiento del indicador
           let moveAction = SKAction.move(to: CGPoint(x: 0, y: yPosition),
                                        duration: Layout.animationDuration)
           moveAction.timingMode = .easeOut
           indicatorNode.run(moveAction)
           
           // Actualizar colores y efectos
           let color = getDeviationColor()
           indicatorNode.fillColor = color
           
           // Configurar el efecto glow
           glowNode.filter = CIFilter(name: "CIGaussianBlur",
                                    parameters: ["inputRadius": Layout.glowRadius])
           glowNode.alpha = isActive ? Layout.glowAlpha : Layout.inactiveAlpha
           
           // Actualizar el color del glow
           blurNode.fillColor = color
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
}

// Extensión para limitar valores numéricos
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
