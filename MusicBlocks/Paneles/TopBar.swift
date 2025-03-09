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
        // Configuración del contenedor
        static let cornerRadius: CGFloat = 15
        static let backgroundAlpha: CGFloat = 0.95
        static let shadowOpacity: Float = 0.2
        
        // Espaciado y márgenes
        static let horizontalMargin: CGFloat = 15
        static let verticalSpacing: CGFloat = 8
        static let elementPadding: CGFloat = 10
        
        // Configuración de fuentes
        static let scoreFontSize: CGFloat = 16     // Añadido para compatibilidad
        static let levelFontSize: CGFloat = 16     // Mantenido
        static let levelAndScoreFontSize: CGFloat = 18
        
        // Iconos y símbolos
        static let scoreIconSize: CGFloat = 16
        static let heartSize: CGFloat = 16
        static let heartSpacing: CGFloat = 6
        
        // Divisores
        static let dividerText = " - "
        
        // Panel de objetivos
        static let objectivePanelWidth: CGFloat = 200
        static let objectivePanelRightMargin: CGFloat = 20
        
        // Distribución vertical
        static let topRowHeightRatio: CGFloat = 0.33
        static let middleRowHeightRatio: CGFloat = 0.34
        static let bottomRowHeightRatio: CGFloat = 0.33
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
    private init(width: CGFloat, height: CGFloat, position: CGPoint) {
        self.size = CGSize(width: width, height: height)
        
        // Inicializar etiqueta de nivel y puntuación combinada
            levelAndScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            levelAndScoreLabel.fontSize = Layout.levelAndScoreFontSize
            levelAndScoreLabel.fontColor = .purple
            levelAndScoreLabel.verticalAlignmentMode = .center
            levelAndScoreLabel.horizontalAlignmentMode = .left
        
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
        // Aplicar el estilo común del contenedor
        applyContainerStyle(size: size)
        
        // Contenedor principal
        let mainContainer = SKNode()
        mainContainer.position = CGPoint(x: -size.width/2 + Layout.horizontalMargin, y: size.height/2 - Layout.horizontalMargin)
        addChild(mainContainer)
        
        // 1. Configurar fila superior (Nivel y Score)
        setupTopRow(in: mainContainer)
        
        // 2. Configurar fila de corazones
        setupHeartsRow(in: mainContainer)
        
        // 3. Área para el panel de objetivos
        setupObjectivePanelArea(in: mainContainer)
    }
    
    private func setupTopRow(in container: SKNode) {
            levelAndScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
            levelAndScoreLabel.fontSize = Layout.levelAndScoreFontSize
            levelAndScoreLabel.fontColor = .purple
            levelAndScoreLabel.horizontalAlignmentMode = .left
            levelAndScoreLabel.verticalAlignmentMode = .top
            levelAndScoreLabel.position = CGPoint(x: 0, y: 0)
            container.addChild(levelAndScoreLabel)
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
    static func create(width: CGFloat, height: CGFloat, position: CGPoint) -> TopBar {
        return TopBar(width: width, height: height, position: position)
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
                panel.position = CGPoint(
                    x: size.width - Layout.objectivePanelWidth - Layout.objectivePanelRightMargin,
                    y: -size.height * Layout.topRowHeightRatio
                )
                addChild(panel)
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
            
            // Leyenda explicativa
            VStack(alignment: .leading, spacing: 8) {
                Text("Leyenda:")
                    .font(.headline)
                HStack {
                    Text("❤️").foregroundColor(.red)
                    Text("Vidas base")
                }
                HStack {
                    Text("❤️").foregroundColor(.yellow)
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
