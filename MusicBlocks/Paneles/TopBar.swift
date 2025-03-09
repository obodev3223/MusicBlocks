//
//  TopBar.swift
//  MusicBlocks
//
//  Created by Jose R. García on 9/2325.
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
    private var heartNodes: [SKLabelNode] = []
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
            setupLevelAndScore(in: container)
            setupHeartsRow(in: container)
        }
        
        private func setupObjectivesTopBar(in container: SKNode) {
            // El panel de objetivos se añadirá en configure()
        }
        
        private func setupLevelAndScore(in container: SKNode) {
            let topRowContainer = SKNode()
            
            // Nivel
            levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            levelLabel?.fontSize = Layout.levelAndScoreFontSize
            levelLabel?.fontColor = .purple
            levelLabel?.horizontalAlignmentMode = .left
            levelLabel?.verticalAlignmentMode = .center
            levelLabel?.text = "Nivel 1"
            
            // Separador
            let separator = SKLabelNode(text: " • ")
            separator.fontSize = Layout.levelAndScoreFontSize
            separator.fontColor = .darkGray
            separator.horizontalAlignmentMode = .left
            separator.verticalAlignmentMode = .center
            separator.position = CGPoint(x: (levelLabel?.frame.maxX ?? 0) + 5, y: 0)
            
            // Puntuación
            let scoreIcon = SKLabelNode(text: "🏆")
            scoreIcon.fontSize = Layout.levelAndScoreFontSize
            scoreIcon.horizontalAlignmentMode = .left
            scoreIcon.verticalAlignmentMode = .center
            scoreIcon.position = CGPoint(x: separator.frame.maxX + 5, y: 0)
            
            scoreValue = SKLabelNode(fontNamed: "Helvetica-Bold")
            scoreValue?.fontSize = Layout.levelAndScoreFontSize
            scoreValue?.fontColor = .black
            scoreValue?.horizontalAlignmentMode = .left
            scoreValue?.verticalAlignmentMode = .center
            scoreValue?.text = "0"
            scoreValue?.position = CGPoint(x: scoreIcon.frame.maxX + 5, y: 0)
            
            if let level = levelLabel, let score = scoreValue {
                topRowContainer.addChild(level)
                topRowContainer.addChild(separator)
                topRowContainer.addChild(scoreIcon)
                topRowContainer.addChild(score)
            }
            
            container.addChild(topRowContainer)
        }
        
        private func setupHeartsRow(in container: SKNode) {
            heartsContainer = SKNode()
            heartsContainer?.position = CGPoint(x: 0, y: -(size.height/2) + Layout.verticalSpacing)
            if let heartsContainer = heartsContainer {
                container.addChild(heartsContainer)
                setupHearts(in: heartsContainer)
            }
        }
        
        private func setupHearts(in container: SKNode) {
            heartNodes.forEach { $0.removeFromParent() }
            heartNodes.removeAll()
            
            // Vidas base
            for i in 0..<maxLives {
                let heart = SKLabelNode(text: "❤️")
                heart.fontSize = Layout.heartSize
                heart.verticalAlignmentMode = .center
                heart.horizontalAlignmentMode = .left
                heart.position = CGPoint(x: CGFloat(i) * (Layout.heartSize + Layout.heartSpacing), y: 0)
                heart.fontColor = .red
                container.addChild(heart)
                heartNodes.append(heart)
            }
            
            // Vidas extra
            for i in maxLives..<(maxLives + maxExtraLives) {
                let heart = SKLabelNode(text: "")
                heart.fontSize = Layout.heartSize
                heart.verticalAlignmentMode = .center
                heart.horizontalAlignmentMode = .left
                heart.position = CGPoint(x: CGFloat(i) * (Layout.heartSize + Layout.heartSpacing), y: 0)
                heart.fontColor = .systemYellow
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
            
            let panelSize = CGSize(width: size.width - (Layout.objectivePanelMargin * 2),
                                  height: size.height - (Layout.objectivePanelMargin * 2))
            
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
                scoreValue?.text = "\(newScore)"
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
                        heart.text = "❤️"
                        heart.fontColor = .red
                    } else {
                        heart.text = "♡"
                        heart.fontColor = .red
                    }
                } else if index < maxLives + maxExtraLives {
                    if index < lives {
                        heart.text = "❤️"
                        heart.fontColor = .systemYellow
                    } else {
                        heart.alpha = 0
                    }
                }
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
            width: 300,
            height: 60,
            position: CGPoint(x: 200, y: 250),
            type: .main
        )
        
        // Crear TopBar derecha (objetivos)
        let rightBar = TopBar.create(
            width: 300,
            height: 60,
            position: CGPoint(x: 600, y: 250),
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
