//
//  TopBar.swift
//  MusicBlocks
//
//  Created by Jose R. García on 9/23/25.
//

import SpriteKit
import UIKit

class TopBar: SKNode {
    
    enum TopBarType {
        case main      // Para nivel, puntuación y vidas
        case objectives // Para objetivos
    }
    
    // MARK: - Layout Configuration
    private struct Layout {
        // Configuración del contenedor
        static let cornerRadius: CGFloat = 15
        static let backgroundAlpha: CGFloat = 0.95
        static let shadowOpacity: Float = 0.2
        
        // Espaciado y márgenes
        static let horizontalMargin: CGFloat = 12
        static let verticalSpacing: CGFloat = 6
        static let elementPadding: CGFloat = 8
        
        // Configuración de fuentes
        static let levelAndScoreFontSize: CGFloat = 14
        
        // Iconos y símbolos
        static let iconSize: CGFloat = 18
        static let heartSize: CGFloat = 16
        static let heartSpacing: CGFloat = 6
        
        // Panel de objetivos
        static let objectivePanelMargin: CGFloat = 8
    }
    
    // MARK: - Properties
    private let size: CGSize
    private let type: TopBarType
    
    // Propiedades para TopBar principal
    private var levelLabel: SKLabelNode?
    private var scoreValue: SKLabelNode?
    private var scoreContainer: SKNode?
    private var heartNodes: [SKSpriteNode] = [] // Cambiado a SKSpriteNode para imágenes
    private var heartsContainer: SKNode?
    
    // Propiedades para TopBar de objetivos
    private var objectivePanel: ObjectiveInfoPanel?
    
    // Estado
    private var score: Int = 0
    private var maxLives: Int = 3
    private var maxExtraLives: Int = 0
    private var lives: Int = 3
    
    // MARK: - Initialization
    private init(width: CGFloat, height: CGFloat, position: CGPoint, type: TopBarType) {
        self.size = CGSize(width: width, height: height)
        self.type = type
        super.init()
        self.position = position
        setupNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        applyContainerStyle(size: size)
        
        let mainContainer = SKNode()
        mainContainer.position = CGPoint(x: -size.width/2 + Layout.horizontalMargin,
                                         y: size.height/2 - Layout.horizontalMargin)
        addChild(mainContainer)
        
        switch type {
        case .main:
            setupMainTopBar(in: mainContainer)
        case .objectives:
            setupObjectivesTopBar(in: mainContainer)
        }
    }
    
    private func setupMainTopBar(in container: SKNode) {
        // Primero configuramos el nivel
        setupLevelIndicator(in: container)
        
        // Luego configuramos los corazones (vidas) en la fila superior
        setupHeartsRow(in: container, yPosition: 0)
        
        // Finalmente configuramos el score en la fila inferior
        setupScoreDisplay(in: container, yPosition: -(size.height/2) + Layout.verticalSpacing)
    }
    
    private func setupObjectivesTopBar(in container: SKNode) {
        // El panel de objetivos se añadirá en configure()
    }
    
    private func setupLevelIndicator(in container: SKNode) {
        // Nivel
        levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        levelLabel?.fontSize = Layout.levelAndScoreFontSize
        levelLabel?.fontColor = .purple
        levelLabel?.horizontalAlignmentMode = .left
        levelLabel?.verticalAlignmentMode = .center
        levelLabel?.text = "Nivel 1"
        
        if let level = levelLabel {
            container.addChild(level)
        }
    }
    
    private func setupScoreDisplay(in container: SKNode, yPosition: CGFloat) {
        scoreContainer = SKNode()
        scoreContainer?.position = CGPoint(x: 0, y: yPosition)
        
        // Usar el Layout.padding definido en TopBar
        let progressWidth = size.width - (Layout.horizontalMargin * 2)
        let scoreProgress = ScoreProgressNode(width: progressWidth)
        
        if let scoreNode = scoreContainer {
            scoreNode.addChild(scoreProgress)
            container.addChild(scoreNode)
        }
    }
    
    private func setupHeartsRow(in container: SKNode, yPosition: CGFloat) {
        heartsContainer = SKNode()
        heartsContainer?.position = CGPoint(x: levelLabel?.frame.maxX ?? 0 + 10, y: yPosition)
        if let heartsContainer = heartsContainer {
            container.addChild(heartsContainer)
            setupHearts(in: heartsContainer)
        }
    }
    
    private func setupHearts(in container: SKNode) {
        heartNodes.forEach { $0.removeFromParent() }
        heartNodes.removeAll()
        
        // Vidas base - usando imágenes de corazón
        for i in 0..<maxLives {
            let heartTexture = SKTexture(imageNamed: "heart_filled")
            let heart = SKSpriteNode(texture: heartTexture)
            heart.size = CGSize(width: Layout.heartSize, height: Layout.heartSize)
            heart.position = CGPoint(x: CGFloat(i) * (Layout.heartSize + Layout.heartSpacing), y: 0)
            container.addChild(heart)
            heartNodes.append(heart)
        }
        
        // Vidas extra - usando imágenes de corazón con diferente color
        for i in maxLives..<(maxLives + maxExtraLives) {
            let heartTexture = SKTexture(imageNamed: "heart_extra")
            let heart = SKSpriteNode(texture: heartTexture)
            heart.size = CGSize(width: Layout.heartSize, height: Layout.heartSize)
            heart.position = CGPoint(x: CGFloat(i) * (Layout.heartSize + Layout.heartSpacing), y: 0)
            heart.alpha = 0
            container.addChild(heart)
            heartNodes.append(heart)
        }
    }
    
    // MARK: - Public Methods
    static func create(width: CGFloat, height: CGFloat, position: CGPoint, type: TopBarType) -> TopBar {
        return TopBar(width: width, height: height, position: position, type: type)
    }
    
    func configure(withLevel level: GameLevel, objectiveTracker: LevelObjectiveTracker) {
        switch type {
        case .main:
            configureMainBar(withLevel: level)
        case .objectives:
            configureObjectivesBar(withLevel: level, objectiveTracker: objectiveTracker)
        }
    }
    
    private func configureMainBar(withLevel level: GameLevel) {
        levelLabel?.text = "Nivel \(level.levelId)"
        scoreValue?.text = "0"
        maxLives = level.lives.initial
        maxExtraLives = level.lives.extraLives.maxExtra
        lives = level.lives.initial
        
        if let container = heartsContainer {
            setupHearts(in: container)
            updateLives(level.lives.initial)
        }
    }
    
    private func configureObjectivesBar(withLevel level: GameLevel, objectiveTracker: LevelObjectiveTracker) {
        objectivePanel?.removeFromParent()
        
        let panelSize = CGSize(width: size.width, height: size.height)  // Usar todo el espacio disponible
        
        objectivePanel = ObjectivePanelFactory.createPanel(
            for: level.objectives.primary,
            size: panelSize,
            tracker: objectiveTracker
        )
        
        if let panel = objectivePanel {
            panel.position = CGPoint(x: 0, y: 0)
            addChild(panel)
        }
    }
    
    func updateScore(_ newScore: Int) {
        if type == .main {
            score = newScore
            if let scoreProgress = scoreContainer?.children.first as? ScoreProgressNode,
               let currentLevel = GameManager.shared.currentLevel {
                scoreProgress.updateProgress(score: newScore, maxScore: currentLevel.maxScore)
            }
        }
    }
    
    func updateLives(_ newLives: Int) {
        if type == .main {
            lives = newLives
            updateHeartsDisplay()
        }
    }
    
    private func updateHeartsDisplay() {
        for (index, heart) in heartNodes.enumerated() {
            heart.alpha = 1.0
            
            if index < maxLives {
                if index < lives {
                    // Corazón lleno para vidas normales activas
                    heart.texture = SKTexture(imageNamed: "heart_filled")
                } else {
                    // Corazón vacío para vidas normales perdidas
                    heart.texture = SKTexture(imageNamed: "heart_empty")
                }
            } else if index < maxLives + maxExtraLives {
                if index < lives {
                    // Corazón extra activo
                    heart.texture = SKTexture(imageNamed: "heart_extra_filled")
                    heart.alpha = 1.0
                } else {
                    // Ocultar corazones extra no disponibles
                    heart.alpha = 0
                }
            }
        }
    }
    
    public func updateObjectiveInfo(with progress: ObjectiveProgress) {
        if type == .objectives {
            objectivePanel?.updateInfo(with: progress)
        }
    }
}

// MARK: - Previews
#if DEBUG
import SwiftUI

extension TopBar {
    static func createPreviewScene() -> SKScene {
        // Crear una escena de ejemplo
        let scene = SKScene(size: CGSize(width: 800, height: 300))
        scene.backgroundColor = .white
        
        // Crear nivel de ejemplo
        let level0 = GameLevel(
            levelId: 0,
            name: "Nivel 0. Tutorial",
            maxScore: 500,
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
                    details: nil
                )
            ),
            blocks: [:]
        )
        
        let mockObjectiveTracker = LevelObjectiveTracker(level: level0)
        
        // Crear TopBar izquierda (principal)
        let leftBar = TopBar.create(
            width: 370,  // Aproximadamente 47% de 800
            height: 60,
            position: CGPoint(x: 190, y: 250),
            type: .main
        )
        // Crear TopBar derecha (objetivos)
        let rightBar = TopBar.create(
            width: 370,  // Aproximadamente 47% de 800
            height: 60,
            position: CGPoint(x: 610, y: 250),
            type: .objectives
        )
        
        // Configurar ambas barras
        leftBar.configure(withLevel: level0, objectiveTracker: mockObjectiveTracker)
        rightBar.configure(withLevel: level0, objectiveTracker: mockObjectiveTracker)
        
        // Actualizar estado inicial
        leftBar.updateScore(0)
        
        // Añadir a la escena
        scene.addChild(leftBar)
        scene.addChild(rightBar)
        
        return scene
    }
}

struct TopBarPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            // Vista previa de ambas TopBars
            SpriteView(scene: TopBar.createPreviewScene())
                .frame(width: 800, height: 300)
                .previewLayout(.fixed(width: 800, height: 150))
        }
        .background(Color.gray.opacity(0.1))
        .previewDisplayName("TopBars - Principal y Objetivos")
    }
}
#endif
