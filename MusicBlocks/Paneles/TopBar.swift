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
        static let backgroundAlpha: CGFloat = 0.95
        static let shadowOpacity: Float = 0.2
        static let padding: CGFloat = 10
        static let scoreFontSize: CGFloat = 20
        static let heartSize: CGFloat = 14
        static let heartSpacing: CGFloat = 4
        static let horizontalMargin: CGFloat = 25
        static let levelFontSize: CGFloat = 16
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
    
    // Propiedad para mantener referencia al contenedor de corazones
        private var heartsContainer: SKNode?
    
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
        // Contenedor principal con sombra
        let container = SKNode()
        container.zPosition = 1
        addChild(container)
        
        // Sombra
        let shadowNode = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        shadowNode.fillColor = .black
        shadowNode.strokeColor = .clear
        shadowNode.alpha = Layout.backgroundAlpha
        shadowNode.zPosition = 1
        shadowNode.position = CGPoint(x: 2, y: -2)
        container.addChild(shadowNode)
        
        // Fondo principal
        let backgroundNode = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        backgroundNode.fillColor = .white
        backgroundNode.strokeColor = .clear
        backgroundNode.alpha = Layout.backgroundAlpha
        backgroundNode.zPosition = 2
        container.addChild(backgroundNode)
        
        // Área izquierda (nivel y vidas)
        let leftAreaNode = SKNode()
        leftAreaNode.position = CGPoint(x: -size.width/2 + Layout.horizontalMargin, y: 0)
        leftAreaNode.zPosition = 3
        addChild(leftAreaNode)
        
        // Título del nivel
        levelLabel.fontSize = Layout.levelFontSize
        levelLabel.fontColor = .purple
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.verticalAlignmentMode = .center
        levelLabel.position = CGPoint(x: 0, y: size.height/4)
        leftAreaNode.addChild(levelLabel)
        
        // Contenedor para los corazones
                let heartsNode = SKNode()
                heartsNode.position = CGPoint(x: 0, y: levelLabel.position.y - Layout.heartSize - Layout.verticalSpacing)
                leftAreaNode.addChild(heartsNode)
                self.heartsContainer = heartsNode // Guardar la referencia
        
        // Área de puntuación (derecha)
        let scoreArea = SKNode()
        scoreArea.position = CGPoint(x: size.width/2 - Layout.horizontalMargin, y: 0)
        scoreArea.zPosition = 3
        addChild(scoreArea)
        
        // Configurar puntuación
        scoreIcon.position = CGPoint(x: -95, y: 0)
        scoreText.position = CGPoint(x: -60, y: 0)
        scoreLabel.position = CGPoint(x: -30, y: 0)
        
        scoreArea.addChild(scoreIcon)
        scoreArea.addChild(scoreText)
        scoreArea.addChild(scoreLabel)
        
        // Configurar corazones iniciales
        if let container = heartsContainer {
                    setupHearts(in: container)
                }
    }
    
    private func setupHearts(in container: SKNode) {
        // Limpiar corazones existentes
        heartNodes.forEach { $0.removeFromParent() }
        heartNodes.removeAll()
        
        // Inicialmente solo mostrar las vidas base
        for i in 0..<maxLives {
            let heart = SKLabelNode(text: "❤️")
            heart.fontSize = Layout.heartSize
            heart.verticalAlignmentMode = .center
            heart.horizontalAlignmentMode = .left
            heart.position = CGPoint(
                x: CGFloat(i) * (Layout.heartSize + Layout.heartSpacing),
                y: 0
            )
            heart.fontColor = .red
            container.addChild(heart)
            heartNodes.append(heart)
        }
        
        // Preparar espacios para vidas extra (inicialmente ocultos)
        for i in maxLives..<(maxLives + maxExtraLives) {
            let heart = SKLabelNode(text: "")
            heart.fontSize = Layout.heartSize
            heart.verticalAlignmentMode = .center
            heart.horizontalAlignmentMode = .left
            heart.position = CGPoint(
                x: CGFloat(i) * (Layout.heartSize + Layout.heartSpacing),
                y: 0
            )
            heart.fontColor = .purple
            heart.alpha = 0
            container.addChild(heart)
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
        
        if let container = heartsContainer {
            setupHearts(in: container)
        }
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
                if let container = heartsContainer {
                    setupHearts(in: container)
                    updateLives(lives)
                }
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
        
        
        // Crear un TopBar con nivel tutorial (3 vidas + 2 extra)
        let tutorialBar = TopBar.create(
            width: 350,
            height: 60,
            position: CGPoint(x: 200, y: 250)
        )
        tutorialBar.configure(withLevel: level0)
        tutorialBar.updateScore(0)
        scene.addChild(tutorialBar)
        
        
        return scene
    }
}

struct TopBarPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            // Vista previa de la TopBar
            SpriteView(scene: TopBar.createPreviewScene())
                .frame(width: 400, height: 300)
                .previewLayout(.fixed(width: 400, height: 150))
            
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
