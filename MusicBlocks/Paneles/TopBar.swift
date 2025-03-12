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
        // Ajustamos el contenedor principal para dar más espacio
        container.position = CGPoint(x: 0, y: size.height/2 - Layout.elementPadding)
        
        // Configuramos el nivel alineado a la izquierda
        setupLevelIndicator(in: container)
        
        // Configuramos los corazones a la derecha del nivel
        setupHeartsRow(in: container)
        
        // Configuramos la barra de progreso debajo
        setupScoreDisplay(in: container)
    }
    
    private func setupObjectivesTopBar(in container: SKNode) {
        // El panel de objetivos se añadirá en configure()
    }
    
    private func setupLevelIndicator(in container: SKNode) {
        levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        levelLabel?.fontSize = Layout.levelAndScoreFontSize
        levelLabel?.fontColor = .purple
        levelLabel?.horizontalAlignmentMode = .left
        levelLabel?.verticalAlignmentMode = .center
        levelLabel?.position = CGPoint(x: Layout.elementPadding, y: 0)
        
        if let level = levelLabel {
            container.addChild(level)
        }
    }

    private func setupHeartsRow(in container: SKNode) {
        heartsContainer = SKNode()
        
        // Posicionamos los corazones a la derecha del nivel con un espaciado
        if let levelWidth = levelLabel?.frame.width {
            heartsContainer?.position = CGPoint(
                x: levelWidth + Layout.elementPadding * 2,
                y: 0
            )
        }
        
        if let heartsContainer = heartsContainer {
            container.addChild(heartsContainer)
            setupHearts(in: heartsContainer)
        }
    }

    private func setupScoreDisplay(in container: SKNode) {
        scoreContainer = SKNode()
        
        // Posicionamos la barra de progreso debajo del nivel y los corazones
        scoreContainer?.position = CGPoint(
            x: Layout.elementPadding,
            y: -Layout.verticalSpacing * 3 // Aumentamos el espaciado vertical
        )
        
        // Ajustamos el ancho de la barra de progreso
        let progressWidth = size.width - (Layout.elementPadding * 2)
        let scoreProgress = ScoreProgressNode(width: progressWidth)
        
        if let scoreNode = scoreContainer {
            scoreNode.addChild(scoreProgress)
            container.addChild(scoreNode)
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

// MARK: - TopBar Preview Provider
struct TopBarPreview: PreviewProvider {
    static var previews: some View {
        TopBarPreviewContainer()
            .previewDisplayName("TopBars - Principal y Objetivos")
    }
}

// MARK: - Preview Container
struct TopBarPreviewContainer: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo
                Color.gray.opacity(0.1)
                    
                
                // Scene View
                SpriteView(scene: createPreviewScene(size: geometry.size))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
            }
        }
    }
    
    private func createPreviewScene(size: CGSize) -> SKScene {
        let scene = SKScene(size: size)
        scene.backgroundColor = .clear
        
        // Crear nivel de ejemplo
        let level = GameLevel(
            levelId: 1,
            name: "Nivel de prueba",
            maxScore: 600,
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
                    target: 1000,
                    timeLimit: 180,
                    minimumAccuracy: nil,
                    details: nil
                )
            ),
            blocks: [:]
        )
        
        let mockObjectiveTracker = LevelObjectiveTracker(level: level)
        
        // Calcular dimensiones responsivas
        let safeWidth = size.width - 16
        let topBarWidth = safeWidth * 0.47
        let topBarHeight: CGFloat = min(60, size.height * 0.1)
        let yPosition = size.height - topBarHeight/2 - 6
        
        // Crear TopBars
        let leftBar = TopBar.create(
            width: topBarWidth,
            height: topBarHeight,
            position: CGPoint(x: 8 + topBarWidth/2, y: yPosition),
            type: .main
        )
        
        let rightBar = TopBar.create(
            width: topBarWidth,
            height: topBarHeight,
            position: CGPoint(x: size.width - 8 - topBarWidth/2, y: yPosition),
            type: .objectives
        )
        
        // Configurar las barras
        leftBar.configure(withLevel: level, objectiveTracker: mockObjectiveTracker)
        rightBar.configure(withLevel: level, objectiveTracker: mockObjectiveTracker)
        
        // Simular datos de ejemplo
        leftBar.updateScore(300)
        leftBar.updateLives(2)
        
        let progress = ObjectiveProgress(
            score: 300,
            notesHit: 15,
            accuracySum: 85.0,
            accuracyCount: 1,
            totalBlocksDestroyed: 15,
            timeElapsed: 45
        )
        rightBar.updateObjectiveInfo(with: progress)
        
        // Añadir barras a la escena
        scene.addChild(leftBar)
        scene.addChild(rightBar)
        
        // Añadir líneas guía para desarrollo
        #if DEBUG
        addGuideLines(to: scene, size: size)
        #endif
        
        return scene
    }
    
    private func addGuideLines(to scene: SKScene, size: CGSize) {
        let guideColor = UIColor.red.withAlphaComponent(0.3)
        
        // Márgenes verticales
        let leftMargin = SKShapeNode(rectOf: CGSize(width: 1, height: size.height))
        leftMargin.position = CGPoint(x: 8, y: size.height/2)
        leftMargin.fillColor = guideColor
        scene.addChild(leftMargin)
        
        let rightMargin = SKShapeNode(rectOf: CGSize(width: 1, height: size.height))
        rightMargin.position = CGPoint(x: size.width - 8, y: size.height/2)
        rightMargin.fillColor = guideColor
        scene.addChild(rightMargin)
        
        // Línea central
        let centerLine = SKShapeNode(rectOf: CGSize(width: 1, height: size.height))
        centerLine.position = CGPoint(x: size.width/2, y: size.height/2)
        centerLine.fillColor = guideColor
        scene.addChild(centerLine)
    }
}

// MARK: - Multiple Device Previews
struct TopBarPreview_MultipleDevices: PreviewProvider {
    static var previews: some View {
        Group {
            TopBarPreviewContainer()
                .previewDevice("iPhone 14")
                .previewDisplayName("iPhone 14")
            
            TopBarPreviewContainer()
                .previewDevice("iPhone 14 Pro Max")
                .previewDisplayName("iPhone 14 Pro Max")
            
            TopBarPreviewContainer()
                .previewDevice("iPad Pro (11-inch)")
                .previewDisplayName("iPad Pro 11\"")
                .previewInterfaceOrientation(.landscapeLeft)
        }
    }
}
#endif
