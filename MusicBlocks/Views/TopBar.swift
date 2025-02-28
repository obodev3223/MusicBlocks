//
//  TopBar.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit
import UIKit

class TopBar: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let cornerRadius: CGFloat = 15
        static let glowRadius: Float = 8.0
        static let backgroundAlpha: CGFloat = 0.95
        static let shadowOffset = CGPoint(x: 0, y: -2)
        static let shadowOpacity: Float = 0.2
        static let padding: CGFloat = 20
        static let scoreFontSize: CGFloat = 20
        static let heartSize: CGFloat = 22
        static let heartSpacing: CGFloat = 8
        static let horizontalMargin: CGFloat = 25
    }
    
    // MARK: - Properties
    private let size: CGSize
    private let scoreLabel: SKLabelNode
    private let scoreIcon: SKLabelNode
    private let scoreText: SKLabelNode
    private var heartNodes: [SKLabelNode] = []
    private var score: Int = 0
    
    // Nuevas variables para las vidas
    private var maxLives: Int = 2
    private var lives: Int = 3
    
    // MARK: - Initialization
    private init(width: CGFloat, height: CGFloat, position: CGPoint) {
        self.size = CGSize(width: width, height: height)
        self.lives = maxLives // Inicialmente tienen el valor máximo
        
        // Inicializar estrella de puntuación
        scoreIcon = SKLabelNode(text: "★")
        scoreIcon.fontSize = Layout.scoreFontSize
        scoreIcon.fontColor = .systemYellow
        scoreIcon.verticalAlignmentMode = .center
        
        // Inicializar texto "Score:"
        scoreText = SKLabelNode(fontNamed: "Helvetica")
        scoreText.text = "Score:"
        scoreText.fontSize = Layout.scoreFontSize * 0.8
        scoreText.fontColor = .darkGray
        scoreText.verticalAlignmentMode = .center
        
        // Inicializar etiqueta de puntuación
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.fontSize = Layout.scoreFontSize
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.fontColor = .black
        
        super.init()
        
        self.position = position
        setupNodes()
        updateScore(0)
        updateLives(lives)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        // Crear nodo de sombra
        let shadowNode = SKEffectNode()
        let shadowShape = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        shadowShape.fillColor = .black
        shadowShape.strokeColor = .clear
        shadowShape.alpha = Layout.backgroundAlpha
        shadowNode.addChild(shadowShape)
        shadowNode.shouldRasterize = true
        shadowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": Layout.glowRadius])
        shadowNode.position = Layout.shadowOffset
        shadowNode.alpha = CGFloat(Layout.shadowOpacity)
        
        // Crear fondo principal
        let backgroundNode = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        backgroundNode.fillColor = .white
        backgroundNode.strokeColor = .clear
        backgroundNode.alpha = Layout.backgroundAlpha
        
        // Añadir nodos en orden
        addChild(shadowNode)
        addChild(backgroundNode)
        
        // Configurar etiqueta de puntuación (a la derecha)
        let rightMargin = size.width/2 - Layout.horizontalMargin
        
        // Posicionar estrella
        scoreIcon.position = CGPoint(x: rightMargin - 120, y: 0)
        addChild(scoreIcon)
        
        // Posicionar texto "Score:"
        scoreText.position = CGPoint(x: rightMargin - 85, y: 0)
        addChild(scoreText)
        
        // Posicionar número de puntuación
        scoreLabel.position = CGPoint(x: rightMargin - 30, y: 0)
        addChild(scoreLabel)
        
        // Crear corazones de vida (a la izquierda)
        setupHearts()
    }
    
    private func setupHearts() {
        // Eliminar corazones existentes
        for heart in heartNodes {
            heart.removeFromParent()
        }
        heartNodes.removeAll()
        
        // Calcular posición inicial (izquierda)
        let startX = -size.width/2 + Layout.horizontalMargin + Layout.heartSize/2
        
        // Crear corazones según maxLives
        for i in 0..<maxLives {
            let heart = SKLabelNode(text: "♥︎") // Utilizamos el símbolo básico de corazón
            heart.fontSize = Layout.heartSize
            heart.fontColor = .red
            heart.verticalAlignmentMode = .center
            heart.position = CGPoint(
                x: startX + CGFloat(i) * (Layout.heartSize + Layout.heartSpacing),
                y: 0
            )
            addChild(heart)
            heartNodes.append(heart)
        }
    }
    
    // MARK: - Public Methods
    static func create(width: CGFloat, height: CGFloat, position: CGPoint) -> TopBar {
        return TopBar(width: width, height: height, position: position)
    }
    
    func updateScore(_ newScore: Int) {
        score = newScore
        scoreLabel.text = "\(score)"
        
        // Animar actualización
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        scoreLabel.run(SKAction.sequence([scaleUp, scaleDown]))
    }
    
    func updateLives(_ newLives: Int) {
            self.lives = newLives
            
            // Actualizar la visualización de los corazones
            for (index, heart) in heartNodes.enumerated() {
                if index < newLives {
                    heart.text = "❤️" // Corazón lleno usando emoji
                    heart.fontColor = .red
                    heart.alpha = 1.0
                } else {
                    heart.text = "♡" // Corazón vacío
                    heart.fontColor = .red
                    heart.alpha = 0.5
                }
            }
        }
        
        // Método para actualizar maxLives si es necesario
        func updateMaxLives(_ newMaxLives: Int) {
            if newMaxLives != maxLives {
                maxLives = newMaxLives
                setupHearts() // Recrear los corazones si cambia el máximo
                updateLives(lives) // Actualizar el estado de los corazones
            }
        }
}

// MARK: - Previews
#if DEBUG
import SwiftUI

extension TopBar {
    static func createPreviewScene() -> SKScene {
        // Crear una escena de ejemplo con diferentes estados de TopBar
        let scene = SKScene(size: CGSize(width: 400, height: 300))
        scene.backgroundColor = .lightGray
        
        // Crear un TopBar con puntuación 0 y 3 vidas
        let defaultTopBar = TopBar.create(
            width: 350,
            height: 60,
            position: CGPoint(x: 200, y: 250)
        )
        scene.addChild(defaultTopBar)
        
        // Crear un TopBar con puntuación alta y 2 vidas
        let highScoreTopBar = TopBar.create(
            width: 350,
            height: 60,
            position: CGPoint(x: 200, y: 150)
        )
        highScoreTopBar.updateScore(1250)
        highScoreTopBar.updateLives(2)
        scene.addChild(highScoreTopBar)
        
        // Crear un TopBar con puntuación muy alta y 0 vidas
        let veryHighScoreTopBar = TopBar.create(
            width: 350,
            height: 60,
            position: CGPoint(x: 200, y: 50)
        )
        veryHighScoreTopBar.updateScore(9999)
        veryHighScoreTopBar.updateLives(0)
        scene.addChild(veryHighScoreTopBar)
        
        return scene
    }
}

struct TopBarPreview: PreviewProvider {
    static var previews: some View {
        SpriteView(scene: TopBar.createPreviewScene())
            .frame(width: 400, height: 300)
            .previewLayout(.fixed(width: 400, height: 300))
    }
}
#endif
