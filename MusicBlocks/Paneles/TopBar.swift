//
//  TopBar.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit
import UIKit

class TopBar: SKNode {
    
    enum TopBarType {
           case main      // Para nivel, puntuación y vidas
           case objectives // Para objetivos
       }
       
       private let type: TopBarType
    
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
        
        // Divisores
        static let dividerText = " • "
        
        // Panel de objetivos
        static let objectivePanelWidth: CGFloat = 160
        static let objectivePanelRightMargin: CGFloat = 8
        
        // Distribución vertical
            static let topRowHeightRatio: CGFloat = 0.45
            static let bottomRowHeightRatio: CGFloat = 0.55
    }
    
    // MARK: - Properties
    private let size: CGSize
    private var levelAndScoreLabel: SKLabelNode!
    private var heartNodes: [SKLabelNode] = []
    private var objectivePanel: ObjectiveInfoPanel?
    private var heartsContainer: SKNode?
    private let scoreLabel: SKLabelNode
    private let scoreIcon: SKLabelNode
    private let scoreText: SKLabelNode
    private var levelLabel: SKLabelNode

    private var score: Int = 0
    
    // Propiedades para vidas
    private var maxLives: Int = 3 // Vidas base del nivel
    private var maxExtraLives: Int = 0 // Máximo de vidas extra permitidas
    private var lives: Int = 3
    
    // MARK: - Initialization
    private init(width: CGFloat, height: CGFloat, position: CGPoint, type: TopBarType) {
            self.size = CGSize(width: width, height: height)
            self.type = type
            
            // Inicializar propiedades según el tipo
            if type == .main {
                levelAndScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
                levelAndScoreLabel.fontSize = Layout.levelAndScoreFontSize
                levelAndScoreLabel.fontColor = .purple
                levelAndScoreLabel.verticalAlignmentMode = .center
                levelAndScoreLabel.horizontalAlignmentMode = .left
                
                scoreIcon = SKLabelNode(text: "🏆")
                scoreIcon.fontSize = Layout.levelAndScoreFontSize
                scoreIcon.fontColor = .systemYellow
                scoreIcon.verticalAlignmentMode = .center
                
                scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
                scoreLabel.fontSize = Layout.levelAndScoreFontSize
                scoreLabel.verticalAlignmentMode = .center
                scoreLabel.horizontalAlignmentMode = .left
                scoreLabel.fontColor = .black
            } else {
                levelAndScoreLabel = nil
                scoreIcon = nil
                scoreLabel = nil
            }
            
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
        mainContainer.position = CGPoint(x: -size.width/2 + Layout.horizontalMargin, y: size.height/2 - Layout.horizontalMargin)
        addChild(mainContainer)
        
        switch type {
        case .main:
            setupMainTopBar(in: mainContainer)
        case .objectives:
            setupObjectivesTopBar(in: mainContainer)
        }
    }
    
    private func setupMainTopBar(in container: SKNode) {
            setupTopRow(in: container)
            setupHeartsRow(in: container)
        }
        
        private func setupObjectivesTopBar(in container: SKNode) {
            setupObjectivePanelArea(in: container)
        }
    
    private func setupTopRow(in container: SKNode) {
        // Crear contenedor para nivel y puntuación
        let topRowContainer = SKNode()
        
        // Configurar etiqueta de nivel
        let levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        levelLabel.fontSize = Layout.levelAndScoreFontSize
        levelLabel.fontColor = .purple
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.verticalAlignmentMode = .center
        levelLabel.text = "Nivel 1"
        
        // Configurar separador
        let separator = SKLabelNode(text: " • ")
        separator.fontSize = Layout.levelAndScoreFontSize
        separator.fontColor = .darkGray
        separator.horizontalAlignmentMode = .left
        separator.verticalAlignmentMode = .center
        separator.position = CGPoint(x: levelLabel.frame.maxX + 5, y: 0)
        
        // Configurar icono de puntuación (trofeo)
        let scoreIcon = SKLabelNode(text: "🏆")
        scoreIcon.fontSize = Layout.levelAndScoreFontSize
        scoreIcon.horizontalAlignmentMode = .left
        scoreIcon.verticalAlignmentMode = .center
        scoreIcon.position = CGPoint(x: separator.frame.maxX + 5, y: 0)
        
        // Configurar valor de puntuación
        let scoreValue = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreValue.fontSize = Layout.levelAndScoreFontSize
        scoreValue.fontColor = .black
        scoreValue.horizontalAlignmentMode = .left
        scoreValue.verticalAlignmentMode = .center
        scoreValue.text = "0"
        scoreValue.position = CGPoint(x: scoreIcon.frame.maxX + 5, y: 0)
        
        // Añadir todos los elementos al contenedor
        topRowContainer.addChild(levelLabel)
        topRowContainer.addChild(separator)
        topRowContainer.addChild(scoreIcon)
        topRowContainer.addChild(scoreValue)
        
        container.addChild(topRowContainer)
    }
        
        private func setupHeartsRow(in container: SKNode) {
            heartsContainer = SKNode()
            heartsContainer?.position = CGPoint(x: 0, y: -size.height * Layout.topRowHeightRatio - Layout.verticalSpacing)
            container.addChild(heartsContainer!)
            setupHearts(in: heartsContainer!)
        }
        
        private func setupObjectivePanelArea(in container: SKNode) {
            // El panel de objetivos se añadirá dinámicamente en configure()
        }
        
        func updateLevelAndScore(level: Int, score: Int) {
            levelAndScoreLabel.text = "Nivel \(level)\(Layout.dividerText)Score: \(score)"
        }
    
    private func setupHearts(in container: SKNode) {
        // Limpiar corazones existentes
        heartNodes.forEach { $0.removeFromParent() }
        heartNodes.removeAll()
        
        // Vidas base (rojas)
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
        
        // Vidas extra (doradas)
        for i in maxLives..<(maxLives + maxExtraLives) {
            let heart = SKLabelNode(text: "")
            heart.fontSize = Layout.heartSize
            heart.verticalAlignmentMode = .center
            heart.horizontalAlignmentMode = .left
            heart.position = CGPoint(
                x: CGFloat(i) * (Layout.heartSize + Layout.heartSpacing),
                y: 0
            )
            heart.fontColor = .systemYellow  // Color dorado para vidas extra
            heart.alpha = 0
            container.addChild(heart)
            heartNodes.append(heart)
        }
    }
    
    // MARK: - Public Methods
    static func create(width: CGFloat, height: CGFloat, position: CGPoint, type: TopBarType) -> TopBar {
            return TopBar(width: width, height: height, position: position, type: type)
        }
    
    // Método para configurar el nivel inicial
    func configure(withLevel level: GameLevel, objectiveTracker: LevelObjectiveTracker) {
        // Actualizar nivel y score
        updateLevelAndScore(level: level.levelId, score: 0)
        
        // Configurar vidas
        maxLives = level.lives.initial
        maxExtraLives = level.lives.extraLives.maxExtra
        lives = level.lives.initial
        
        // Eliminar panel anterior si existe
        objectivePanel?.removeFromParent()
        
        // Crear y posicionar nuevo panel de objetivos
        let panelSize = CGSize(
            width: Layout.objectivePanelWidth,
            height: size.height * Layout.middleRowHeightRatio
        )
        
        objectivePanel = ObjectivePanelFactory.createPanel(
            for: level.objectives.primary,
            size: panelSize,
            tracker: objectiveTracker
        )
        
        if let panel = objectivePanel {
            // Calcular la posición del panel en la mitad derecha de la TopBar
            let halfWidth = size.width / 2
            let panelX = halfWidth + (halfWidth - Layout.objectivePanelWidth) / 2 - Layout.objectivePanelRightMargin
            
            panel.position = CGPoint(
                x: panelX,
                y: -size.height * Layout.topRowHeightRatio + Layout.verticalSpacing
            )
            addChild(panel)
            
            // Imprimir información de depuración
            print("Panel position: \(panel.position)")
            print("TopBar size: \(size)")
            print("Panel size: \(panelSize)")
        }
        
        // Actualizar vidas
        if let container = heartsContainer {
            setupHearts(in: container)
            updateLives(level.lives.initial)
        }
    }
    
    func updateScore(_ newScore: Int) {
            guard let levelId = Int(levelAndScoreLabel.text?.components(separatedBy: Layout.dividerText).first?.replacingOccurrences(of: "Nivel ", with: "") ?? "0") else { return }
            updateLevelAndScore(level: levelId, score: newScore)
        }
    
    func updateLives(_ newLives: Int) {
        self.lives = newLives
        
        for (index, heart) in heartNodes.enumerated() {
            heart.alpha = 1.0  // Asegurar que todos los corazones son visibles
            
            if index < maxLives {
                // Vidas base
                if index < lives {
                    heart.text = "❤️"  // Corazón lleno
                    heart.fontColor = .red
                } else {
                    heart.text = "♡"   // Corazón vacío
                    heart.fontColor = .red
                }
            } else if index < maxLives + maxExtraLives {
                // Vidas extra
                if index < lives {
                    heart.text = "❤️"
                    heart.fontColor = .systemYellow
                } else {
                    heart.alpha = 0  // Ocultar corazones extra no ganados
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
        scene.backgroundColor = .white
        
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
                    details: nil
                )
            ),
            blocks: [:]
        )
        
        let mockObjectiveTracker = LevelObjectiveTracker(level: level0)
        
        // Crear un TopBar con nivel tutorial (3 vidas + 2 extra)
        let tutorialBar = TopBar.create(
            width: 350,
            height: 60,
            position: CGPoint(x: 200, y: 250)
        )
        tutorialBar.configure(withLevel: level0, objectiveTracker: mockObjectiveTracker)
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

        }
        .background(Color.white)
        .previewDisplayName("TopBar Estados")
    }
}
#endif
