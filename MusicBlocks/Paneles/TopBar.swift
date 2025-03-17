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
        case main       // Para nivel, puntuación y vidas
        case objectives // Para objetivos
    }
    
    // MARK: - Layout
    private struct Layout {
        // Tamaño fijo del TopBar
        static let cornerRadius: CGFloat = 10
        
        // Separaciones
        static let horizontalPadding: CGFloat = 10 // Se usa para desplazar la fila superior hacia la derecha desde el borde izquierdo del contenedor
        static let verticalPadding: CGFloat = 12 // Se usa para desplazar la fila superior hacia abajo desde el borde superior del contenedor.
        
        // Separaciones para la fila inferior
            static let bottomRowHorizontalPadding: CGFloat = 18

        static let itemSpacing: CGFloat = 8
        
        // Texto
        static let fontSize: CGFloat = 14
        
        // Corazones
        static let heartSize: CGFloat = 16
        static let heartSpacing: CGFloat = 6
        
        // Distancia vertical entre fila superior y fila inferior
        static let rowSpacing: CGFloat = 14
    }
    
    // MARK: - Propiedades
    private let barSize: CGSize
    private let type: TopBarType
    
    // Fila superior
    private let topRow = SKNode()
    private var levelLabel: SKLabelNode?
    private var heartsContainer = SKNode()
    
    // Fila inferior
    private let bottomRow = SKNode()
    private var scoreProgressNode: ScoreProgressNode?
    private var objectivePanel: ObjectiveInfoPanel?
    
    // Vidas
    private var heartNodes: [SKSpriteNode] = []
    private var maxLives: Int = 0
    private var maxExtraLives: Int = 0
    private var lives: Int = 0
    
    // MARK: - Init
    private init(width: CGFloat, height: CGFloat, position: CGPoint, type: TopBarType) {
        self.barSize = CGSize(width: width, height: height)
        self.type = type
        super.init()
        
        self.position = position
        
        // Fondo y sombra (definido en tu UIContainer.swift)
        applyContainerStyle(size: barSize)
        
        // Añadir las dos filas
        addChild(topRow)
        addChild(bottomRow)
        
        switch type {
        case .main:
            setupMainTopBar()
        case .objectives:
            // El panel de objetivos se configura luego en configureObjectivesBar(...)
            break
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Crear la TopBar
    static func create(width: CGFloat, height: CGFloat, position: CGPoint, type: TopBarType) -> TopBar {
        return TopBar(width: width, height: height, position: position, type: type)
    }
    
    // MARK: - Setup para la barra principal
    private func setupMainTopBar() {
        // Fila superior: Nivel, separador y contenedor de corazones
        levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        levelLabel?.fontSize = Layout.fontSize
        levelLabel?.fontColor = .purple
        levelLabel?.verticalAlignmentMode = .center
        levelLabel?.horizontalAlignmentMode = .left
        levelLabel?.text = "Nivel ?" // Se actualiza en configure(...)
        
        let separator = SKLabelNode(fontNamed: "Helvetica-Bold")
        separator.text = "·"
        separator.fontSize = Layout.fontSize
        separator.fontColor = .darkGray
        separator.verticalAlignmentMode = .center
        separator.horizontalAlignmentMode = .left
        
        // Layout horizontal en topRow
        var currentX: CGFloat = -barSize.width/2 + Layout.horizontalPadding
        let rowY: CGFloat = barSize.height/2 - Layout.verticalPadding
        
        // 1) levelLabel
        if let label = levelLabel {
            label.position = CGPoint(x: currentX, y: rowY)
            topRow.addChild(label)
            currentX += label.frame.width + Layout.itemSpacing
        }
        
        // 2) separador
        separator.position = CGPoint(x: currentX, y: rowY)
        topRow.addChild(separator)
        currentX += separator.frame.width + Layout.itemSpacing + 5
        
        // 3) heartsContainer
        heartsContainer.position = CGPoint(x: currentX, y: rowY)
        topRow.addChild(heartsContainer)
        // (los corazones se crean en setupHearts(...) luego)

    }
    
    private func setupScoreDisplay() {
        let topRowHeight = topRow.calculateAccumulatedFrame().height
        bottomRow.position = CGPoint(
            x: 0,
            y: (barSize.height/2 - Layout.verticalPadding) - topRowHeight - Layout.rowSpacing
        )
        
        // Ahora restamos bottomRowHorizontalPadding en lugar de horizontalPadding
        let availableWidth = barSize.width - (Layout.bottomRowHorizontalPadding * 2)
        
        let progressNode = ScoreProgressNode(width: availableWidth)
        
        // Centrarlo horizontalmente en bottomRow,
        // dejando bottomRowHorizontalPadding desde el borde izquierdo del TopBar
        progressNode.position = CGPoint(
            x: -barSize.width/2 + Layout.bottomRowHorizontalPadding,
            y: 0
        )
        
        bottomRow.addChild(progressNode)
        scoreProgressNode = progressNode
    }

    
    // MARK: - Configuración
    func configure(withLevel level: GameLevel, objectiveTracker: LevelObjectiveTracker) {
        switch type {
        case .main:
            configureMainBar(withLevel: level)
        case .objectives:
            configureObjectivesBar(withLevel: level, objectiveTracker: objectiveTracker)
        }
    }
    
    private func configureMainBar(withLevel level: GameLevel) {
        // 1) Ajustamos el texto y las vidas
        levelLabel?.text = "Nivel \(level.levelId)"

        maxLives = level.lives.initial
        maxExtraLives = level.lives.extraLives.maxExtra
        lives = level.lives.initial

        setupHearts(in: heartsContainer)
        updateLives(lives)

        // 2) En vez de llamar a setupScoreDisplay() directamente,
        //    lo hacemos en la siguiente iteración del runloop:
        DispatchQueue.main.async {
            self.setupScoreDisplay()
        }
    }
    
    private func configureObjectivesBar(withLevel level: GameLevel, objectiveTracker: LevelObjectiveTracker) {
        topRow.removeFromParent()  // si no usas la fila superior

        objectivePanel?.removeFromParent()
        
        let panelSize = CGSize(width: barSize.width, height: barSize.height)
        let panel = ObjectivePanelFactory.createPanel(
            for: level.objectives.primary,
            size: panelSize,
            tracker: objectiveTracker
        )
        objectivePanel = panel
        
        // bottomRow centrado en (0,0)
        bottomRow.position = .zero
        bottomRow.removeAllChildren()
        
        // AHORA, para alinear el borde izquierdo del panel con la TopBar:
        // la TopBar va de x = -barSize.width/2 a x = +barSize.width/2
        // si pones panel.position.x = -barSize.width/2 + 10, dejas 10 px de margen
        panel.position = CGPoint(x: -barSize.width/2 + 10, y: 0)
        
        bottomRow.addChild(panel)
    }


    
    // MARK: - Score y Vidas
    func updateScore(_ newScore: Int) {
        // No actualizar si el scoreProgressNode aún no está inicializado
        guard type == .main,
              let scoreNode = scoreProgressNode,
              let currentLevel = GameManager.shared.currentLevel,
              currentLevel.maxScore > 0 else { return }
        
        // Usar maxScore directamente del nivel actual
        scoreNode.updateProgress(score: newScore, maxScore: currentLevel.maxScore)
    }
    
    func updateLives(_ newLives: Int) {
        if type == .main {
            lives = newLives
            updateHeartsDisplay()
        }
    }
    
    // MARK: - Corazones
    private func setupHearts(in container: SKNode) {
        // Limpia corazones anteriores
        heartNodes.forEach { $0.removeFromParent() }
        heartNodes.removeAll()
        
        var currentX: CGFloat = 0
        // Vidas base
        for _ in 0..<maxLives {
            let heart = SKSpriteNode(imageNamed: "heart_filled")
            heart.size = CGSize(width: Layout.heartSize, height: Layout.heartSize)
            heart.position = CGPoint(x: currentX, y: 0)
            container.addChild(heart)
            heartNodes.append(heart)
            currentX += Layout.heartSize + Layout.heartSpacing
        }
        
        // Vidas extra
        for _ in 0..<maxExtraLives {
            let heart = SKSpriteNode(imageNamed: "heart_extra")
            heart.size = CGSize(width: Layout.heartSize, height: Layout.heartSize)
            heart.alpha = 0
            heart.position = CGPoint(x: currentX, y: 0)
            container.addChild(heart)
            heartNodes.append(heart)
            currentX += Layout.heartSize + Layout.heartSpacing
        }
    }
    
    private func updateHeartsDisplay() {
        for (index, heart) in heartNodes.enumerated() {
            heart.alpha = 1.0
            
            if index < maxLives {
                if index < lives {
                    heart.texture = SKTexture(imageNamed: "heart_filled")
                } else {
                    heart.texture = SKTexture(imageNamed: "heart_empty")
                }
            } else if index < (maxLives + maxExtraLives) {
                if index < lives {
                    heart.texture = SKTexture(imageNamed: "heart_extra_filled")
                    heart.alpha = 1.0
                } else {
                    heart.alpha = 0
                }
            }
        }
    }
    
    // MARK: - Objetivos
    func updateObjectiveInfo(with progress: ObjectiveProgress) {
        if type == .objectives {
            objectivePanel?.updateInfo(with: progress)
        }
    }
    
    // MARK: - Actualización de Progreso
    func updateProgress(progress: Double) {
        // Solo actualizar en la barra principal
        if type == .main, let progressNode = scoreProgressNode {
            if let currentLevel = GameManager.shared.currentLevel {
                // Calcular la puntuación actual basada en el progreso y la puntuación máxima
                let maxScore = currentLevel.maxScore
                let currentScore = Int(progress * Double(maxScore))
                
                // Actualizar usando la puntuación calculada y maxScore del nivel
                progressNode.updateProgress(score: currentScore, maxScore: maxScore)
                
                // Debug
                GameLogger.shared.scoreUpdate("TopBar: progreso \(Int(progress * 100))% (score \(currentScore)/\(maxScore))")
            }
        }
    }
}


// MARK: - SwiftUI Previews
#if DEBUG
import SwiftUI

struct TopBarPreview: PreviewProvider {
    static var previews: some View {
        TopBarPreviewContainer()
            .previewDisplayName("TopBar")
    }
}

struct TopBarPreviewContainer: View {
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createScene(size: geometry.size))
                .background(Color.gray.opacity(0.2))
        }
    }
    
    private func createScene(size: CGSize) -> SKScene {
        let scene = SKScene(size: size)
        scene.backgroundColor = .darkGray
        
        let level = GameLevel(
            levelId: 1,
            name: "Nivel de prueba",
            maxScore: 600,
            allowedStyles: [],
            fallingSpeed: FallingSpeed(initial: 8.0, increment: 0.0),
            lives: Lives(
                initial: 3,
                extraLives: ExtraLives(scoreThresholds: [500, 1000], maxExtra: 2)
            ),
            objectives: Objectives(primary: Objective(
                type: "score",
                target: 1000,
                timeLimit: 180,
                minimumAccuracy: nil,
                details: nil
            )),
            blocks: [:]
        )
        
        // TopBar de tipo .main (izquierda)
        let topBarWidth = min(size.width * 0.45, 300)
        let topBarHeight: CGFloat = 60
        
        let leftBar = TopBar.create(
            width: topBarWidth,
            height: topBarHeight,
            position: CGPoint(x: size.width/2, y: size.height/2 + 50),
            type: .main
        )
        leftBar.configure(withLevel: level, objectiveTracker: LevelObjectiveTracker(level: level))
        leftBar.updateScore(300)
        leftBar.updateLives(2)
        
        scene.addChild(leftBar)
        
        // TopBar de tipo .objectives (derecha)
        let rightBar = TopBar.create(
            width: topBarWidth,
            height: topBarHeight,
            position: CGPoint(x: size.width/2, y: size.height/2 - 50),
            type: .objectives
        )
        rightBar.configure(withLevel: level, objectiveTracker: LevelObjectiveTracker(level: level))
        let progress = ObjectiveProgress(
            score: 300,
            notesHit: 15,
            accuracySum: 85.0,
            accuracyCount: 1,
            totalBlocksDestroyed: 15,
            timeElapsed: 45
        )
        rightBar.updateObjectiveInfo(with: progress)
        
        scene.addChild(rightBar)
        
        return scene
    }
}
#endif
