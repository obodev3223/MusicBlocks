//
//  GameSceneScene.swift
//  MusicBlocks
//
//  Created by Jose R. García on 11/2/25.
//

import SpriteKit
import UIKit
import SwiftUI

class MusicBlocksScene: SKScene {
    @Environment(\.screenSize) var screenSize
    
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
        }
    
    // MARK: - Properties
    /// Controladores principales
    let audioController = AudioController.sharedInstance
    private let tunerEngine = TunerEngine.shared
    
    /// Estado del juego
    var score: Int = 0
    var targetNote: TunerEngine.Note?
    var noteMatchTime: TimeInterval = 0
    var isTransitioning: Bool = false
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Configuration Constants
    let requiredMatchTime: TimeInterval = 2.0
    let transitionDelay: TimeInterval = 2.0
    let acceptableDeviation: Double = 10.0

    // MARK: - UI Elements
    /// Etiquetas principales
    var scoreLabel: SKLabelNode!
    var currentNoteLabel: SKLabelNode!
    var targetNoteLabel: SKLabelNode!
    var successOverlay: SKNode!

    /// Indicadores y contadores
    var stabilityIndicatorNode: StabilityIndicatorNode!
    var stabilityCounterNode: StabilityCounterNode!
    var tuningIndicatorNode: TuningIndicatorNode!
    var tuningInfoNode: TuningInfoNode!
    
    private var topBarNode: TopBar?
    
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
        backgroundColor = .lightGray
        
        let safeWidth = size.width - Layout.margins.left - Layout.margins.right
        let safeHeight = size.height - Layout.margins.top - Layout.margins.bottom
        
        // Calcular alturas
        let topBarHeight = safeHeight * Layout.topBarHeightRatio
        let mainAreaHeight = safeHeight * Layout.mainAreaHeightRatio
        let bottomBarHeight = safeHeight * Layout.bottomBarHeightRatio
        
        // Calcular anchos
        let mainAreaWidth = safeWidth * Layout.mainAreaWidthRatio
        let sideBarWidth = safeWidth * Layout.sideBarWidthRatio
        
        // Configurar barras superior e inferior
        setupTopBar(width: safeWidth, height: topBarHeight)
        setupBottomBar(width: safeWidth, height: bottomBarHeight)
        
        // Configurar área principal con ajuste de posición
        setupMainArea(width: mainAreaWidth,
                     height: mainAreaHeight,
                     topBarHeight: topBarHeight)
        
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
        
        topBarNode = TopBar.create(width: width, height: height, position: position)
        if let topBar = topBarNode {
            addChild(topBar)
        }
    }
    
    
    private func setupMainArea(width: CGFloat, height: CGFloat, topBarHeight: CGFloat) {
        let mainArea = SKShapeNode(rectOf: CGSize(width: width, height: height),
                                  cornerRadius: Layout.cornerRadius)
        mainArea.fillColor = .white
        mainArea.strokeColor = .blue
        // Ajustar posición para dejar espacio después de la barra superior
        mainArea.position = CGPoint(
            x: size.width/2,
            y: size.height/2 - (Layout.verticalSpacing/2)
        )
        addChild(mainArea)
        
        currentNoteLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        currentNoteLabel.fontSize = height * Layout.currentNoteFontRatio
        currentNoteLabel.fontColor = .black
        currentNoteLabel.text = "-"
        currentNoteLabel.position = CGPoint(x: 0, y: 0)
        currentNoteLabel.verticalAlignmentMode = .center
        mainArea.addChild(currentNoteLabel)
    }
    
    /// Configura la barra inferior con la nota objetivo
    private func setupBottomBar(width: CGFloat, height: CGFloat) {
        let bottomBar = SKShapeNode(rectOf: CGSize(width: width, height: height),
                                    cornerRadius: Layout.cornerRadius)
        bottomBar.fillColor = .white
        bottomBar.strokeColor = .blue
        bottomBar.position = CGPoint(x: size.width/2,
                                     y: Layout.margins.bottom + height/2)
        addChild(bottomBar)
        
        targetNoteLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        targetNoteLabel.fontSize = height * 0.4 // Tamaño relativo
        targetNoteLabel.fontColor = .black
        targetNoteLabel.text = "Nota objetivo: -"
        targetNoteLabel.position = CGPoint(x: 0, y: -height * 0.2)
        bottomBar.addChild(targetNoteLabel)
    }
    
    /// Configura las barras laterales con indicadores
    private func setupSideBars(width: CGFloat, height: CGFloat, topBarHeight: CGFloat) {
            // Barra izquierda
            setupSideBar(width: width, height: height, isLeft: true, topBarHeight: topBarHeight)
            // Barra derecha
            setupSideBar(width: width, height: height, isLeft: false, topBarHeight: topBarHeight)
        }
    
    /// Configura una barra lateral individual
    private func setupSideBar(width: CGFloat, height: CGFloat, isLeft: Bool, topBarHeight: CGFloat) {
            let xPosition = isLeft ?
                Layout.margins.left + width/2 :
                size.width - Layout.margins.right - width/2
            
            // Ajustar posición vertical para alinear con el área principal
            let yPosition = size.height/2 - (Layout.verticalSpacing/2)
            
            // Crear el contenedor principal
            let sideBar = SKShapeNode(rectOf: CGSize(width: width, height: height),
                                     cornerRadius: Layout.cornerRadius)
            sideBar.fillColor = .white
            sideBar.strokeColor = .blue
            sideBar.position = CGPoint(x: xPosition, y: yPosition)
            addChild(sideBar)
            
            // El resto del código del setupSideBar permanece igual...
            let indicatorSize = CGSize(width: width * 0.9, height: height * 0.9)
            
            if isLeft {
                stabilityIndicatorNode = StabilityIndicatorNode(size: indicatorSize)
                stabilityIndicatorNode.position = CGPoint(x: 0, y: 0)
                sideBar.addChild(stabilityIndicatorNode)
            } else {
                tuningIndicatorNode = TuningIndicatorNode(size: indicatorSize)
                tuningIndicatorNode.position = CGPoint(x: 0, y: 0)
                sideBar.addChild(tuningIndicatorNode)
            }
            
            setupSideBarExtension(width: width, height: height * Layout.sideBarExtensionHeightRatio,
                                parent: sideBar, isLeft: isLeft)
        }
    
    /// Configura la extensión inferior de una barra lateral

    private func setupSideBarExtension(width: CGFloat, height: CGFloat, parent: SKShapeNode, isLeft: Bool) {
        let extensionNode = SKShapeNode(rectOf: CGSize(width: width, height: height),
                                        cornerRadius: Layout.cornerRadius)
        extensionNode.fillColor = .white
        extensionNode.strokeColor = .blue
        extensionNode.position = CGPoint(x: 0,
                                         y: -parent.frame.height/2 - height/2)
        parent.addChild(extensionNode)
        
        // Calcular dimensiones para los contadores
        let counterSize = CGSize(width: width * 0.9, height: height * 0.8)
        
        if isLeft {
            // Configurar contador de estabilidad
            stabilityCounterNode = StabilityCounterNode(size: counterSize)
            stabilityCounterNode.position = CGPoint(x: 0, y: 0)
            extensionNode.addChild(stabilityCounterNode)
        } else {
            // Configurar información de afinación
            tuningInfoNode = TuningInfoNode(size: counterSize)
            tuningInfoNode.position = CGPoint(x: 0, y: 0)
            extensionNode.addChild(tuningInfoNode)
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
        
        // Actualizar etiquetas principales
        currentNoteLabel.text = tunerData.note
        currentNoteLabel.fontColor = getDeviationColor(deviation: tunerData.deviation)
        
        // Actualizar indicadores laterales
        stabilityIndicatorNode.duration = audioController.stabilityDuration
        stabilityCounterNode.duration = audioController.stabilityDuration
        
        tuningIndicatorNode.deviation = tunerData.deviation
        tuningIndicatorNode.isActive = tunerData.isActive
        
        tuningInfoNode.frequency = tunerData.frequency
        tuningInfoNode.deviation = tunerData.deviation
        tuningInfoNode.isActive = tunerData.isActive
    }
    
    func checkNoteAndUpdateScore(deltaTime: TimeInterval) {
        guard let targetNote = targetNote,
              let currentNote = tunerEngine.parseNote(audioController.tunerData.note),
              audioController.tunerData.isActive else {
            noteMatchTime = 0
            return
        }
        
        if currentNote == targetNote &&
            abs(audioController.tunerData.deviation) <= acceptableDeviation {
            noteMatchTime += deltaTime
            
            if noteMatchTime >= requiredMatchTime && !isTransitioning {
                score += 1
                topBarNode?.updateScore(score)
                isTransitioning = true
                showSuccessOverlay()
                
                let wait = SKAction.wait(forDuration: transitionDelay)
                let newNoteAction = SKAction.run { [weak self] in
                    self?.generateNewNote()
                }
                run(SKAction.sequence([wait, newNoteAction]))
            }
        } else {
            noteMatchTime = 0
        }
    }
    
    // MARK: - Helper Methods
    func showSuccessOverlay() {
        successOverlay.isHidden = false
        successOverlay.setScale(0.5)
        let appear = SKAction.scale(to: 1.0, duration: 0.3)
        successOverlay.run(appear)
        
        let wait = SKAction.wait(forDuration: 1.0)
        let hideOverlay = SKAction.run { [weak self] in
            self?.successOverlay.isHidden = true
        }
        successOverlay.run(SKAction.sequence([wait, hideOverlay]))
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
    
    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        
        updateUI()
        checkNoteAndUpdateScore(deltaTime: deltaTime)
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


