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
    
    private func createContainerWithShadow(size: CGSize, cornerRadius: CGFloat) -> (container: SKNode, shape: SKShapeNode) {
        // Crear el nodo contenedor
        let containerNode = SKNode()
        
        // Crear el nodo de sombra
        let shadowNode = SKEffectNode()
        let shadowShape = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        shadowShape.fillColor = .black
        shadowShape.strokeColor = .clear
        shadowShape.alpha = CGFloat(Layout.shadowOpacity)
        shadowNode.addChild(shadowShape)
        shadowNode.shouldRasterize = true
        shadowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": Layout.shadowRadius])
        shadowNode.position = Layout.shadowOffset
        
        // Crear el nodo principal
        let mainShape = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        mainShape.fillColor = .white
        mainShape.strokeColor = .clear
        mainShape.alpha = Layout.containerAlpha
        
        // Añadir los nodos en orden (primero la sombra, luego el contenido)
        containerNode.addChild(shadowNode)
        containerNode.addChild(mainShape)
        
        return (containerNode, mainShape)
    }
    
    // MARK: - Layout Configuration
    private struct Layout {
        /// Márgenes de seguridad para el contenido
        static let margins = UIEdgeInsets(
            top: 8,
            left: 10,
            bottom: UIScreen.main.bounds.height * 0.05, // Dinámico según la pantalla
            right: 10
        )
        static let cornerRadius: CGFloat = 15
        
        // Espacio entre elementos
        static let verticalSpacing: CGFloat = 20 // Nuevo: espacio vertical entre elementos
        
        // Proporciones de las áreas principales
        static let topBarHeightRatio: CGFloat = 0.08     // 8% de altura
        static let mainAreaHeightRatio: CGFloat = 0.74    // 74% de altura
        static let bottomBarHeightRatio: CGFloat = 0.08   // 8% de altura
        static let sideBarWidthRatio: CGFloat = 0.08     // 15% del ancho
        static let mainAreaWidthRatio: CGFloat = 0.66    // 66% del ancho
        static let sideBarHeightRatio: CGFloat = 0.444   // Nuevo: 74% * 0.6 = ~44.4% (40% más corto)
        static let sideBarExtensionHeightRatio: CGFloat = 0.15
        
        // Tamaños relativos de fuente
        static let scoreFontRatio: CGFloat = 0.5         // 50% de la altura de su contenedor
        static let currentNoteFontRatio: CGFloat = 0.3   // 30% de la altura del área principal
        static let targetNoteFontRatio: CGFloat = 0.5    // 50% de la altura de su contenedor
        
        // Nuevas constantes para el diseño 3D
        static let shadowRadius: CGFloat = 4.0
        static let shadowOpacity: Float = 0.2
        static let shadowOffset = CGPoint(x: 0, y: -2)
        static let containerAlpha: CGFloat = 0.95
    }
    
    // MARK: - Properties
    /// Controladores principales
    let audioController = AudioController.sharedInstance
    private let tunerEngine = TunerEngine.shared
    private let gameEngine = GameEngine()
    
    /// Estado del juego
    var score: Int = 0
    private var lastUpdateTime: TimeInterval = 0
    private let acceptableDeviation: Double = 10.0
    
    
    // MARK: - UI Elements
    /// Etiquetas principales
    var scoreLabel: SKLabelNode!
    var targetNoteLabel: SKLabelNode!
    var successOverlay: SKNode!
    
    /// Indicadores y contadores
    var stabilityIndicatorNode: StabilityIndicatorNode!
    var stabilityCounterNode: StabilityCounterNode!
    var tuningIndicatorNode: TuningIndicatorNode!
    private var tuningCounterNode: TuningCounterNode!
    private var topBarNode: TopBar?
    private var currentOverlay: GameOverlayNode?
    var detectedNoteCounterNode: DetectedNoteCounterNode!
    private var floatingTargetNote: FloatingTargetNoteNode!
    
    // MARK: - Lifecycle Methods
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Reiniciar el audio cuando la escena se carga
        Task {
            audioController.stop()
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 segundos
            await MainActor.run {
                audioController.start()
            }
        }
        
        // Configurar toda la escena
        setupScene()
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        audioController.stop()
    }
    
    private func setupScene() {
        backgroundColor = .white
        
        let safeWidth = size.width - Layout.margins.left - Layout.margins.right
        let safeHeight = size.height - Layout.margins.top - Layout.margins.bottom
        
        // Calcular alturas
        let topBarHeight = safeHeight * Layout.topBarHeightRatio
        let mainAreaHeight = safeHeight * Layout.mainAreaHeightRatio

        
        // Calcular anchos
        let mainAreaWidth = safeWidth * Layout.mainAreaWidthRatio
        let sideBarWidth = safeWidth * Layout.sideBarWidthRatio
        
        // Configurar barras superior e inferior
        setupTopBar(width: safeWidth, height: topBarHeight)

        
        // Configurar área principal con ajuste de posición
        setupMainArea(width: mainAreaWidth,
                      height: mainAreaHeight,
                      topBarHeight: topBarHeight)
        
        //Configurar la nota aleatoria flotante
        setupFloatingTargetNote(width: size.width)
        
        // Configurar barras laterales (40% más cortas)
        let sideBarHeight = safeHeight * Layout.sideBarHeightRatio
        setupSideBars(width: sideBarWidth,
                      height: sideBarHeight,
                      topBarHeight: topBarHeight)
        
        // Configurar overlay de éxito
        setupSuccessOverlay(size: CGSize(width: mainAreaWidth * 0.5,
                                         height: safeHeight * 0.25))
        
        setupAndStart()
    }
    
    
    // Configura la barra superior con la puntuación
    private func setupTopBar(width: CGFloat, height: CGFloat) {
        let safeAreaTop = view?.safeAreaInsets.top ?? 0
        let position = CGPoint(
            x: size.width / 2,
            y: size.height - safeAreaTop - height / 2
        )
        
        let (containerNode, _) = createContainerWithShadow(
            size: CGSize(width: width, height: height),
            cornerRadius: Layout.cornerRadius
        )
        containerNode.position = position
        addChild(containerNode)
        
        topBarNode = TopBar.create(width: width, height: height, position: position)
        if let topBar = topBarNode {
            addChild(topBar)
        }
    }
    
    
    private func setupMainArea(width: CGFloat, height: CGFloat, topBarHeight: CGFloat) {
        let containerNode = createContainerWithShadow(
            size: CGSize(width: width, height: height),
            cornerRadius: Layout.cornerRadius,
            position: CGPoint(
                x: size.width/2,
                y: size.height/2 - (Layout.verticalSpacing/2)
            ),
            zPosition: 1
        )
        addChild(containerNode)
    }
    

    
    private func setupFloatingTargetNote(width: CGFloat) {
        floatingTargetNote = FloatingTargetNoteNode(width: width)
        
        // Posicionar el panel flotante encima del área principal
        let yPosition = size.height/2 + Layout.verticalSpacing * 2
        floatingTargetNote.position = CGPoint(
            x: size.width/2,
            y: yPosition
        )
        
        addChild(floatingTargetNote)
    }
    
    /// Configura las barras laterales con indicadores
    private func setupSideBars(width: CGFloat, height: CGFloat, topBarHeight: CGFloat) {
        // Barra izquierda - Estabilidad
        let leftBarPosition = CGPoint(
            x: Layout.margins.left + width/2,
            y: size.height/2 - (Layout.verticalSpacing/2)
        )
        
        let leftBar = createContainerWithShadow(
            size: CGSize(width: width, height: height),
            cornerRadius: Layout.cornerRadius,
            position: leftBarPosition,
            zPosition: 1
        )
        addChild(leftBar)
        
        // Indicadores de estabilidad (izquierda)
        stabilityIndicatorNode = StabilityIndicatorNode(size: CGSize(width: width * 0.8, height: height * 0.3))
        stabilityIndicatorNode.position = CGPoint(x: leftBarPosition.x, y: leftBarPosition.y + height * 0.2)
        stabilityIndicatorNode.zPosition = 10
        addChild(stabilityIndicatorNode)
        
        stabilityCounterNode = StabilityCounterNode(size: CGSize(width: width * 0.8, height: height * 0.3))
        stabilityCounterNode.position = CGPoint(x: leftBarPosition.x, y: leftBarPosition.y - height * 0.2)
        stabilityCounterNode.zPosition = 10
        addChild(stabilityCounterNode)
        
        // Barra derecha - Afinación
        let rightBarPosition = CGPoint(
            x: size.width - Layout.margins.right - width/2,
            y: size.height/2 - (Layout.verticalSpacing/2)
        )
        
        let rightBar = createContainerWithShadow(
            size: CGSize(width: width, height: height),
            cornerRadius: Layout.cornerRadius,
            position: rightBarPosition,
            zPosition: 1
        )
        addChild(rightBar)
        
        // Indicadores de afinación (derecha)
        tuningIndicatorNode = TuningIndicatorNode(size: CGSize(width: width * 0.8, height: height * 0.3))
        tuningIndicatorNode.position = CGPoint(x: rightBarPosition.x, y: rightBarPosition.y + height * 0.2)
        tuningIndicatorNode.zPosition = 10
        addChild(tuningIndicatorNode)
        
        tuningCounterNode = TuningCounterNode(size: CGSize(width: width * 0.8, height: height * 0.3))
        tuningCounterNode.position = CGPoint(x: rightBarPosition.x, y: rightBarPosition.y - height * 0.2)
        tuningCounterNode.zPosition = 10
        addChild(tuningCounterNode)
    }

    // Función auxiliar para crear contenedores con sombra
    private func createContainerWithShadow(size: CGSize, cornerRadius: CGFloat, position: CGPoint, zPosition: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = zPosition
        
        // Efecto de sombra
        let effectNode = SKEffectNode()
        effectNode.filter = CIFilter(
            name: "CIGaussianBlur",
            parameters: ["inputRadius": 3.0]
        )
        effectNode.shouldRasterize = true
        effectNode.shouldEnableEffects = true
        effectNode.zPosition = -1
        container.addChild(effectNode)
        
        // Forma del contenedor
        let shape = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        shape.fillColor = .white
        shape.strokeColor = .clear
        shape.alpha = Layout.containerAlpha
        effectNode.addChild(shape)
        
        return container
    }
    
    private func setupSideBar(width: CGFloat, height: CGFloat, isLeft: Bool, topBarHeight: CGFloat) {
        let xPosition = isLeft ?
            Layout.margins.left + width/2 :
            size.width - Layout.margins.right - width/2
        
        let yPosition = size.height/2 - (Layout.verticalSpacing/2)
        
        let (containerNode, mainShape) = createContainerWithShadow(
            size: CGSize(width: width, height: height),
            cornerRadius: Layout.cornerRadius
        )
        containerNode.position = CGPoint(x: xPosition, y: yPosition)
        addChild(containerNode)
        
        let indicatorSize = CGSize(width: width * 0.9, height: height * 0.9)
        
        if isLeft {
            stabilityIndicatorNode = StabilityIndicatorNode(size: indicatorSize)
            stabilityIndicatorNode.position = CGPoint(x: 0, y: 0)
            mainShape.addChild(stabilityIndicatorNode)
        } else {
            tuningIndicatorNode = TuningIndicatorNode(size: indicatorSize)
            tuningIndicatorNode.position = CGPoint(x: 0, y: 0)
            mainShape.addChild(tuningIndicatorNode)
        }
        
        setupSideBarExtension(width: width, height: height * Layout.sideBarExtensionHeightRatio,
                             parent: mainShape, isLeft: isLeft)
    }
    
    /// Configura la extensión inferior de una barra lateral
    private func setupSideBarExtension(width: CGFloat, height: CGFloat, parent: SKShapeNode, isLeft: Bool) {
        // Aumentar la altura para acomodar el DetectedNoteCounter
        let totalHeight = height * 1.5 // Ajustamos la altura total para acomodar el nuevo elemento
        
        let (containerNode, mainShape) = createContainerWithShadow(
            size: CGSize(width: width, height: totalHeight),
            cornerRadius: Layout.cornerRadius
        )
        containerNode.position = CGPoint(
            x: 0,
            y: -parent.frame.height/2 - totalHeight/2
        )
        parent.addChild(containerNode)
        
        if !isLeft {
            // Configurar DetectedNoteCounterNode
            let noteCounterHeight = totalHeight * 0.3
            let noteCounterSize = CGSize(width: width * 0.9, height: noteCounterHeight)
            detectedNoteCounterNode = DetectedNoteCounterNode(size: noteCounterSize)
            detectedNoteCounterNode.position = CGPoint(x: 0, y: totalHeight * 0.1)
            mainShape.addChild(detectedNoteCounterNode)
            
            // Configurar TuningCounterNode
            let tuningCounterSize = CGSize(width: width * 0.9, height: totalHeight * 0.6)
            tuningCounterNode = TuningCounterNode(size: tuningCounterSize)
            tuningCounterNode.position = CGPoint(x: 0, y: -totalHeight * 0.2)
            mainShape.addChild(tuningCounterNode)
        } else {
            // Configurar contador de estabilidad
            let counterSize = CGSize(width: width * 0.9, height: totalHeight * 0.8)
            stabilityCounterNode = StabilityCounterNode(size: counterSize)
            stabilityCounterNode.position = CGPoint(x: 0, y: 0)
            mainShape.addChild(stabilityCounterNode)
        }
    }
    
    /// Configura el overlay de éxito
    private func setupSuccessOverlay(size: CGSize) {
        successOverlay = SKNode()
        
        let overlayBackground = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        overlayBackground.fillColor = .white
        overlayBackground.strokeColor = .clear
        overlayBackground.position = .zero
        
        let checkmarkLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        checkmarkLabel.fontSize = size.height * 0.3
        checkmarkLabel.fontColor = .green
        checkmarkLabel.text = "✔️"
        checkmarkLabel.position = CGPoint(x: 0, y: size.height * 0.1)
        
        let perfectLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        perfectLabel.fontSize = size.height * 0.15
        perfectLabel.fontColor = .green
        perfectLabel.text = "¡Perfecto!"
        perfectLabel.position = CGPoint(x: 0, y: -size.height * 0.2)
        
        successOverlay.addChild(overlayBackground)
        successOverlay.addChild(checkmarkLabel)
        successOverlay.addChild(perfectLabel)
        successOverlay.position = CGPoint(x: size.width/2, y: size.height/2)
        successOverlay.isHidden = true
        
        addChild(successOverlay)
    }
    
    
    // MARK: - Update Methods
    private func updateUI() {
        let tunerData = audioController.tunerData
                
        // Actualizar el contador de notas detectadas
        detectedNoteCounterNode.currentNote = tunerData.note
        detectedNoteCounterNode.isActive = tunerData.isActive
        
        // Actualizar indicadores laterales
        stabilityIndicatorNode.duration = audioController.stabilityDuration
        stabilityCounterNode.duration = audioController.stabilityDuration
        
        tuningIndicatorNode.deviation = tunerData.deviation
        tuningIndicatorNode.isActive = tunerData.isActive
        
        tuningCounterNode.frequency = tunerData.frequency
        tuningCounterNode.deviation = tunerData.deviation
        tuningCounterNode.isActive = tunerData.isActive
    }
    
    private func updateGameUI() {
        // Actualizar puntuación
        topBarNode?.updateScore(gameEngine.score)
        
        // Actualizar nota objetivo en el panel flotante
        floatingTargetNote.targetNote = gameEngine.targetNote
        
        // Animar el panel según el estado
        switch gameEngine.noteState {
        case .waiting, .correct:
            floatingTargetNote.animate(scale: 1.0, opacity: 1.0)
        case .wrong:
            floatingTargetNote.animate(scale: 0.95, opacity: 0.7)
        case .success:
            floatingTargetNote.animate(scale: 1.1, opacity: 1.0)
        }
        
        // Actualizar estado visual
        switch gameEngine.noteState {
        case .waiting:
            successOverlay.isHidden = true
            
        case .correct(let deviation):
            successOverlay.isHidden = true
            
        case .wrong:
            showFailureOverlay()
            
        case .success(let multiplier, let message):
            showSuccessOverlay(multiplier: multiplier, message: message)
        }
        
        // Manejar game over si es necesario
        if gameEngine.gameState == .gameOver {
            handleGameOver()
        }
    }
    
    func checkNoteAndUpdateScore(deltaTime: TimeInterval) {
        let tunerData = audioController.tunerData
        gameEngine.checkNote(
            currentNote: tunerData.note,
            deviation: tunerData.deviation,
            isActive: tunerData.isActive
        )
        
        // Actualizar la UI según el estado del juego
        updateGameUI()
    }
    
    // MARK: - Helper Methods
    private func showSuccessOverlay(multiplier: Int, message: String) {
        // Eliminar overlay anterior si existe
        currentOverlay?.removeFromParent()
        
        let overlaySize = CGSize(width: 300, height: 150)
        let overlay = SuccessOverlayNode(size: overlaySize, multiplier: multiplier, message: message)
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(overlay)
        currentOverlay = overlay
        
        overlay.show(in: self)
        
        // Ocultar después de 2 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak overlay] in
            overlay?.hide()
        }
    }
    
    // Añade el método para mostrar el overlay de fallo:
    private func showFailureOverlay() {
        // Eliminar overlay anterior si existe
        currentOverlay?.removeFromParent()
        
        let overlaySize = CGSize(width: 300, height: 150)
        let overlay = FailureOverlayNode(size: overlaySize)
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(overlay)
        currentOverlay = overlay
        
        overlay.show(in: self)
        
        // Ocultar después de 2 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak overlay] in
            overlay?.hide()
        }
    }
    
    
    func getDeviationColor(deviation: Double) -> SKColor {
        guard audioController.tunerData.isActive else {
            return .gray
        }
        
        let absDeviation = abs(deviation)
        if absDeviation <= acceptableDeviation {
            return .green
        } else if absDeviation < 15 {
            return .orange
        } else {
            return .red
        }
    }
    
    // MARK: - Game Setup & Control
    private func setupAndStart() {
        // Iniciar el audio
        audioController.start()
        
        // Iniciar nuevo juego
        gameEngine.startNewGame()
        
        // Actualizar la UI inicial
        updateGameUI()
    }
    
    private func updateGameState() {
        // Actualizar puntuación
        topBarNode?.updateScore(gameEngine.score)
        
        // Actualizar nota objetivo si existe
        if let targetNote = gameEngine.targetNote {
            targetNoteLabel.text = "Nota objetivo: \(targetNote.fullName)"
        } else {
            targetNoteLabel.text = "Nota objetivo: -"
        }
    }
    
    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        
        // Actualizar la UI general (indicadores de estabilidad, etc.)
        updateUI()
        
        // Actualizar el estado del juego
        checkNoteAndUpdateScore(deltaTime: deltaTime)
    }
    
    private func handleGameState() {
        if gameEngine.gameState == .gameOver {
            handleGameOverState()
        }
        // El estado .playing ya se maneja en updateGameUI
    }
        
    private func handleGameOverState() {
        // Mostrar pantalla de game over
        // Por ahora solo detenemos el audio
        audioController.stop()
    }
    
    private func handleGameOver() {
        audioController.stop()
        
        // Eliminar overlay anterior si existe
        currentOverlay?.removeFromParent()
        
        let overlaySize = CGSize(width: 400, height: 300)
        let overlay = GameOverOverlayNode(size: overlaySize, score: gameEngine.score) { [weak self] in
            self?.gameEngine.startNewGame()
            self?.audioController.start()
            self?.currentOverlay?.hide()
        }
        
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(overlay)
        currentOverlay = overlay
        
        overlay.show(in: self)
    }
    
}

// Extensión para obtener el tamaño de la pantalla
private struct ScreenSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = UIScreen.main.bounds.size
}

// MARK: - Environment Values
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
                .ignoresSafeArea() // Elimina cualquier margen
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ocupa toda la pantalla
                .navigationBarHidden(true) // Ocultar barra de navegación
        }
    }
}


