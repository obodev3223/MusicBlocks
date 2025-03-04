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
        static let heartSize: CGFloat = 18
        static let heartSpacing: CGFloat = 6
        static let horizontalMargin: CGFloat = 25
        static let levelFontSize: CGFloat = 18
        static let levelSpacing: CGFloat = 10
    }
    
    // MARK: - Properties
    private let size: CGSize
    private let scoreLabel: SKLabelNode
    private let scoreIcon: SKLabelNode
    private let scoreText: SKLabelNode
    private let levelLabel: SKLabelNode
    private var heartNodes: [SKLabelNode] = []
    private var score: Int = 0

    
    // Propiedades para vidas
    private var maxLives: Int = 3 // Vidas base del nivel
    private var maxExtraLives: Int = 0 // Máximo de vidas extra permitidas
    private var lives: Int = 3
    
    // MARK: - Initialization
        private init(width: CGFloat, height: CGFloat, position: CGPoint) {
            self.size = CGSize(width: width, height: height)
            
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
            
            // Inicializar etiqueta de nivel
            levelLabel = SKLabelNode(fontNamed: "Helvetica")
            levelLabel.fontSize = Layout.levelFontSize
            levelLabel.verticalAlignmentMode = .center
            levelLabel.horizontalAlignmentMode = .center
            levelLabel.fontColor = .purple
            
            super.init()
            
            self.position = position
            setupNodes()
        }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        // Configurar posiciones relativas al centro de la TopBar
        let centerY: CGFloat = 0
        
        // Crear nodo de sombra
        let shadowNode = SKEffectNode()
        shadowNode.zPosition = 1
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
        backgroundNode.zPosition = 2
        backgroundNode.fillColor = .white
        backgroundNode.strokeColor = .clear
        backgroundNode.alpha = Layout.backgroundAlpha
        
        // Añadir nodos en orden
        addChild(shadowNode)
        addChild(backgroundNode)
        
        // Configurar elementos del score (a la derecha)
        let rightMargin = size.width/2 - Layout.horizontalMargin
        
        // Posicionar estrella
        scoreIcon.zPosition = 3
        scoreIcon.position = CGPoint(x: rightMargin - 120, y: centerY)
        addChild(scoreIcon)
        
        // Configurar nivel (en el centro)
                levelLabel.zPosition = 3
                levelLabel.position = CGPoint(x: 0, y: centerY)
                addChild(levelLabel)
        
        // Posicionar texto "Score:"
        scoreText.zPosition = 3
        scoreText.position = CGPoint(x: rightMargin - 85, y: centerY)
        addChild(scoreText)
        
        // Posicionar número de puntuación
        scoreLabel.zPosition = 3
        scoreLabel.position = CGPoint(x: rightMargin - 30, y: centerY)
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
            
            // Calcular el número total de espacios para corazones (base + extra)
            let totalHeartSpaces = maxLives + maxExtraLives
            
            // Calcular posición inicial (izquierda)
            let startX = -size.width/2 + Layout.horizontalMargin + Layout.heartSize/2
            let centerY: CGFloat = 0
            
            // Crear todos los corazones posibles
            for i in 0..<totalHeartSpaces {
                let heart = SKLabelNode(text: "❤️")
                heart.fontSize = Layout.heartSize
                heart.verticalAlignmentMode = .center
                heart.zPosition = 3
                heart.position = CGPoint(
                    x: startX + CGFloat(i) * (Layout.heartSize + Layout.heartSpacing),
                    y: centerY
                )
                addChild(heart)
                heartNodes.append(heart)
            }
            
            // Actualizar visualización inicial
            updateLives(lives)
        }
    
    // MARK: - Public Methods
        static func create(width: CGFloat, height: CGFloat, position: CGPoint) -> TopBar {
            return TopBar(width: width, height: height, position: position)
        }
        
        // Método para configurar el nivel inicial
        func configure(withLevel level: GameLevel) {
            maxLives = level.lives.initial
            maxExtraLives = level.lives.extraLives.maxExtra
            lives = level.lives.initial
            
            levelLabel.text = "Nivel \(level.levelId)"
            
            setupHearts()
            updateScore(0)
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
                if index < lives {
                    // Corazón lleno
                    heart.text = "❤️"
                    heart.fontColor = index < maxLives ? .red : .purple // Corazones extra en púrpura
                    heart.alpha = 1.0
                } else {
                    // Corazón vacío
                    heart.text = "♡"
                    heart.fontColor = index < maxLives ? .red : .purple
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
