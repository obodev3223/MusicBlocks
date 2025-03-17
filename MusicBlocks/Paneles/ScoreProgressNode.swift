//
//  ScoreProgressNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 16/3/25.
//

import SpriteKit

class ScoreProgressNode: SKNode {
    // MARK: - Private Properties
    private var progressBar: SKShapeNode
    private var progressFill: SKShapeNode
    private var stars: [SKSpriteNode] = []
    private var litStars: [Bool] = [] // Para seguir el estado de las estrellas
    
    // MARK: - Layout Constants
    private enum Layout {
        static let maxStars: Int = 5
        
        static let starSize: CGFloat = 20
        static let starVerticalOffset: CGFloat = 1
        
        static let barHeight: CGFloat = 8
        
        static let progressBarColor: SKColor = .white.withAlphaComponent(0.6)
        static let progressFillColor: SKColor = .systemPurple
        
        // Animación simple
        static let animationDuration: TimeInterval = 0.3
    }
    
    private let barWidth: CGFloat
    
    // MARK: - Initialization
    init(width: CGFloat) {
        self.barWidth = width
        
        // Barra de progreso con origen en (0,0) y ancho=barWidth
        progressBar = SKShapeNode(
            rect: CGRect(x: 0, y: 0, width: width, height: Layout.barHeight),
            cornerRadius: Layout.barHeight / 2
        )
        progressFill = SKShapeNode(
            rect: CGRect(x: 0, y: 0, width: 0, height: Layout.barHeight - 2),
            cornerRadius: (Layout.barHeight - 2) / 2
        )
        
        // Inicializar estrellas apagadas
        litStars = Array(repeating: false, count: Layout.maxStars)
        
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
    
    /// Barra de fondo
    private func setupProgressBar() {
        progressBar.fillColor = Layout.progressBarColor
        progressBar.strokeColor = .clear
        progressBar.position = .zero
        addChild(progressBar)
    }
    
    /// Barra de relleno que crece con el progreso
    private func setupProgressFill() {
        progressFill.fillColor = Layout.progressFillColor
        progressFill.strokeColor = .clear
        progressFill.position = .zero
        addChild(progressFill)
    }

    /// Distribuye 5 estrellas uniformemente sobre la barra
    private func setupStars() {
        for i in 0..<Layout.maxStars {
            let star = SKSpriteNode(imageNamed: "star_empty")
            star.size = CGSize(width: Layout.starSize, height: Layout.starSize)
            
            // Posición horizontal: distribuir uniformemente (0%, 25%, 50%, 75%, 100%)
            let fraction = CGFloat(i) / CGFloat(Layout.maxStars - 1)
            let xPos = fraction * barWidth
            
            // Ajustar altura para que estén encima de la barra
            let yPos = (Layout.barHeight / 2) + Layout.starVerticalOffset
            
            star.position = CGPoint(x: xPos, y: yPos)
            stars.append(star)
            addChild(star)
        }
    }
    
    // MARK: - Update Methods
    /// Actualiza el progreso basado en puntuación actual y máxima del nivel
    func updateProgress(score: Int, maxScore: Int) {
        // Evitar división por cero
        guard maxScore > 0 else { return }
        
        // Calcular la fracción de progreso (limitado a 1.0)
        let progress = min(CGFloat(score) / CGFloat(maxScore), 1.0)
        
        // Animar la barra de progreso
        animateProgressBar(to: progress)
        
        // Actualizar las estrellas según thresholds específicos
        updateStars(score: score, maxScore: maxScore)
        
        // Debug
        GameLogger.shared.scoreUpdate("ScoreProgressNode: progreso \(Int(progress*100))%, puntuación \(score)/\(maxScore)")
    }
    
    /// Método alternativo para actualizar directamente con un valor de progreso
    func updateProgressDirect(progress: Double) {
        let clampedProgress = min(max(progress, 0.0), 1.0)
        
        // Animar la barra de progreso
        animateProgressBar(to: CGFloat(clampedProgress))
        
        // Calcular puntuación equivalente para las estrellas
        // Usamos 1000 como valor de referencia para mantener consistencia
        let equivalentScore = Int(clampedProgress * 1000)
        updateStars(score: equivalentScore, maxScore: 1000)
        
        // Debug
        GameLogger.shared.scoreUpdate("ScoreProgressNode: progreso directo \(Int(clampedProgress*100))%")
    }
    
    /// Anima la barra de progreso al valor especificado
    private func animateProgressBar(to progress: CGFloat) {
        let targetWidth = barWidth * progress
        
        // Redimensionar con animación
        let resizeAction = SKAction.resize(toWidth: targetWidth, duration: Layout.animationDuration)
        resizeAction.timingMode = .easeOut
        progressFill.run(resizeAction)
    }
    
    /// Actualiza las estrellas basadas en thresholds específicos
    private func updateStars(score: Int, maxScore: Int) {
        // Cada estrella se enciende a 1/5, 2/5, 3/5, 4/5 y 5/5 del maxScore
        let starsStep = maxScore / Layout.maxStars
        
        for i in 0..<Layout.maxStars {
            // Calcular threshold para esta estrella
            let threshold = starsStep * (i + 1)
            
            // Debería estar encendida?
            let shouldBeLit = score >= threshold
            
            // Solo actualizar si el estado cambia
            if litStars[i] != shouldBeLit {
                updateStar(at: i, lit: shouldBeLit)
                litStars[i] = shouldBeLit
            }
        }
    }
    
    /// Actualiza una estrella específica (encendida/apagada)
    private func updateStar(at index: Int, lit: Bool) {
        guard index < stars.count else { return }
        
        let star = stars[index]
        star.texture = lit ?
            SKTexture(imageNamed: "star_filled") :
            SKTexture(imageNamed: "star_empty")
    }
}

// MARK: - SwiftUI Preview
#if DEBUG
import SwiftUI

struct ScoreProgressNodePreview: PreviewProvider {
    static var previews: some View {
        ScoreProgressNodeContainer()
            .frame(width: 340, height: 120)
            .previewDisplayName("Barra con 5 estrellas (x=0..barWidth)")
    }
}

/// Contenedor SwiftUI que muestra el nodo en una escena de SpriteKit
struct ScoreProgressNodeContainer: View {
    private func createScene(size: CGSize) -> SKScene {
        let scene = SKScene(size: size)
        scene.backgroundColor = .black
        
        // Instanciamos la barra con ancho 300, por ejemplo
        let barWidth: CGFloat = 300
        let progressNode = ScoreProgressNode(width: barWidth)
        
        // Colocamos la barra en x=20, y=centro vertical
        // (así su "lado izquierdo" arranca en x=20)
        progressNode.position = CGPoint(x: 20, y: size.height / 2)
        scene.addChild(progressNode)
        
        // Simulamos un score para ver la barra rellena a ~66%
        progressNode.updateProgress(score: 200, maxScore: 300)
        
        return scene
    }
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createScene(size: geometry.size))
        }
    }
}
#endif
