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
        static let heartSize: CGFloat = 14
        static let heartSpacing: CGFloat = 4
        static let horizontalMargin: CGFloat = 25
        static let levelFontSize: CGFloat = 16
        static let levelSpacing: CGFloat = 10
        static let verticalSpacing: CGFloat = 8
    }
    
    // MARK: - Properties
    private let size: CGSize
    private let scoreLabel: SKLabelNode
    private let scoreIcon: SKLabelNode
    private let scoreText: SKLabelNode
    private var levelLabel: SKLabelNode
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
        
        // Crear contenedor principal
            let backgroundNode = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
            backgroundNode.zPosition = 1
            backgroundNode.fillColor = .white
            backgroundNode.strokeColor = .clear
            backgroundNode.alpha = Layout.backgroundAlpha
            addChild(backgroundNode)
            
            // Crear el área izquierda para nivel y vidas
            let leftAreaNode = SKNode()
            leftAreaNode.position = CGPoint(x: -size.width/2 + Layout.horizontalMargin, y: size.height/4)
            leftAreaNode.zPosition = 2
            addChild(leftAreaNode)
            
            // Título del nivel
            levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            levelLabel.fontSize = Layout.levelFontSize
            levelLabel.fontColor = .purple
            levelLabel.horizontalAlignmentMode = .left
            levelLabel.verticalAlignmentMode = .top
            levelLabel.position = CGPoint(x: 0, y: 0)
            levelLabel.zPosition = 3
            leftAreaNode.addChild(levelLabel)
            
            // Contenedor para los corazones
            let heartsContainer = SKNode()
            heartsContainer.position = CGPoint(x: 0, y: -Layout.verticalSpacing - Layout.heartSize)
            heartsContainer.zPosition = 3
            leftAreaNode.addChild(heartsContainer)
            
            // Área de puntuación (derecha)
            let scoreArea = SKNode()
            scoreArea.position = CGPoint(x: size.width/2 - Layout.horizontalMargin, y: 0)
            scoreArea.zPosition = 2
            addChild(scoreArea)
            
            // Estrella y puntuación con zPosition ajustada
            scoreIcon.zPosition = 3
            scoreText.zPosition = 3
            scoreLabel.zPosition = 3
            
            scoreIcon.position = CGPoint(x: -120, y: 0)
            scoreText.position = CGPoint(x: -85, y: 0)
            scoreLabel.position = CGPoint(x: -30, y: 0)
            
            scoreArea.addChild(scoreIcon)
            scoreArea.addChild(scoreText)
            scoreArea.addChild(scoreLabel)
        }
    
    private func setupHearts() {
        // Limpiar corazones existentes
        for heart in heartNodes {
            heart.removeFromParent()
        }
        heartNodes.removeAll()
        
        // Inicialmente solo mostrar las vidas base
        for i in 0..<maxLives {
            let heart = SKLabelNode(text: "❤️")
            heart.fontSize = Layout.heartSize
            heart.verticalAlignmentMode = .center
            heart.horizontalAlignmentMode = .left
            heart.zPosition = 3
            heart.position = CGPoint(
                x: CGFloat(i) * (Layout.heartSize + Layout.heartSpacing),
                y: -15
            )
            heart.fontColor = .red
            addChild(heart)
            heartNodes.append(heart)
        }
        
        // Preparar espacios para vidas extra (inicialmente ocultos)
        for i in maxLives..<(maxLives + maxExtraLives) {
            let heart = SKLabelNode(text: "")  // Inicialmente vacío
            heart.fontSize = Layout.heartSize
            heart.verticalAlignmentMode = .center
            heart.horizontalAlignmentMode = .left
            heart.zPosition = 3
            heart.position = CGPoint(
                x: CGFloat(i) * (Layout.heartSize + Layout.heartSpacing),
                y: -15
            )
            heart.fontColor = .purple
            heart.alpha = 0  // Inicialmente invisible
            addChild(heart)
            heartNodes.append(heart)
        }
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
        updateLives(lives)
        updateScore(0)
        
        print("TopBar configurada - Nivel: \(level.levelId), Vidas base: \(maxLives), Vidas extra posibles: \(maxExtraLives)")
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
        
        for (index, heart) in heartNodes.enumerated() {
            if index < maxLives {
                // Vidas base
                heart.alpha = 1.0
                if index < lives {
                    heart.text = "❤️"  // Corazón lleno
                } else {
                    heart.text = "♡"   // Corazón vacío
                }
            } else {
                // Vidas extra
                if index < lives {
                    heart.text = "❤️"
                    heart.alpha = 1.0  // Mostrar vida extra ganada
                } else {
                    heart.alpha = 0    // Mantener oculta
                }
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
        
        // Crear niveles de ejemplo que simulan la configuración del JSON
        let level0 = GameLevel(
            levelId: 0,
            name: "Nivel 0. Tutorial",
            allowedStyles: ["default"],
            fallingSpeed: FallingSpeed(initial: 8.0, increment: 0.0),
            lives: Lives(
                initial: 3,
                extraLives: ExtraLives(
                    scoreThresholds: [500, 1000],
                    maxExtra: 2
                )
            ),
            objectives: Objectives(
                primary: Objective(
                    type: "score",
                    target: 100,
                    timeLimit: 180,
                    minimumAccuracy: nil,
                    details: nil,
                    requireAll: nil
                ),
                secondary: nil
            ),
            blocks: [:]
        )
        
        let level1 = GameLevel(
            levelId: 1,
            name: "Nivel 1",
            allowedStyles: ["defaultBlock", "iceBlock"],
            fallingSpeed: FallingSpeed(initial: 8.0, increment: 0.0),
            lives: Lives(
                initial: 4,
                extraLives: ExtraLives(
                    scoreThresholds: [500, 1000, 1500],
                    maxExtra: 3
                )
            ),
            objectives: Objectives(
                primary: Objective(
                    type: "note_accuracy",
                    target: 10,
                    timeLimit: 0,
                    minimumAccuracy: 0.8,
                    details: nil,
                    requireAll: nil
                ),
                secondary: nil
            ),
            blocks: [:]
        )
        
        let level2 = GameLevel(
            levelId: 2,
            name: "Nivel 2",
            allowedStyles: ["defaultBlock", "hardIceBlock", "ghostBlock"],
            fallingSpeed: FallingSpeed(initial: 7.0, increment: 0.0),
            lives: Lives(
                initial: 5,
                extraLives: ExtraLives(
                    scoreThresholds: [500, 1000, 1500, 2000],
                    maxExtra: 4
                )
            ),
            objectives: Objectives(
                primary: Objective(
                    type: "total_blocks",
                    target: 15,
                    timeLimit: 240,
                    minimumAccuracy: nil,
                    details: nil,
                    requireAll: nil
                ),
                secondary: nil
            ),
            blocks: [:]
        )
        
        // Crear un TopBar con nivel tutorial (3 vidas + 2 extra)
        let tutorialBar = TopBar.create(
            width: 350,
            height: 60,
            position: CGPoint(x: 200, y: 250)
        )
        tutorialBar.configure(withLevel: level0)
        tutorialBar.updateScore(0)
        scene.addChild(tutorialBar)
        
        // Crear un TopBar con nivel 1 (4 vidas + 3 extra, algunas perdidas)
        let level1Bar = TopBar.create(
            width: 350,
            height: 60,
            position: CGPoint(x: 200, y: 150)
        )
        level1Bar.configure(withLevel: level1)
        level1Bar.updateScore(750)
        level1Bar.updateLives(5) // 4 base + 1 extra ganada, 2 perdidas
        scene.addChild(level1Bar)
        
        // Crear un TopBar con nivel 2 (5 vidas + 4 extra, todas las extra ganadas)
        let level2Bar = TopBar.create(
            width: 350,
            height: 60,
            position: CGPoint(x: 200, y: 50)
        )
        level2Bar.configure(withLevel: level2)
        level2Bar.updateScore(2500)
        level2Bar.updateLives(9) // Todas las vidas disponibles (5 base + 4 extra)
        scene.addChild(level2Bar)
        
        return scene
    }
}

struct TopBarPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            // Vista previa de la TopBar
            SpriteView(scene: TopBar.createPreviewScene())
                .frame(width: 400, height: 300)
                .previewLayout(.fixed(width: 400, height: 300))
            
            // Leyenda explicativa
            VStack(alignment: .leading, spacing: 8) {
                Text("Leyenda:")
                    .font(.headline)
                HStack {
                    Text("❤️").foregroundColor(.red)
                    Text("Vidas base")
                }
                HStack {
                    Text("❤️").foregroundColor(.purple)
                    Text("Vidas extra")
                }
                Text("♡ Vida perdida")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .background(Color.gray.opacity(0.2))
        .previewDisplayName("TopBar Estados")
    }
}
#endif
