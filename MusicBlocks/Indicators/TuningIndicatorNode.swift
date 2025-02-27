//
//  TuningIndicatorNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit

// Extensión para limitar valores numéricos
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

class TuningIndicatorNode: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let barWidthRatio: CGFloat = 0.8
        static let markingWidthRatio: CGFloat = 0.6
        static let indicatorSizeRatio: CGFloat = 0.15
        static let glowRadius: Float = 15.0
        static let backgroundAlpha: CGFloat = 0.15
        static let markingsAlpha: CGFloat = 0.3
        static let glowAlpha: CGFloat = 0.8
        static let inactiveAlpha: CGFloat = 0.2
        static let animationDuration: TimeInterval = 0.2
    }
    
    // MARK: - Properties
    private let containerSize: CGSize
    private let backgroundBar: SKShapeNode
    private let markings: [SKShapeNode]
    private let indicatorContainer: SKNode
    private let indicatorGlow: SKEffectNode
    private let indicatorCore: SKShapeNode
    
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
        
        // Calcular dimensiones
        let barWidth = size.width * Layout.barWidthRatio
        let barHeight = size.height
        
        // Inicializar nodos
        backgroundBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight))
        indicatorContainer = SKNode()
        indicatorGlow = SKEffectNode()
        indicatorCore = SKShapeNode(circleOfRadius: size.width * Layout.indicatorSizeRatio)
        
        // Inicializar marcas
        var marks: [SKShapeNode] = []
        let markValues = [-25, -10, 0, 10, 25]
        
        for cents in markValues {
            let mark = SKShapeNode(rectOf: CGSize(
                width: cents == 0 ? barWidth * 0.8 : barWidth * Layout.markingWidthRatio,
                height: 1
            ))
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
        // Configurar barra de fondo
        backgroundBar.fillColor = .white
        backgroundBar.strokeColor = .clear
        backgroundBar.alpha = Layout.backgroundAlpha
        addChild(backgroundBar)
        
        // Configurar marcas
        for (index, mark) in markings.enumerated() {
            let progress = CGFloat(index) / CGFloat(markings.count - 1)
            let yPosition = -containerSize.height/2 + containerSize.height * progress
            mark.position = CGPoint(x: 0, y: yPosition)
            mark.fillColor = .white
            mark.strokeColor = .clear
            mark.alpha = Layout.markingsAlpha
            addChild(mark)
        }
        
        // Configurar indicador
        addChild(indicatorContainer)
        indicatorContainer.addChild(indicatorGlow)
        
        // Configurar glow
        indicatorGlow.shouldRasterize = true
        indicatorGlow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": Layout.glowRadius])
        
        // Configurar núcleo del indicador
        indicatorCore.fillColor = .white
        indicatorCore.strokeColor = .clear
        indicatorGlow.addChild(indicatorCore)
        
        updateIndicator()
    }
    
    // MARK: - Updates
    private func updateIndicator() {
        // Calcular posición
        let normalizedDeviation = CGFloat((deviation + 25) / 50).clamped(to: 0...1)
        let indicatorRadius = containerSize.width * Layout.indicatorSizeRatio
        let effectiveHeight = containerSize.height - (indicatorRadius * 2)
        let minY = -containerSize.height/2 + indicatorRadius
        let yPosition = minY + (effectiveHeight * normalizedDeviation)
        
        // Animar movimiento
        let moveAction = SKAction.move(to: CGPoint(x: 0, y: yPosition), duration: Layout.animationDuration)
        moveAction.timingMode = SKActionTimingMode.easeOut
        indicatorContainer.run(moveAction)
        
        // Actualizar color y glow
        let color = getDeviationColor()
        indicatorCore.fillColor = color
        indicatorGlow.alpha = isActive ? Layout.glowAlpha : Layout.inactiveAlpha
    }
    
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

// Al final de TuningIndicatorNode.swift

#if DEBUG
import SwiftUI

// MARK: - Previews
extension TuningIndicatorNode {
    static func createPreviewScene() -> SKScene {
        let scene = SKScene(size: CGSize(width: 300, height: 200))
        scene.backgroundColor = .clear
        
        let states: [(deviation: Double, isActive: Bool, position: CGPoint)] = [
            (0, true, CGPoint(x: 75, y: 100)),     // Perfecta afinación
            (12, true, CGPoint(x: 150, y: 100)),   // Desviación leve
            (-20, true, CGPoint(x: 225, y: 100)),  // Desviación grande
        ]
        
        for state in states {
            let node = TuningIndicatorNode(size: CGSize(width: 40, height: 120))
            node.position = state.position
            node.deviation = state.deviation
            node.isActive = state.isActive
            scene.addChild(node)
        }
        
        return scene
    }
}

struct TuningIndicatorPreview: PreviewProvider {
    static var previews: some View {
        SpriteViewPreview {
            TuningIndicatorNode.createPreviewScene()
        }
        .frame(width: 300, height: 200)
        .previewLayout(.fixed(width: 300, height: 200))
    }
}
#endif
