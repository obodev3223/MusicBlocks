//
//  TuningIndicatorNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

//
//  TuningIndicatorNode.swift
//  MusicBlocks
//
//  Creado por Jose R. García el 25/2/25.
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
        static let indicatorSizeRatio: CGFloat = 0.15  // Relativo al ancho de la barra
        static let backgroundAlpha: CGFloat = 0.15
        static let markingsAlpha: CGFloat = 0.3
        static let glowAlpha: CGFloat = 0.8  // Opacidad cuando está activo
        static let inactiveAlpha: CGFloat = 0.2
        static let animationDuration: TimeInterval = 0.2
        static let glowRadius: Float = 15.0
        static let glowLineWidth: CGFloat = 8.0  // Grosor del contorno glow
    }
    
    // MARK: - Properties
    var containerSize: CGSize {
        didSet {
            updateLayout()
        }
    }
    
    private let backgroundBar: SKShapeNode = SKShapeNode()
    private var markings: [SKShapeNode] = []
    
    // Indicador central
    private let indicatorContainer: SKNode = SKNode()
    private let indicatorCore: SKShapeNode = SKShapeNode()
    
    // Glow de la barra (se muestra como contorno)
    private let barGlow: SKEffectNode = SKEffectNode()
    private let barGlowShape: SKShapeNode = SKShapeNode()
    
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
        
        // Crear marcas basadas en valores fijos [-25, -10, 0, 10, 25]
        let markValues = [-25, -10, 0, 10, 25]
        for _ in markValues {
            let mark = SKShapeNode()
            markings.append(mark)
        }
        
        super.init()
        
        setupNodes()
        updateLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) no ha sido implementado")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        // Configurar glow de la barra
        barGlow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": Layout.glowRadius])
        barGlow.shouldRasterize = true
        barGlow.addChild(barGlowShape)
        barGlow.zPosition = -1
        addChild(barGlow)
        
        // Configurar la barra de fondo
        backgroundBar.fillColor = UIColor.lightGray
        backgroundBar.strokeColor = .clear
        backgroundBar.alpha = Layout.backgroundAlpha
        addChild(backgroundBar)
        
        // Configurar marcas
        for (index, mark) in markings.enumerated() {
            mark.fillColor = UIColor.darkGray
            mark.strokeColor = .clear
            mark.alpha = Layout.markingsAlpha
            addChild(mark)
        }
        
        // Configurar indicador central
        addChild(indicatorContainer)
        
        // Creamos la forma para el indicador (círculo)
        let barWidth = containerSize.width * Layout.barWidthRatio
        let indicatorRadius = barWidth * Layout.indicatorSizeRatio
        indicatorCore.path = CGPath(ellipseIn: CGRect(x: -indicatorRadius, y: -indicatorRadius,
                                                    width: indicatorRadius*2, height: indicatorRadius*2), transform: nil)
        indicatorCore.strokeColor = .clear
        indicatorContainer.addChild(indicatorCore)
        
        updateIndicator()
    }
    
    // MARK: - Layout Update
    private func updateLayout() {
        let barWidth = containerSize.width * Layout.barWidthRatio
        let barHeight = containerSize.height
        
        let bgRect = CGRect(x: -barWidth/2, y: -barHeight/2, width: barWidth, height: barHeight)
        backgroundBar.path = CGPath(rect: bgRect, transform: nil)
        
        barGlowShape.path = CGPath(rect: bgRect, transform: nil)
        barGlowShape.lineWidth = Layout.glowLineWidth
        
        // Actualizar marcas
        for (index, mark) in markings.enumerated() {
            let progress = CGFloat(index) / CGFloat(markings.count - 1)
            let yPosition = -containerSize.height / 2 + containerSize.height * progress
            mark.position = CGPoint(x: 0, y: yPosition)
            let markWidth: CGFloat
            // Se define una marca central más ancha (por ejemplo, índice 2)
            if index == 2 {
                markWidth = barWidth * 0.8
            } else {
                markWidth = barWidth * Layout.markingWidthRatio
            }
            let markRect = CGRect(x: -markWidth/2, y: -0.5, width: markWidth, height: 1)
            mark.path = CGPath(rect: markRect, transform: nil)
        }
        
        updateIndicator()
    }
    
    // MARK: - Updates
    private func updateIndicator() {
        let normalizedDeviation = CGFloat((deviation + 25) / 50).clamped(to: 0...1)
        let barWidth = containerSize.width * Layout.barWidthRatio
        let indicatorRadius = barWidth * Layout.indicatorSizeRatio
        let effectiveHeight = containerSize.height - (indicatorRadius * 2)
        let minY = -containerSize.height / 2 + indicatorRadius
        let yPosition = minY + (effectiveHeight * normalizedDeviation)
        
        // Asegúrate de que el indicador tenga una forma definida
        if indicatorCore.path == nil {
            indicatorCore.path = CGPath(ellipseIn: CGRect(x: -indicatorRadius, y: -indicatorRadius,
                                                       width: indicatorRadius*2, height: indicatorRadius*2), transform: nil)
        }
        
        let moveAction = SKAction.move(to: CGPoint(x: 0, y: yPosition), duration: Layout.animationDuration)
        moveAction.timingMode = .easeOut
        indicatorContainer.run(moveAction)
        
        let color = getDeviationColor()
        indicatorCore.fillColor = color
        indicatorCore.alpha = isActive ? Layout.glowAlpha : Layout.inactiveAlpha
        
        barGlowShape.strokeColor = color
        barGlowShape.fillColor = .clear
        barGlowShape.alpha = isActive ? Layout.glowAlpha : Layout.inactiveAlpha
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


#if DEBUG
import SwiftUI

// MARK: - Previews
extension TuningIndicatorNode {
    static func createPreviewScene() -> SKScene {
        let scene = SKScene(size: CGSize(width: 300, height: 200))
        scene.backgroundColor = .white
        
        let states: [(deviation: Double, isActive: Bool, position: CGPoint)] = [
            (0, true, CGPoint(x: 75, y: 100)),     // Perfecta afinación
            (12, true, CGPoint(x: 150, y: 100)),   // Desviación leve
            (-20, true, CGPoint(x: 225, y: 100))   // Desviación grande
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
        SpriteView(scene: TuningIndicatorNode.createPreviewScene())
            .frame(width: 300, height: 200)
            .previewLayout(.fixed(width: 300, height: 200))
    }
}

#endif
