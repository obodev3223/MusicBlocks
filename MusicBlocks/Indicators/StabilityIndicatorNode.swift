//
//  StabilityIndicatorNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit

class StabilityIndicatorNode: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let barWidthRatio: CGFloat = 0.8
        static let markingWidthRatio: CGFloat = 0.6
        static let glowRadius: Float = 15.0
        static let backgroundAlpha: CGFloat = 0.15
        static let markingsAlpha: CGFloat = 0.3
        static let glowAlpha: CGFloat = 0.8
        static let cornerRadius: CGFloat = 4
        static let animationDuration: TimeInterval = 0.2
    }
    
    // MARK: - Properties
    private let containerSize: CGSize
    private let backgroundBar: SKShapeNode
    private let markings: [SKShapeNode]
    private let glowContainer: SKEffectNode
    private let glowBar: SKShapeNode
    private var maxDuration: TimeInterval = 10.0
    
    var duration: TimeInterval = 0 {
        didSet {
            updateProgress()
        }
    }
    
    // MARK: - Initialization
    init(size: CGSize) {
        self.containerSize = size
        
        // Calcular dimensiones
        let barWidth = size.width * Layout.barWidthRatio
        let barHeight = size.height
        
        // Inicializar nodos
        backgroundBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight),
                                  cornerRadius: Layout.cornerRadius)
        glowContainer = SKEffectNode()
        glowBar = SKShapeNode()
        
        // Inicializar marcas
        var marks: [SKShapeNode] = []
        let timeMarks = [0, 5, 10]
        
        for _ in timeMarks {
            let mark = SKShapeNode(rectOf: CGSize(
                width: barWidth * Layout.markingWidthRatio,
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
        
        // Configurar glow
        addChild(glowContainer)
        glowContainer.addChild(glowBar)
        glowContainer.shouldRasterize = true
        glowContainer.filter = CIFilter(name: "CIGaussianBlur",
                                      parameters: ["inputRadius": Layout.glowRadius])
        
        updateProgress()
    }
    
    // MARK: - Updates
    private func updateProgress() {
        let normalizedProgress = CGFloat(min(duration, maxDuration) / maxDuration)
        let progressHeight = containerSize.height * normalizedProgress
        
        let progressWidth = containerSize.width * Layout.barWidthRatio
        let rect = CGRect(x: -progressWidth/2,
                         y: -containerSize.height/2,
                         width: progressWidth,
                         height: progressHeight)
        
        let path = CGMutablePath()
        let cornerRadius = Layout.cornerRadius
        
        if progressHeight > cornerRadius * 2 {
            path.addRoundedRect(in: rect,
                              cornerWidth: cornerRadius,
                              cornerHeight: cornerRadius)
        } else {
            path.addRect(rect)
        }
        
        // Animar cambio de path
        let action = SKAction.run { [weak self] in
            self?.glowBar.path = path
            self?.glowBar.fillColor = self?.getProgressColor() ?? .blue
        }
        glowBar.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            action
        ]))
        
        // Actualizar alpha del glow
        glowContainer.alpha = normalizedProgress * Layout.glowAlpha
    }
    
    private func getProgressColor() -> SKColor {
        let progress = duration / maxDuration
        
        if progress >= 1.0 {
            return .green
        } else if progress >= 0.5 {
            return .orange
        } else {
            return .blue
        }
    }
    
    // MARK: - Public Methods
    func reset() {
        duration = 0
        updateProgress()
    }
    
    func setMaxDuration(_ maxDuration: TimeInterval) {
        self.maxDuration = maxDuration
        updateProgress()
    }
}

#if DEBUG
import SwiftUI

struct StabilityIndicatorPreview: PreviewProvider {
    static var previews: some View {
        // Contenedor para visualizar el nodo
        ZStack {
            Color.gray.opacity(0.3) // Fondo para mejor visualización
            
            StabilityIndicatorPreviewView()
        }
        .frame(width: 300, height: 200)
        .previewLayout(.fixed(width: 300, height: 200))
    }
}

// Vista auxiliar para manejar la preview
private struct StabilityIndicatorPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        let scene = SKScene(size: CGSize(width: 300, height: 200))
        scene.backgroundColor = .clear
        
        // Crear y configurar el nodo de prueba
        let indicatorNode = StabilityIndicatorNode(size: CGSize(width: 40, height: 120))
        indicatorNode.position = CGPoint(x: 150, y: 100)
        indicatorNode.duration = 7.5 // Valor de prueba
        
        scene.addChild(indicatorNode)
        view.presentScene(scene)
        
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {}
}

// Extensión para demostrar diferentes estados
extension StabilityIndicatorPreviewView {
    static func createPreviewScene() -> SKScene {
        let scene = SKScene(size: CGSize(width: 300, height: 200))
        scene.backgroundColor = .clear
        
        // Mostrar diferentes estados
        let states: [(duration: TimeInterval, position: CGPoint)] = [
            (0.0, CGPoint(x: 75, y: 100)),    // Vacío
            (5.0, CGPoint(x: 150, y: 100)),   // Medio
            (10.0, CGPoint(x: 225, y: 100))   // Lleno
        ]
        
        for state in states {
            let node = StabilityIndicatorNode(size: CGSize(width: 40, height: 120))
            node.position = state.position
            node.duration = state.duration
            scene.addChild(node)
        }
        
        return scene
    }
}
#endif
