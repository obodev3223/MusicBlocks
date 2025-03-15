//
//  ScoreProgressNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 12/3/25.
//

import SpriteKit

class ScoreProgressNode: SKNode {
    // MARK: - Private Properties
    private var progressBar: SKShapeNode
    private var progressFill: SKShapeNode
    private var stars: [SKSpriteNode] = []
    private var litStars: [Bool] = [] // Añadir un array para seguir el estado de las estrellas
    
    // MARK: - Layout Constants
    private enum Layout {
        static let maxStars: Int = 5
        
        static let starSize: CGFloat = 20
        /// Offset vertical para las estrellas respecto al centro superior de la barra
        /// (ajústalo a 0 si quieres que queden centradas en la altura).
        static let starVerticalOffset: CGFloat = 1
        
        static let barHeight: CGFloat = 8
        
        static let progressBarColor: SKColor = .white.withAlphaComponent(0.6)
        static let progressFillColor: SKColor = .systemPurple
        
        // Animaciones
        static let animationDuration: TimeInterval = 0.3
        static let starAnimationScale: CGFloat = 0.5
        static let starAnimationDuration: TimeInterval = 0.15
        static let starAnimationDelay: TimeInterval = 0.1
    }
    
    private let barWidth: CGFloat
    
    // MARK: - Initialization
    init(width: CGFloat) {
        self.barWidth = width
        
        // En vez de rectOf(...), creamos rect con origen (0,0) y width = barWidth
        progressBar = SKShapeNode(
            rect: CGRect(x: 0, y: 0, width: width, height: Layout.barHeight),
            cornerRadius: Layout.barHeight / 2
        )
        progressFill = SKShapeNode(
            rect: CGRect(x: 0, y: 0, width: 0, height: Layout.barHeight - 2),
            cornerRadius: (Layout.barHeight - 2) / 2
        )
        
        // Inicializar el array de estado de estrellas con todas apagadas
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
    
    /// Barra de fondo, va de x=0 a x=barWidth
    private func setupProgressBar() {
        progressBar.fillColor = Layout.progressBarColor
        progressBar.strokeColor = .clear
        // Su origen local es (0,0)
        progressBar.position = .zero
        addChild(progressBar)
    }
    
    /// Barra "relleno" que crece desde x=0 hacia la derecha
    private func setupProgressFill() {
        progressFill.fillColor = Layout.progressFillColor
        progressFill.strokeColor = .clear
        // También empieza en (0,0)
        progressFill.position = .zero
        addChild(progressFill)
    }

    /// Distribuye las estrellas en el rango [0 .. barWidth]
    private func setupStars() {
        
        for i in 0..<Layout.maxStars {
            let star = SKSpriteNode(imageNamed: "star_empty")
            star.size = CGSize(width: Layout.starSize, height: Layout.starSize)
            
            // Fracción de 0 a 1
            let fraction = CGFloat(i) / CGFloat(Layout.maxStars - 1)
            // X = fraction * barWidth
            let xPos = fraction * barWidth
            
            // Ajusta la altura de las estrellas
            let yPos = (Layout.barHeight / 2) + Layout.starVerticalOffset
            
            star.position = CGPoint(x: xPos, y: yPos)
            stars.append(star)
            addChild(star)
        }
    }
    
    // MARK: - Update Methods
    func updateProgress(score: Int, maxScore: Int) {
        animateProgressBar(score: score, maxScore: maxScore)
        updateStars(score: score, maxScore: maxScore)
    }
    
    private func animateProgressBar(score: Int, maxScore: Int) {
        let fraction = min(CGFloat(score) / CGFloat(maxScore), 1.0)
        let fillWidth = barWidth * fraction
        
        // Redimensionamos el ancho del rect
        let resizeAction = SKAction.resize(toWidth: fillWidth, duration: Layout.animationDuration)
        resizeAction.timingMode = .easeOut
        progressFill.run(resizeAction)
    }
    
    private func updateStars(score: Int, maxScore: Int) {
        // Cinco estrellas: se encienden en 1/5, 2/5, 3/5, 4/5, 5/5 de maxScore
        let step = maxScore / Layout.maxStars
        let thresholds = (1...Layout.maxStars).map { step * $0 }
        
        for (index, threshold) in thresholds.enumerated() {
            let delay = Double(index) * Layout.starAnimationDelay
            updateStar(at: index, lit: score >= threshold, delay: delay)
        }
    }
    
    private func updateStar(at index: Int, lit: Bool, delay: TimeInterval) {
        let star = stars[index]
        let currentlyLit = star.texture?.description.contains("filled") ?? false
        
        guard lit != currentlyLit else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak star] in
            guard let star = star else { return }
            
            let scaleDown = SKAction.scale(to: Layout.starAnimationScale,
                                           duration: Layout.starAnimationDuration)
            let changeTexture = SKAction.run {
                star.texture = SKTexture(imageNamed: lit ? "star_filled" : "star_empty")
            }
            let scaleUp = SKAction.scale(to: 1.0,
                                         duration: Layout.starAnimationDuration)
            let sequence = SKAction.sequence([scaleDown, changeTexture, scaleUp])
            star.run(sequence)
        }
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
