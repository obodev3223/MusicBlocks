//
//  GameUIManager.swift
//  MusicBlocks
//
//  Created by Jose R. García on 7/3/25.
//

import SpriteKit

class GameUIManager {
    // MARK: - Properties
    private weak var scene: SKScene?
    private weak var mainAreaNode: SKNode?
    private var backgroundPattern: BackgroundPatternNode!
    private var topBarNode: TopBar?
    private var currentOverlay: GameOverlayNode?
    
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
            left: 20,
            bottom: UIScreen.main.bounds.height * 0.05,
            right: 20
        )
        static let cornerRadius: CGFloat = 15
        static let verticalSpacing: CGFloat = 5
        
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
        topBarNode?.updateScore(score)
        topBarNode?.updateLives(lives)
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
        
        setupTopBar(width: safeWidth, height: topBarHeight)
        setupMainArea(width: mainAreaWidth, height: mainAreaHeight, topBarHeight: topBarHeight)
        setupSideBars(width: sideBarWidth, height: sideBarHeight, topBarHeight: topBarHeight)
    }

        // MARK: - UI Setup Methods
        private func setupTopBar(width: CGFloat, height: CGFloat) {
            guard let scene = scene else { return }
            let safeAreaTop = (scene.view?.safeAreaInsets.top ?? 0)
            let position = CGPoint(
                x: scene.size.width / 2,
                y: scene.size.height - safeAreaTop - height / 2
            )
            
            topBarNode = TopBar.create(width: width, height: height, position: position)
            
            if let topBar = topBarNode {
                topBar.zPosition = 100
                
                if let currentLevel = GameManager.shared.currentLevel {
                    topBar.configure(withLevel: currentLevel)
                }
                
                scene.addChild(topBar)
                
                print("TopBar configurada en posición: \(position)")
                print("TopBar frame: \(topBar.frame)")
                print("Scene size: \(scene.size)")
                print("Safe area top: \(safeAreaTop)")
            } else {
                print("Error: No se pudo crear la TopBar")
            }
        }
        
        private func setupMainArea(width: CGFloat, height: CGFloat, topBarHeight: CGFloat) {
            guard let scene = scene else { return }
            mainAreaWidth = width
            mainAreaHeight = height
            
            let containerNode = createContainerWithShadow(
                size: CGSize(width: width, height: height),
                cornerRadius: Layout.cornerRadius,
                position: CGPoint(
                    x: scene.size.width/2,
                    y: scene.size.height/2 - Layout.verticalSpacing
                ),
                zPosition: 1
            )
            
            let mainContent = SKNode()
            mainContent.zPosition = 2
            containerNode.addChild(mainContent)
            mainAreaNode = mainContent
            scene.addChild(containerNode)
            
            print("MainArea configurada - Tamaño: \(width)x\(height)")
        }
        
        private func setupSideBars(width: CGFloat, height: CGFloat, topBarHeight: CGFloat) {
            setupLeftSideBar(width: width, height: height)
            setupRightSideBar(width: width, height: height)
        }
        
        private func setupLeftSideBar(width: CGFloat, height: CGFloat) {
            guard let scene = scene else { return }
            let position = CGPoint(
                x: Layout.margins.left + width/2,
                y: scene.size.height/2 - (Layout.verticalSpacing/2)
            )
            
            let leftBar = createContainerWithShadow(
                size: CGSize(width: width, height: height),
                cornerRadius: Layout.cornerRadius,
                position: position,
                zPosition: 1
            )
            scene.addChild(leftBar)
            
            setupStabilityIndicators(in: leftBar, at: position, width: width, height: height)
        }
        
        private func setupRightSideBar(width: CGFloat, height: CGFloat) {
            guard let scene = scene else { return }
            let position = CGPoint(
                x: scene.size.width - Layout.margins.right - width/2,
                y: scene.size.height/2 - (Layout.verticalSpacing/2)
            )
            
            let rightBar = createContainerWithShadow(
                size: CGSize(width: width, height: height),
                cornerRadius: Layout.cornerRadius,
                position: position,
                zPosition: 1
            )
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
        
        // MARK: - Container Creation
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
        
        // MARK: - Overlay Methods
    func showLevelStartOverlay(for level: GameLevel, completion: @escaping () -> Void) {
        guard let scene = scene else { return }
        currentOverlay?.removeFromParent()
        
        let overlaySize = CGSize(width: scene.size.width * 0.7, height: scene.size.height * 0.45)
        let overlay = LevelStartOverlayNode(
            size: overlaySize,
            levelId: level.levelId,
            levelName: level.name,
            startAction: completion  // Cambio: completion -> startAction
        )
        
        scene.addChild(overlay)
        currentOverlay = overlay
        
        overlay.show(in: scene, overlayPosition: .center)  // No necesita OverlayPosition. ya está definido en GameOverlayNode
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

    func showGameOverOverlay(score: Int, onRestart: @escaping () -> Void) {
        guard let scene = scene else { return }
        currentOverlay?.removeFromParent()
        
        let overlaySize = CGSize(width: 400, height: 300)
        let overlay = GameOverOverlayNode(
            size: overlaySize,
            score: score,
            restartAction: onRestart  // Cambio: onRestart -> restartAction
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
    }
