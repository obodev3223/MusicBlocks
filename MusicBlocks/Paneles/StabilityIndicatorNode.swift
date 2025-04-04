//
//  StabilityIndicatorNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.

import SpriteKit

class StabilityIndicatorNode: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let barWidthRatio: CGFloat = 0.8
        static let markingWidthRatio: CGFloat = 0.6
        static let backgroundAlpha: CGFloat = 0.15
        static let markingsAlpha: CGFloat = 0.3
        static let glowAlpha: CGFloat = 0.8
        static let cornerRadius: CGFloat = 4
        static let animationDuration: TimeInterval = 0.2
    }
    
    // MARK: - Properties
    var containerSize: CGSize {
        didSet {
            updateLayout()
        }
    }
    
    private let backgroundBar: SKShapeNode = SKShapeNode()
    private var markings: [SKShapeNode] = []
    private let glowBar: SKShapeNode = SKShapeNode()
    private var maxDuration: TimeInterval = 10.0
    
    var duration: TimeInterval = 0 {
        didSet {
            updateProgress()
        }
    }
    
    // MARK: - Initialization
    init(size: CGSize) {
        self.containerSize = size
        
        // Creación de tres marcas (por ejemplo, para 0, 5 y 10)
        for _ in 0..<3 {
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
        // Configurar la barra de fondo
        backgroundBar.fillColor = .lightGray
        backgroundBar.strokeColor = .clear
        backgroundBar.alpha = Layout.backgroundAlpha
        addChild(backgroundBar)
        
        // Configurar las marcas
        for mark in markings {
            mark.fillColor = .darkGray
            mark.strokeColor = .clear
            mark.alpha = Layout.markingsAlpha
            addChild(mark)
        }
        
        // Agregar glowBar (que se usará para mostrar el progreso)
        addChild(glowBar)
    }
    
    // MARK: - Layout Update
    private func updateLayout() {
        let barWidth = containerSize.width * Layout.barWidthRatio
        let barHeight = containerSize.height
        
        // Actualizar el fondo de la barra - asegurándonos que ocupe todo el espacio disponible
        let bgRect = CGRect(x: -barWidth/2, y: -barHeight/2, width: barWidth, height: barHeight)
        backgroundBar.path = CGPath(roundedRect: bgRect, cornerWidth: Layout.cornerRadius, cornerHeight: Layout.cornerRadius, transform: nil)
        
        // Actualizar la posición y tamaño de cada marca - espaciadas uniformemente
        for (index, mark) in markings.enumerated() {
            let progress = CGFloat(index) / CGFloat(markings.count - 1)
            let yPosition = -containerSize.height * 0.5 + containerSize.height * progress
            
            // CORREGIDO: Ajustar posición para alinearse mejor con la barra
            mark.position = CGPoint(x: 0, y: yPosition)
            
            // Ancho de marca consistente
            let markWidth = barWidth * Layout.markingWidthRatio
            let markHeight: CGFloat = 2.0  // Altura fija para que sea visible
            let markRect = CGRect(x: -markWidth/2, y: -markHeight/2, width: markWidth, height: markHeight)
            mark.path = CGPath(rect: markRect, transform: nil)
        }
        
        updateProgress()
    }

    // MARK: - Updates
    private func updateProgress() {
        let normalizedProgress = CGFloat(min(duration, maxDuration) / maxDuration)
        let progressHeight = containerSize.height * normalizedProgress
        let progressWidth = containerSize.width * Layout.barWidthRatio
        
        // La posición del rectángulo debe partir desde abajo
        let rect = CGRect(x: -progressWidth / 2,
                          y: -containerSize.height / 2,  // Siempre partimos desde abajo
                          width: progressWidth,
                          height: progressHeight)
        
        let path = CGMutablePath()
        if progressHeight > Layout.cornerRadius * 2 {
            path.addRoundedRect(in: rect, cornerWidth: Layout.cornerRadius, cornerHeight: Layout.cornerRadius)
        } else {
            path.addRect(rect)
        }
        
        // Actualización inmediata para mejor rendimiento
        glowBar.path = path
        glowBar.fillColor = getProgressColor()
        glowBar.alpha = normalizedProgress * Layout.glowAlpha
    }
    
    private func getProgressColor() -> SKColor {
        return UIColor(red: 0, green: 0.4, blue: 0.9, alpha: 1.0)
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

// MARK: - Previews
extension StabilityIndicatorNode {
    static func createPreviewScene() -> SKScene {
        let scene = SKScene(size: CGSize(width: 300, height: 200))
        scene.backgroundColor = .white
        
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

struct StabilityIndicatorPreview: PreviewProvider {
    static var previews: some View {
        SpriteView(scene: StabilityIndicatorNode.createPreviewScene())
            .frame(width: 300, height: 200)
            .previewLayout(.fixed(width: 300, height: 200))
    }
}

#endif
