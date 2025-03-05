//
//  MusicBlocksScene.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit
import UIKit
import SwiftUI

class MusicBlocksScene: SKScene {
    @Environment(\.screenSize) var screenSize
    
    // MARK: - Properties
    /// Managers y Controllers
    let audioController = AudioController.sharedInstance
    private let tunerEngine = TunerEngine.shared
    private let gameEngine = GameEngine()
    private var blocksManager: BlocksManager!
    private var levelStartOverlay: LevelStartOverlayNode?
    
    /// UI Elements
    private var backgroundPattern: BackgroundPatternNode!
    private var mainAreaNode: SKNode!
    private var mainAreaHeight: CGFloat = 0
    private var mainAreaWidth: CGFloat = 0
    private var topBarNode: TopBar?
    private var currentOverlay: GameOverlayNode?
    
    // Indicadores
    var stabilityIndicatorNode: StabilityIndicatorNode!
    var stabilityCounterNode: StabilityCounterNode!
    var tuningIndicatorNode: TuningIndicatorNode!
    var detectedNoteCounterNode: DetectedNoteCounterNode!
    
    /// Estado del juego
    private var lastUpdateTime: TimeInterval = 0
    private let acceptableDeviation: Double = 10.0
    

    
    // MARK: - Layout Configuration
    private struct Layout {
        static let margins = UIEdgeInsets(
            top: 6,
            left: 20,
            bottom: UIScreen.main.bounds.height * 0.05,
            right: 20
        )
        static let cornerRadius: CGFloat = 15
        static let verticalSpacing: CGFloat = 20
        
        // Proporciones de las áreas principales
        static let topBarHeightRatio: CGFloat = 0.08
        static let mainAreaHeightRatio: CGFloat = 0.74
        static let sideBarWidthRatio: CGFloat = 0.07
        static let mainAreaWidthRatio: CGFloat = 0.75
        static let sideBarHeightRatio: CGFloat = 0.4
        
        // Efectos visuales
        static let shadowRadius: CGFloat = 8.0
        static let shadowOpacity: Float = 0.8
        static let shadowOffset = CGPoint(x: 0, y: -2)
        static let containerAlpha: CGFloat = 0.95
    }
    
    // MARK: - Lifecycle Methods
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        print("Scene did move to view")
        
        // Reiniciar el audio cuando la escena se carga
        Task {
            audioController.stop()
            try? await Task.sleep(nanoseconds: 100_000_000)
            await MainActor.run {
                audioController.start()
            }
        }
        
        setupScene()
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        audioController.stop()
    }
    
    // MARK: - Setup Methods
    private func setupScene() {
        setupBackground()
        setupLayout()
        setupAndStart()
    }
    
    private func setupBackground() {
        backgroundPattern = BackgroundPatternNode(size: size)
        backgroundPattern.zPosition = -10
        addChild(backgroundPattern)
    }
    
    private func setupLayout() {
        let safeWidth = size.width - Layout.margins.left - Layout.margins.right
        let safeHeight = size.height - Layout.margins.top - Layout.margins.bottom
        
        let topBarHeight = safeHeight * Layout.topBarHeightRatio
        let mainAreaHeight = safeHeight * Layout.mainAreaHeightRatio
        let mainAreaWidth = safeWidth * Layout.mainAreaWidthRatio
        let sideBarWidth = safeWidth * Layout.sideBarWidthRatio
        let sideBarHeight = safeHeight * Layout.sideBarHeightRatio
        
        setupTopBar(width: safeWidth, height: topBarHeight)
        setupMainArea(width: mainAreaWidth, height: mainAreaHeight, topBarHeight: topBarHeight)
        setupSideBars(width: sideBarWidth, height: sideBarHeight, topBarHeight: topBarHeight)
        
        // Inicializar BlocksManager después de crear mainAreaNode
        blocksManager = BlocksManager(
            mainAreaNode: mainAreaNode,
            mainAreaHeight: mainAreaHeight
        )
    }
    
    private func setupTopBar(width: CGFloat, height: CGFloat) {
        let safeAreaTop = view?.safeAreaInsets.top ?? 0
        let position = CGPoint(
            x: size.width / 2,
            y: size.height - safeAreaTop - height / 2
        )
        
        // Crear la TopBar
        topBarNode = TopBar.create(width: width, height: height, position: position)
        
        if let topBar = topBarNode {
            // Asegurarnos de que la TopBar tenga una zPosition adecuada
            topBar.zPosition = 100 // Un valor alto para asegurar que esté por encima de otros elementos
            
            // Configurar con el nivel actual si existe
            if let currentLevel = GameManager.shared.currentLevel {
                topBar.configure(withLevel: currentLevel)
            }
            
            // IMPORTANTE: Añadir el nodo a la escena
            addChild(topBar)
            
            // Imprimir información de depuración
            print("TopBar configurada en posición: \(position)")
            print("TopBar frame: \(topBar.frame)")
            print("Scene size: \(size)")
            print("Safe area top: \(safeAreaTop)")
        } else {
            print("Error: No se pudo crear la TopBar")
        }
    }
    
    private func setupMainArea(width: CGFloat, height: CGFloat, topBarHeight: CGFloat) {
        mainAreaWidth = width
        mainAreaHeight = height
        
        let containerNode = createContainerWithShadow(
            size: CGSize(width: width, height: height),
            cornerRadius: Layout.cornerRadius,
            position: CGPoint(
                x: size.width/2,
                y: size.height/2 - topBarHeight - Layout.verticalSpacing
            ),
            zPosition: 1
        )
        
        let mainContent = SKNode()
        mainContent.zPosition = 2
        mainContent.position = .zero
        containerNode.addChild(mainContent)
        mainAreaNode = mainContent
        addChild(containerNode)
        
        // Inicializar BlocksManager
        blocksManager = BlocksManager(
            blockSize: CGSize(width: width * 0.8, height: height * 0.15),
            blockSpacing: 10,
            mainAreaNode: mainContent,
            mainAreaHeight: height
        )
        
        print("MainArea configurada - Tamaño: \(width)x\(height)")
    }
    
    private func setupSideBars(width: CGFloat, height: CGFloat, topBarHeight: CGFloat) {
        setupLeftSideBar(width: width, height: height)
        setupRightSideBar(width: width, height: height)
    }
    
    private func setupLeftSideBar(width: CGFloat, height: CGFloat) {
        let position = CGPoint(
            x: Layout.margins.left + width/2,
            y: size.height/2 - (Layout.verticalSpacing/2)
        )
        
        let leftBar = createContainerWithShadow(
            size: CGSize(width: width, height: height),
            cornerRadius: Layout.cornerRadius,
            position: position,
            zPosition: 1
        )
        addChild(leftBar)
        
        setupStabilityIndicators(in: leftBar, at: position, width: width, height: height)
    }
    
    private func setupRightSideBar(width: CGFloat, height: CGFloat) {
        let position = CGPoint(
            x: size.width - Layout.margins.right - width/2,
            y: size.height/2 - (Layout.verticalSpacing/2)
        )
        
        let rightBar = createContainerWithShadow(
            size: CGSize(width: width, height: height),
            cornerRadius: Layout.cornerRadius,
            position: position,
            zPosition: 1
        )
        addChild(rightBar)
        
        setupTuningIndicators(in: rightBar, at: position, width: width, height: height)
    }
    
    private func setupStabilityIndicators(in container: SKNode, at position: CGPoint, width: CGFloat, height: CGFloat) {
        stabilityIndicatorNode = StabilityIndicatorNode(size: CGSize(width: width * 0.6, height: height * 0.9))
        stabilityIndicatorNode.position = .zero
        stabilityIndicatorNode.zPosition = 10
        container.addChild(stabilityIndicatorNode)
        
        let counterYPosition = position.y - height/2 - 30
        stabilityCounterNode = StabilityCounterNode(size: CGSize(width: width * 2.0, height: 30))
        stabilityCounterNode.position = CGPoint(x: position.x, y: counterYPosition)
        stabilityCounterNode.zPosition = 10
        addChild(stabilityCounterNode)
    }
    
    private func setupTuningIndicators(in container: SKNode, at position: CGPoint, width: CGFloat, height: CGFloat) {
        tuningIndicatorNode = TuningIndicatorNode(size: CGSize(width: width * 0.6, height: height * 0.9))
        tuningIndicatorNode.position = .zero
        tuningIndicatorNode.zPosition = 10
        container.addChild(tuningIndicatorNode)
        
        let counterYPosition = position.y - height/2 - 30
        detectedNoteCounterNode = DetectedNoteCounterNode(size: CGSize(width: width * 2.0, height: 30))
        detectedNoteCounterNode.position = CGPoint(x: position.x, y: counterYPosition)
        detectedNoteCounterNode.zPosition = 10
        addChild(detectedNoteCounterNode)
    }
    
    private func createContainerWithShadow(size: CGSize, cornerRadius: CGFloat, position: CGPoint, zPosition: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = zPosition
        
        let shadowNode = SKEffectNode()
        shadowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": Layout.shadowRadius])
        shadowNode.shouldRasterize = true
        shadowNode.shouldEnableEffects = true
        shadowNode.position = Layout.shadowOffset
        container.addChild(shadowNode)
        
        let shadowShape = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        shadowShape.fillColor = .black
        shadowShape.strokeColor = .clear
        shadowShape.alpha = CGFloat(Layout.shadowOpacity)
        shadowNode.addChild(shadowShape)
        
        let mainShape = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        mainShape.fillColor = .white
        mainShape.strokeColor = .clear
        mainShape.alpha = Layout.containerAlpha
        mainShape.zPosition = 1
        container.addChild(mainShape)
        
        return container
    }
    
    // MARK: - Game Control Methods
    private func setupAndStart() {
        initializeUIElements()
        audioController.stop() // Asegurarnos de que el audio está detenido
        
        // Cargar el nivel actual desde UserProfile
        let userProfile = UserProfile.load()
        print("Intentando cargar nivel \(userProfile.statistics.currentLevel)")
        
        if GameManager.shared.loadLevel(userProfile.statistics.currentLevel) {
            if let currentLevel = GameManager.shared.currentLevel {
                print("Nivel \(currentLevel.levelId) cargado: \(currentLevel.name)")
                
                // Configurar TopBar
                topBarNode?.configure(withLevel: currentLevel)
                
                // Inicializar GameEngine con el nivel
                gameEngine.initialize(withLevel: currentLevel)
                
                // Mostrar overlay de inicio de nivel
                showLevelStartOverlay(for: currentLevel)
            }
        } else {
            print("Error al cargar el nivel, intentando cargar tutorial")
            // Intentar cargar el nivel tutorial
            if GameManager.shared.loadLevel(0) {
                if let tutorialLevel = GameManager.shared.currentLevel {
                    print("Tutorial cargado correctamente")
                    
                    // Configurar TopBar
                    topBarNode?.configure(withLevel: tutorialLevel)
                    
                    // Inicializar GameEngine con el tutorial
                    gameEngine.initialize(withLevel: tutorialLevel)
                    
                    // Mostrar overlay de inicio de nivel
                    showLevelStartOverlay(for: tutorialLevel)
                }
            }
        }
    }
    
        // Detener cualquier secuencia anterior si existe
        private func startBlockSequence() {
            removeAction(forKey: "spawnSequence")
            
            let spawnSequence = SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.run { [weak self] in
                            guard let self = self else { return }
                            self.blocksManager.spawnBlock()
                            print("Bloque generado")  // Debug
                        },
                        SKAction.wait(forDuration: 4.0)
                    ])
                )
            ])
            
            run(spawnSequence, withKey: "spawnSequence")
        }
    
    private func initializeUIElements() {
        if detectedNoteCounterNode == nil {
            let safePosition = CGPoint(
                x: min(size.width * 0.9, size.width - DetectedNoteCounterNode.Layout.defaultSize.width),
                y: size.height * 0.3
            )
            detectedNoteCounterNode = DetectedNoteCounterNode.createForRightSideBar(at: safePosition)
            addChild(detectedNoteCounterNode)
        }
    }
    
    private func startGame() {
        audioController.start()
        gameEngine.startNewGame()
        
        // Iniciar secuencia de bloques
        let spawnSequence = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.blocksManager.spawnBlock()
            },
            SKAction.wait(forDuration: 4.0)
        ])
        let spawnRepeat = SKAction.repeat(spawnSequence, count: 6)
        run(spawnRepeat)
        
        updateGameUI()
    }
    
    private func showLevelStartOverlay(for level: GameLevel) {
            // Ocultar overlay anterior si existe
            currentOverlay?.removeFromParent()
            
            // Crear y mostrar el overlay de inicio de nivel
            let overlaySize = CGSize(width: 400, height: 300)
            let overlay = LevelStartOverlayNode(
                size: overlaySize,
                levelId: level.levelId,
                levelName: level.name
            ) { [weak self] in
                // Esta closure se ejecuta cuando termina la cuenta atrás
                self?.startGameplay()
            }
            
            addChild(overlay)
            levelStartOverlay = overlay
            currentOverlay = overlay
            
            overlay.show(in: self, overlayPosition: .center)
        }
        
    private func startGameplay() {
        // Iniciar el juego
        gameEngine.startNewGame()
        
        // Iniciar secuencia de bloques cayendo
        startBlockSequence()
        
        // Actualizar UI
        updateGameUI()
    }
    
    // MARK: - Update Methods
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        
        updateUI()
        checkNoteAndUpdateScore(deltaTime: deltaTime)
    }
    
    private func updateUI() {
        let tunerData = audioController.tunerData
        
        detectedNoteCounterNode?.currentNote = tunerData.note
        detectedNoteCounterNode?.isActive = tunerData.isActive
        
        stabilityIndicatorNode.duration = audioController.stabilityDuration
        stabilityCounterNode.duration = audioController.stabilityDuration
        
        tuningIndicatorNode.deviation = tunerData.deviation
        tuningIndicatorNode.isActive = tunerData.isActive
    }
    
    private func updateGameUI() {
        topBarNode?.updateScore(gameEngine.score)
        topBarNode?.updateLives(gameEngine.lives)
        
        handleGameState()
    }
    
    private func checkNoteAndUpdateScore(deltaTime: TimeInterval) {
        let tunerData = audioController.tunerData
        
        // Obtener la nota y configuración del bloque inferior actual
        let currentBlock = blocksManager.getCurrentBlock()
        
        gameEngine.checkNote(
            currentNote: tunerData.note,
            deviation: tunerData.deviation,
            isActive: tunerData.isActive,
            currentBlockNote: currentBlock?.note,
            currentBlockConfig: currentBlock?.config
        )
        
        updateGameUI()
    }
    
    // MARK: - Game State Handling
    private func handleGameState() {
            switch gameEngine.gameState {
            case .countdown:
                // No hacer nada, el overlay maneja la cuenta atrás
                break
            case .playing:
                handleGameplayState()
            case .gameOver:
                handleGameOver()
            }
        }
    
    private func handleGameplayState() {
        switch gameEngine.noteState {
        case .success(let multiplier, let message):
            showSuccessOverlay(multiplier: multiplier, message: message)
        case .wrong:
            showFailureOverlay()
        default:
            currentOverlay?.hide()
        }
    }
    
    private func handleGameOver() {
        audioController.stop()
        blocksManager.clearBlocks()
        
        showGameOverOverlay()
    }
    
    // MARK: - Overlay Methods
    private func showSuccessOverlay(multiplier: Int, message: String) {
        currentOverlay?.removeFromParent()
        
        let overlaySize = CGSize(width: 350, height: 60)
        let overlay = SuccessOverlayNode(size: overlaySize, multiplier: multiplier, message: message)
        addChild(overlay)
        currentOverlay = overlay
        
        overlay.show(in: self, overlayPosition: .bottom)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak overlay] in
            overlay?.hide()
        }
    }
    
    private func showFailureOverlay() {
        currentOverlay?.removeFromParent()
        
        let overlaySize = CGSize(width: 350, height: 60)
        let overlay = FailureOverlayNode(size: overlaySize)
        addChild(overlay)
        currentOverlay = overlay
        
        overlay.show(in: self, overlayPosition: .bottom)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak overlay] in
            overlay?.hide()
        }
    }
    
    private func showGameOverOverlay() {
        currentOverlay?.removeFromParent()
        
        let overlaySize = CGSize(width: 400, height: 300)
        let overlay = GameOverOverlayNode(size: overlaySize, score: gameEngine.score) { [weak self] in
            self?.gameEngine.startNewGame()
            self?.audioController.start()
            self?.currentOverlay?.hide()
        }
        
        addChild(overlay)
        currentOverlay = overlay
        
        overlay.show(in: self, overlayPosition: .center)
    }
}

// MARK: - Environment Values
private struct ScreenSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = UIScreen.main.bounds.size
}

extension EnvironmentValues {
    var screenSize: CGSize {
        get { self[ScreenSizeKey.self] }
        set { self[ScreenSizeKey.self] = newValue }
    }
}

// MARK: - SwiftUI Representative
struct SpriteViewRepresentable: UIViewRepresentable {
    let size: CGSize
    
    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        view.preferredFramesPerSecond = 60
        view.ignoresSiblingOrder = true
        
        let scene = MusicBlocksScene()
        scene.scaleMode = .resizeFill
        scene.size = size
        view.presentScene(scene)
        
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        if let scene = uiView.scene {
            scene.size = size
        }
    }
}

struct MusicBlocksSceneView: View {
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: MusicBlocksScene(size: geometry.size))
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarHidden(true)
        }
    }
}

#if DEBUG
import SwiftUI

struct MusicBlocksScene_Previews: PreviewProvider {
    static var previews: some View {
        MusicBlocksSceneView()
            .previewDevice("iPhone 16")
    }
}
#endif
