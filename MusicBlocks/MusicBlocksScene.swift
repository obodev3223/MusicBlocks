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
    
    // Add the backgroundPattern property at the class level
    private var backgroundPattern: BackgroundPatternNode!
    
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
            top: 6,
            left: 20,
            bottom: UIScreen.main.bounds.height * 0.05, // Dinámico según la pantalla
            right: 20
        )
        static let cornerRadius: CGFloat = 15
        
        // Espacio entre elementos
        static let verticalSpacing: CGFloat = 20 // Nuevo: espacio vertical entre elementos
        
        // Proporciones de las áreas principales
        static let topBarHeightRatio: CGFloat = 0.08     // 8% de altura
        static let mainAreaHeightRatio: CGFloat = 0.74    // 74% de altura
        static let sideBarWidthRatio: CGFloat = 0.07     // 15% del ancho
        static let mainAreaWidthRatio: CGFloat = 0.75    // 66% del ancho
        static let sideBarHeightRatio: CGFloat = 0.4   // Altura de las barras

        
        // Tamaños relativos de fuente
        static let scoreFontRatio: CGFloat = 0.5         // 50% de la altura de su contenedor
        static let currentNoteFontRatio: CGFloat = 0.3   // 30% de la altura del área principal
        static let targetNoteFontRatio: CGFloat = 0.5    // 50% de la altura de su contenedor
        
        // Nuevas constantes para el diseño 3D
        static let shadowRadius: CGFloat = 8.0
        static let shadowOpacity: Float = 0.8
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

        backgroundPattern = BackgroundPatternNode(size: size)
        backgroundPattern.zPosition = -10 // Asegura que esté detrás de todo
        addChild(backgroundPattern)
        
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
        
        // Posición del área principal para cálculos de espacio
        let mainAreaY = size.height/2 - (Layout.verticalSpacing/2)
        let mainAreaHeight = size.height * Layout.mainAreaHeightRatio
        
        // Se crea el contenedor de la barra lateral izquierda
        let leftBar = createContainerWithShadow(
            size: CGSize(width: width, height: height),
            cornerRadius: Layout.cornerRadius,
            position: leftBarPosition,
            zPosition: 1
        )
        addChild(leftBar)
        
        // Indicador de estabilidad (barra vertical)
        stabilityIndicatorNode = StabilityIndicatorNode(size: CGSize(width: width * 0.6, height: height * 0.9))
        stabilityIndicatorNode.position = CGPoint.zero // Centrado en el contenedor
        stabilityIndicatorNode.zPosition = 10
        leftBar.addChild(stabilityIndicatorNode)
        
        // Distancia de los contadores con el final de las barras
        let leftBarBottom = leftBarPosition.y - height/2
        let counterYPosition = leftBarBottom - 30
        
        // Contador de estabilidad - horizontal y más ancho
        stabilityCounterNode = StabilityCounterNode(size: CGSize(width: width * 2.0, height: 30))
        stabilityCounterNode.position = CGPoint(x: leftBarPosition.x, y: counterYPosition)
        stabilityCounterNode.zPosition = 10
        addChild(stabilityCounterNode)
        
        // Barra derecha - Afinación
        let rightBarPosition = CGPoint(
            x: size.width - Layout.margins.right - width/2,
            y: size.height/2 - (Layout.verticalSpacing/2)
        )
        
        // Se crea el contenedor de la barra lateral derecha
        let rightBar = createContainerWithShadow(
            size: CGSize(width: width, height: height),
            cornerRadius: Layout.cornerRadius,
            position: rightBarPosition,
            zPosition: 1
        )
        addChild(rightBar)
        
        // Indicador de afinación (derecha)
        tuningIndicatorNode = TuningIndicatorNode(size: CGSize(width: width * 0.6, height: height * 0.9))
        tuningIndicatorNode.position = CGPoint.zero // Centrado en el contenedor
        tuningIndicatorNode.zPosition = 10
        rightBar.addChild(tuningIndicatorNode)
        
        // CORREGIDO: Posicionar el contador usando la misma distancia desde la barra derecha
        detectedNoteCounterNode = DetectedNoteCounterNode(size: CGSize(width: width * 2.0, height: 30))
        detectedNoteCounterNode.position = CGPoint(x: rightBarPosition.x, y: counterYPosition)
        detectedNoteCounterNode.zPosition = 10
        addChild(detectedNoteCounterNode)
    }

    // Función auxiliar para crear contenedores con sombra
private func createContainerWithShadow(size: CGSize, cornerRadius: CGFloat, position: CGPoint, zPosition: CGFloat) -> SKNode {
    let container = SKNode()
    container.position = position
    container.zPosition = zPosition
    
    // Nodo para la sombra con efecto de desenfoque
    let shadowNode = SKEffectNode()
    shadowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": Layout.shadowRadius])
    shadowNode.shouldRasterize = true
    shadowNode.shouldEnableEffects = true
    shadowNode.position = Layout.shadowOffset
    container.addChild(shadowNode)
    
    // Forma que representa la sombra
    let shadowShape = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
    shadowShape.fillColor = .black
    shadowShape.strokeColor = .clear
    shadowShape.alpha = CGFloat(Layout.shadowOpacity)
    shadowNode.addChild(shadowShape)
    
    // Nodo principal sin filtro
    let mainShape = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
    mainShape.fillColor = .white
    mainShape.strokeColor = .clear
    mainShape.alpha = Layout.containerAlpha
    mainShape.zPosition = 1 // Se asegura que quede por encima de la sombra
    container.addChild(mainShape)
    
    return container
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
        detectedNoteCounterNode?.currentNote = tunerData.note
        detectedNoteCounterNode?.isActive = tunerData.isActive
        
        // Actualizar indicadores laterales
        stabilityIndicatorNode.duration = audioController.stabilityDuration
        stabilityCounterNode.duration = audioController.stabilityDuration
        
        tuningIndicatorNode.deviation = tunerData.deviation
        tuningIndicatorNode.isActive = tunerData.isActive
    }
    
    private func updateGameUI() {
        // Actualizar puntuación y vidas en la TopBar
        topBarNode?.updateScore(gameEngine.score)
        topBarNode?.updateLives(gameEngine.lives)  // Añadir esta línea para actualizar las vidas
        
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
        // Remove previous overlay if exists
        currentOverlay?.removeFromParent()
        
        // Nuevo tamaño: 350x60
        let overlaySize = CGSize(width: 350, height: 60)
        let overlay = SuccessOverlayNode(size: overlaySize, multiplier: multiplier, message: message)
        addChild(overlay)
        currentOverlay = overlay
        
        // Mostrar en la parte inferior
        overlay.show(in: self, overlayPosition: .bottom)
        
        // Hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak overlay] in
            overlay?.hide()
        }
    }
    
    // Añade el método para mostrar el overlay de fallo:
    private func showFailureOverlay() {
        // Remove previous overlay if exists
        currentOverlay?.removeFromParent()
        
        // Nuevo tamaño: 350x60
        let overlaySize = CGSize(width: 350, height: 60)
        let overlay = FailureOverlayNode(size: overlaySize)
        addChild(overlay)
        currentOverlay = overlay
        
        // Mostrar en la parte inferior
        overlay.show(in: self, overlayPosition: .bottom)
        
        // Hide after 2 seconds
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
        // Asegurarnos que todos los elementos de UI estén configurados antes de actualizar
        if detectedNoteCounterNode == nil {
            // Si por alguna razón no se ha inicializado, lo hacemos aquí
            let safePosition = CGPoint(
                x: min(size.width * 0.9, size.width - DetectedNoteCounterNode.Layout.defaultSize.width),
                y: size.height * 0.3
            )
            detectedNoteCounterNode = DetectedNoteCounterNode.createForRightSideBar(at: safePosition)
            addChild(detectedNoteCounterNode)
        }
        
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
        
        // Remove previous overlay if exists
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

#if DEBUG
import SwiftUI

struct MusicBlocksScene_Previews: PreviewProvider {
    static var previews: some View {
        MusicBlocksSceneView()
            .previewDevice("iPhone 16") // Puedes cambiar el dispositivo para ver diferentes tamaños
    }
}
#endif

