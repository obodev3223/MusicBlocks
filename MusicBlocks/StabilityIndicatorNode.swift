//
//  StabilityIndicatorNode.swift
//  FrikiTuner
//
//  Created by Jose R. García on 13/2/25.
//

import SpriteKit

class StabilityIndicatorNode: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let barWidthRatio: CGFloat = 0.8
        static let markingWidthRatio: CGFloat = 0.6
        static let progressWidthRatio: CGFloat = 0.6
        static let markingHeightRatio: CGFloat = 0.005 // 0.5% de la altura
        static let cornerRadius: CGFloat = 4
    }
    
    // MARK: - Properties
    private let containerSize: CGSize
    private let backgroundBar: SKShapeNode
    private let progressBar: SKShapeNode
    private let markings: [SKShapeNode]
    private var maxDuration: TimeInterval = 10.0
    
    var duration: TimeInterval = 0 {
        didSet {
            updateProgress()
        }
    }
    
    // MARK: - Initialization
    init(size: CGSize) {
        self.containerSize = size
        
        // Calcular dimensiones basadas en el contenedor
        let barWidth = size.width * Layout.barWidthRatio
        let barHeight = size.height
        
        // Inicializar barra de fondo
        backgroundBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight),
                                    cornerRadius: Layout.cornerRadius)
        backgroundBar.fillColor = .white
        backgroundBar.strokeColor = .gray
        backgroundBar.alpha = 0.3
        
        // Inicializar barra de progreso
        progressBar = SKShapeNode()
        progressBar.fillColor = .blue
        progressBar.strokeColor = .clear
        
        // Inicializar marcas de tiempo
        var marks: [SKShapeNode] = []
        let timeMarks = [0, 5, 10] // Segundos
        
        for _ in timeMarks {
            let mark = SKShapeNode(rectOf: CGSize(
                width: barWidth * Layout.markingWidthRatio,
                height: size.height * Layout.markingHeightRatio
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
        // Añadir barra de fondo
        addChild(backgroundBar)
        
        // Añadir barra de progreso
        addChild(progressBar)
        
        // Configurar y añadir marcas de tiempo
        for (index, mark) in markings.enumerated() {
            let yPosition = CGFloat(index) * (containerSize.height / CGFloat(markings.count - 1))
            mark.position = CGPoint(x: 0, y: -containerSize.height/2 + yPosition)
            addChild(mark)
        }
        
        // Inicializar progreso
        updateProgress()
    }
    
    // MARK: - Updates
    private func updateProgress() {
        let normalizedProgress = CGFloat(min(duration, maxDuration) / maxDuration)
        let progressHeight = containerSize.height * normalizedProgress
        
        // Crear el path para la barra de progreso
        let progressWidth = containerSize.width * Layout.progressWidthRatio
        let rect = CGRect(x: -progressWidth/2,
                          y: -containerSize.height/2, // Origen en la parte inferior
                          width: progressWidth,
                          height: progressHeight)
        
        // Crear path con esquinas redondeadas
        let path = CGMutablePath()
        let cornerRadius = Layout.cornerRadius
        
        if progressHeight > cornerRadius * 2 {
            // Añadir esquinas redondeadas solo si hay suficiente altura
            path.addRoundedRect(in: rect,
                                cornerWidth: cornerRadius,
                                cornerHeight: cornerRadius)
        } else {
            // Si es muy pequeña, usar un rectángulo simple
            path.addRect(rect)
        }
        
        progressBar.path = path
        
        // Actualizar color según duración
        progressBar.fillColor = getProgressColor()
    }
    
    // MARK: - Helper Methods
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
