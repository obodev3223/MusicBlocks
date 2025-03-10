//
//  GameUIManager.swift
//  MusicBlocks
//
//  Created by Jose R. García on 7/3/25.
//

import SpriteKit
import UIKit

class GameUIManager {
    // MARK: - Properties
    private weak var scene: SKScene?
    private weak var mainAreaNode: SKNode?
    private var backgroundPattern: BackgroundPatternNode!
    private var leftTopBarNode: TopBar?
    private var rightTopBarNode: TopBar?
    private var currentOverlay: GameOverlayNode?
    private var objectiveTracker: LevelObjectiveTracker?
    
    // Indicadores
    var stabilityIndicatorNode: StabilityIndicatorNode!
    var stabilityCounterNode: StabilityCounterNode!
    var tuningIndicatorNode: TuningIndicatorNode!
    var detectedNoteCounterNode: DetectedNoteCounterNode!
    
    // Dimensiones
    private var mainAreaHeight: CGFloat = 0
    private var mainAreaWidth: CGFloat = 0
    
    // MARK: - Layout Configuration
    private struct Layout {
        static let margins = UIEdgeInsets(
            top: 6,
            left: 6,
            bottom: UIScreen.main.bounds.height * 0.05,
            right: 6
        )
        static let cornerRadius: CGFloat = 15
        static let verticalSpacing: CGFloat = 5
        
        // Proporciones de las áreas principales
        static let topBarHeightRatio: CGFloat = 0.08
        static let mainAreaHeightRatio: CGFloat = 0.74
        static let sideBarWidthRatio: CGFloat = 0.07
        static let mainAreaWidthRatio: CGFloat = 0.75
        static let sideBarHeightRatio: CGFloat = 0.4
        
        // TopBars específicas
        static let topBarWidthRatio: CGFloat = 0.485  // Aumentado de 0.47 para que sean más anchas
        static let topBarSpacing: CGFloat = 4         // Reducido de 8 para que estén más juntas
        
        // Efectos visuales
        static let shadowRadius: CGFloat = 8.0
        static let shadowOpacity: Float = 0.8
        static let shadowOffset = CGPoint(x: 0, y: -2)
        static let containerAlpha: CGFloat = 0.95
    }
    
    // MARK: - Initialization
    init(scene: SKScene) {
        self.scene = scene
        setupUI()
    }
    
    // MARK: - Public Methods
        func setupUI() {
            setupBackground()
            setupLayout()
        }
        
    func updateUI(score: Int, lives: Int) {
        leftTopBarNode?.updateScore(score)
        leftTopBarNode?.updateLives(lives)
        
        // Crear un objeto ObjectiveProgress con los datos actuales
        if let tracker = objectiveTracker {
            tracker.updateProgress(score: score)
            
            // Crear el objeto de progreso con los datos actualizados
            let progress = ObjectiveProgress(
                score: score,
                notesHit: tracker.notesHit,
                accuracySum: tracker.accuracySum,
                accuracyCount: tracker.accuracyCount,
                blocksByType: tracker.blocksByType,
                totalBlocksDestroyed: tracker.totalBlocksDestroyed,
                timeElapsed: tracker.timeElapsed
            )
            
            // Actualizar el panel de objetivos con estos datos
            rightTopBarNode?.updateObjectiveInfo(with: progress)
        }
    }

    
    // MARK: - Setup Methods
        private func setupBackground() {
            guard let scene = scene else { return }
            backgroundPattern = BackgroundPatternNode(size: scene.size)
            backgroundPattern.zPosition = -10
            scene.addChild(backgroundPattern)
        }
        
        private func setupLayout() {
            guard let scene = scene else { return }
            
            let safeWidth = scene.size.width - Layout.margins.left - Layout.margins.right
            let safeHeight = scene.size.height - Layout.margins.top - Layout.margins.bottom
            
            let topBarHeight = safeHeight * Layout.topBarHeightRatio
            let mainAreaHeight = safeHeight * Layout.mainAreaHeightRatio
            let mainAreaWidth = safeWidth * Layout.mainAreaWidthRatio
            let sideBarWidth = safeWidth * Layout.sideBarWidthRatio
            let sideBarHeight = safeHeight * Layout.sideBarHeightRatio
            
            setupTopBars(width: safeWidth, height: topBarHeight)
            setupMainArea(width: mainAreaWidth, height: mainAreaHeight, topBarHeight: topBarHeight)
            setupSideBars(width: sideBarWidth, height: sideBarHeight, topBarHeight: topBarHeight)
        }
        
    private func setupTopBars(width: CGFloat, height: CGFloat) {
        guard let scene = scene else { return }
        let safeAreaTop = (scene.view?.safeAreaInsets.top ?? 0)
        
        // Calcular dimensiones
        let topBarWidth = width * Layout.topBarWidthRatio
        let yPosition = scene.size.height - safeAreaTop - height / 2
        
        // Calcular posiciones X
        // Ajustamos las posiciones para que estén más cerca de los bordes
        let leftXPosition = Layout.margins.left + topBarWidth/2
        let rightXPosition = scene.size.width - Layout.margins.right - topBarWidth/2
        
        // Crear TopBars
        leftTopBarNode = TopBar.create(
            width: topBarWidth,
            height: height,
            position: CGPoint(x: leftXPosition, y: yPosition),
            type: .main
        )
        
        rightTopBarNode = TopBar.create(
            width: topBarWidth,
            height: height,
            position: CGPoint(x: rightXPosition, y: yPosition),
            type: .objectives
        )
        
        if let leftBar = leftTopBarNode, let rightBar = rightTopBarNode {
            leftBar.zPosition = 100
            rightBar.zPosition = 100
            
            // Configurar las barras
            if let currentLevel = GameManager.shared.currentLevel {
                objectiveTracker = LevelObjectiveTracker(level: currentLevel)
                
                if let tracker = objectiveTracker {
                    leftBar.configure(withLevel: currentLevel, objectiveTracker: tracker)
                    rightBar.configure(withLevel: currentLevel, objectiveTracker: tracker)
                    leftBar.updateLives(currentLevel.lives.initial)
                    leftBar.updateScore(0)
                }
            }
            
            // Añadir a la escena
            scene.addChild(leftBar)
            scene.addChild(rightBar)
            
            // Debug de posiciones
            print("Left TopBar position: \(leftXPosition)")
            print("Right TopBar position: \(rightXPosition)")
            print("TopBar width: \(topBarWidth)")
            print("Scene width: \(scene.size.width)")
        }
    }
    
    private func setupMainArea(width: CGFloat, height: CGFloat, topBarHeight: CGFloat) {
        guard let scene = scene else { return }
        
        mainAreaWidth = width
        mainAreaHeight = height
        
        // Crear el contenedor principal sin fondo ni bordes
        let containerNode = SKNode()
        containerNode.position = CGPoint(
            x: scene.size.width/2,
            y: scene.size.height/2 - Layout.verticalSpacing
        )
        containerNode.zPosition = 1
        
        // Añadir línea límite con efecto de "danger zone"
        addDangerZone(to: containerNode, width: width, height: height)
        
        // Contenido principal (bloques)
        let mainContent = SKNode()
        mainContent.zPosition = 2
        containerNode.addChild(mainContent)
        mainAreaNode = mainContent
        scene.addChild(containerNode)
        
        print("MainArea configurada - Tamaño: \(width)x\(height)")
    }

    private func addDangerZone(to container: SKNode, width: CGFloat, height: CGFloat) {
        guard let scene = scene else { return }
        
        let dangerZone = SKNode()
        dangerZone.zPosition = 1
        
        // Calcular la posición del límite (en la parte inferior)
        let bottomLimit = -(height/2)
        
        // Crear el área de advertencia usando el ancho total de la pantalla y extendiendo hasta el fondo
        let warningArea = SKShapeNode(rect: CGRect(
            x: -scene.size.width/2,
            y: bottomLimit - scene.size.height, // Extender hacia abajo
            width: scene.size.width,
            height: scene.size.height // Usar toda la altura restante de la pantalla
        ))
        warningArea.fillColor = UIColor.red
        warningArea.strokeColor = UIColor.clear
        warningArea.alpha = 0.15
        
        // La línea límite permanece en la misma posición
        let limitLine = SKShapeNode(rect: CGRect(
            x: -scene.size.width/2,
            y: bottomLimit,
            width: scene.size.width,
            height: 2
        ))
        limitLine.fillColor = UIColor.red
        limitLine.strokeColor = UIColor.clear
        limitLine.alpha = 0.8
        
        // Animación de parpadeo solo para la línea
        let fadeSequence = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 0.8, duration: 0.5)
        ])
        limitLine.run(SKAction.repeatForever(fadeSequence))
        
        dangerZone.addChild(warningArea)
        dangerZone.addChild(limitLine)
        
        container.addChild(dangerZone)
    }
    
    private func createDangerMarker(size: CGSize) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: size.width, y: 0))
        path.addLine(to: CGPoint(x: size.width, y: -size.height))
        path.addLine(to: CGPoint(x: 0, y: -size.height))
        path.closeSubpath()
        
        let marker = SKShapeNode(path: path)
        marker.fillColor = UIColor.red
        marker.strokeColor = UIColor.clear
        marker.alpha = 0.8
        
        // Añadir efecto de parpadeo
        let fadeSequence = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 0.8, duration: 0.5)
        ])
        marker.run(SKAction.repeatForever(fadeSequence))
        
        return marker
    }
    
    private func setupSideBars(width: CGFloat, height: CGFloat, topBarHeight: CGFloat) {
        setupLeftSideBar(width: width, height: height)
        setupRightSideBar(width: width, height: height)
    }
    
    private func setupLeftSideBar(width: CGFloat, height: CGFloat) {
        guard let scene = scene else { return }
        let position = CGPoint(
            x: Layout.margins.left + width/2 + 10,
            y: scene.size.height/2 - (Layout.verticalSpacing/2)
        )
        
        // Crear el contenedor y aplicar el estilo directamente
        let leftBar = SKNode()
        leftBar.position = position
        leftBar.zPosition = 1
        leftBar.applyContainerStyle(size: CGSize(width: width, height: height))
        scene.addChild(leftBar)
        
        setupStabilityIndicators(in: leftBar, at: position, width: width, height: height)
    }

    private func setupRightSideBar(width: CGFloat, height: CGFloat) {
        guard let scene = scene else { return }
        let position = CGPoint(
            x: scene.size.width - Layout.margins.right - width/2 - 10,
            y: scene.size.height/2 - (Layout.verticalSpacing/2)
        )
        
        // Crear el contenedor y aplicar el estilo directamente
        let rightBar = SKNode()
        rightBar.position = position
        rightBar.zPosition = 1
        rightBar.applyContainerStyle(size: CGSize(width: width, height: height))
        scene.addChild(rightBar)
        
        setupTuningIndicators(in: rightBar, at: position, width: width, height: height)
    }
    
    // MARK: - Indicator Setup
    private func setupStabilityIndicators(in container: SKNode, at position: CGPoint, width: CGFloat, height: CGFloat) {
        guard let scene = scene else { return }
        stabilityIndicatorNode = StabilityIndicatorNode(size: CGSize(width: width * 0.6, height: height * 0.9))
        stabilityIndicatorNode.position = .zero
        stabilityIndicatorNode.zPosition = 10
        container.addChild(stabilityIndicatorNode)
        
        let counterYPosition = position.y - height/2 - 30
        stabilityCounterNode = StabilityCounterNode(size: CGSize(width: width * 2.0, height: 30))
        stabilityCounterNode.position = CGPoint(x: position.x, y: counterYPosition)
        stabilityCounterNode.zPosition = 10
        scene.addChild(stabilityCounterNode)
    }
    
    private func setupTuningIndicators(in container: SKNode, at position: CGPoint, width: CGFloat, height: CGFloat) {
        guard let scene = scene else { return }
        tuningIndicatorNode = TuningIndicatorNode(size: CGSize(width: width * 0.6, height: height * 0.9))
        tuningIndicatorNode.position = .zero
        tuningIndicatorNode.zPosition = 10
        container.addChild(tuningIndicatorNode)
        
        let counterYPosition = position.y - height/2 - 30
        detectedNoteCounterNode = DetectedNoteCounterNode(size: CGSize(width: width * 2.0, height: 30))
        detectedNoteCounterNode.position = CGPoint(x: position.x, y: counterYPosition)
        detectedNoteCounterNode.zPosition = 10
        scene.addChild(detectedNoteCounterNode)
    }
    
    
    // MARK: - Overlay Methods
    func showLevelStartOverlay(for level: GameLevel, completion: @escaping () -> Void) {
        guard let scene = scene else { return }
        currentOverlay?.removeFromParent()
        
        // Actualizar las vidas en la TopBar antes de mostrar el overlay
        updateUI(score: 0, lives: level.lives.initial)
        
        let overlaySize = CGSize(width: scene.size.width * 0.7, height: scene.size.height * 0.45)
        let overlay = LevelStartOverlayNode(
            size: overlaySize,
            levelId: level.levelId,
            levelName: level.name,
            startAction: completion
        )
        
        scene.addChild(overlay)
        currentOverlay = overlay
        
        overlay.show(in: scene, overlayPosition: .center)
    }
    
    func showSuccessOverlay(multiplier: Int, message: String) {
        guard let scene = scene else { return }
        currentOverlay?.removeFromParent()
        
        let overlaySize = CGSize(width: 350, height: 60)
        let overlay = SuccessOverlayNode(
            size: overlaySize,
            multiplier: multiplier,
            message: message
        )
        scene.addChild(overlay)
        currentOverlay = overlay
        
        overlay.show(in: scene, overlayPosition: .bottom)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak overlay] in
            overlay?.hide()
        }
    }
    
    func showFailureOverlay() {
        guard let scene = scene else { return }
        currentOverlay?.removeFromParent()
        
        let overlaySize = CGSize(width: 350, height: 60)
        let overlay = FailureOverlayNode(size: overlaySize)
        scene.addChild(overlay)
        currentOverlay = overlay
        
        overlay.show(in: scene, overlayPosition: .bottom)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak overlay] in
            overlay?.hide()
        }
    }
    
    func showGameOverOverlay(score: Int, message: String, isVictory: Bool, onRestart: @escaping () -> Void) {
        guard let scene = scene else { return }
        currentOverlay?.removeFromParent()
        
        let overlaySize = CGSize(width: 400, height: 300)
        let overlay = GameOverOverlayNode(
            size: overlaySize,
            score: score,
            message: message,
            isVictory: isVictory,
            restartAction: onRestart
        )
        
        scene.addChild(overlay)
        currentOverlay = overlay
        
        overlay.show(in: scene, overlayPosition: .center)
    }
    
    // MARK: - Public Accessors
    func getMainAreaNode() -> SKNode? {
        return mainAreaNode
    }
    
    func getMainAreaDimensions() -> (width: CGFloat, height: CGFloat) {
        return (mainAreaWidth, mainAreaHeight)
    }
            
        // Método adicional para actualizar el progreso del objetivo
        func updateObjectiveProgress(
            score: Int? = nil,
            noteHit: Bool? = nil,
            accuracy: Double? = nil,
            blockDestroyed: String? = nil,
            deltaTime: TimeInterval? = nil
        ) {
            objectiveTracker?.updateProgress(
                score: score,
                noteHit: noteHit,
                accuracy: accuracy,
                blockDestroyed: blockDestroyed,
                deltaTime: deltaTime
            )
        }
    
    public func configureTopBars(withLevel level: GameLevel, objectiveTracker: LevelObjectiveTracker) {
        leftTopBarNode?.configure(withLevel: level, objectiveTracker: objectiveTracker)
        rightTopBarNode?.configure(withLevel: level, objectiveTracker: objectiveTracker)
    }
}
