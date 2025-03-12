//
//  ScoreProgressNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 12/3/25.

import SpriteKit

/// Nodo que combina una barra de progreso con indicadores de estrellas para mostrar el avance
/// del puntaje en el juego.
class ScoreProgressNode: SKNode {
    // MARK: - Private Properties
    private var progressBar: SKShapeNode
    private var progressFill: SKShapeNode
    private var stars: [SKSpriteNode] = []
    
    // MARK: - Layout Constants
    private enum Layout {
        static let maxStars: Int = 3
        static let starSize: CGFloat = 20
        static let starSpacing: CGFloat = 6
        static let barHeight: CGFloat = 8
        static let starVerticalOffset: CGFloat = 4 // Espacio entre la barra y las estrellas
        
        static let progressBarColor: SKColor = .systemGray5
        static let progressFillColor: SKColor = .systemPurple
        static let animationDuration: TimeInterval = 0.3
        
        static let starAnimationScale: CGFloat = 0.5
        static let starAnimationDuration: TimeInterval = 0.15
        static let starAnimationDelay: TimeInterval = 0.1
    }
    
    private let barWidth: CGFloat
    
    // MARK: - Initialization
    init(width: CGFloat) {
        self.barWidth = width
        
        // Inicializar las barras de progreso
        progressBar = SKShapeNode(rectOf: CGSize(width: width, height: Layout.barHeight),
                                cornerRadius: Layout.barHeight/2)
        
        progressFill = SKShapeNode(rectOf: CGSize(width: 0, height: Layout.barHeight - 2),
                                 cornerRadius: (Layout.barHeight - 2)/2)
        
        super.init()
        setupNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupNodes() {
        setupProgressBar()
        setupProgressFill()
        setupStars()
    }
    
    private func setupProgressBar() {
        progressBar.fillColor = Layout.progressBarColor
        progressBar.strokeColor = .clear
        progressBar.position = .zero
        addChild(progressBar)
    }
    
    private func setupProgressFill() {
            progressFill.fillColor = Layout.progressFillColor
            progressFill.strokeColor = .clear
            // Posicionamos el fill al inicio de la barra
            progressFill.position = CGPoint(x: -barWidth/2, y: 0)
            addChild(progressFill)
        }

    
    private func setupStars() {
        // Calcular el ancho total que ocuparán las estrellas
        let totalStarsWidth = (CGFloat(Layout.maxStars) * Layout.starSize) +
                            (CGFloat(Layout.maxStars - 1) * Layout.starSpacing)
        let startX = -totalStarsWidth / 2
        
        // Crear y posicionar cada estrella
        for i in 0..<Layout.maxStars {
            let star = SKSpriteNode(imageNamed: "star_empty")
            star.size = CGSize(width: Layout.starSize, height: Layout.starSize)
            star.position = CGPoint(
                x: startX + (CGFloat(i) * (Layout.starSize + Layout.starSpacing)),
                y: Layout.barHeight + Layout.starSize/2 + Layout.starVerticalOffset
            )
            stars.append(star)
            addChild(star)
        }
    }
    
    // MARK: - Update Methods
    /// Actualiza la barra de progreso y las estrellas basado en el puntaje actual
    /// - Parameters:
    ///   - score: Puntaje actual del jugador
    ///   - maxScore: Puntaje máximo posible en el nivel
    func updateProgress(score: Int, maxScore: Int) {
        animateProgressBar(score: score, maxScore: maxScore)
        updateStars(score: score, maxScore: maxScore)
    }
    
    private func animateProgressBar(score: Int, maxScore: Int) {
        // Calcular y animar el progreso de la barra
        let progress = min(CGFloat(score) / CGFloat(maxScore), 1.0)
        let fillWidth = barWidth * progress
        
        let resizeAction = SKAction.resize(toWidth: fillWidth, duration: Layout.animationDuration)
        resizeAction.timingMode = .easeOut
        progressFill.run(resizeAction)
    }
    
    private func updateStars(score: Int, maxScore: Int) {
        // Calcular umbrales para cada estrella
        let thresholds = [
            maxScore / 3,        // Primera estrella
            (maxScore * 2) / 3,  // Segunda estrella
            maxScore            // Tercera estrella
        ]
        
        // Actualizar cada estrella con un delay incremental
        for (index, threshold) in thresholds.enumerated() {
            let delay = Double(index) * Layout.starAnimationDelay
            updateStar(at: index, lit: score >= threshold, delay: delay)
        }
    }
    
    private func updateStar(at index: Int, lit: Bool, delay: TimeInterval) {
        let star = stars[index]
        let currentlyLit = star.texture?.description.contains("filled") ?? false
        
        // Solo animar si el estado de la estrella cambia
        guard lit != currentlyLit else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let scaleDown = SKAction.scale(to: Layout.starAnimationScale,
                                         duration: Layout.starAnimationDuration)
            let changeTexture = SKAction.run { [weak star] in
                star?.texture = SKTexture(imageNamed: lit ? "star_filled" : "star_empty")
            }
            let scaleUp = SKAction.scale(to: 1.0,
                                       duration: Layout.starAnimationDuration)
            
            let sequence = SKAction.sequence([scaleDown, changeTexture, scaleUp])
            star.run(sequence)
        }
    }
}
