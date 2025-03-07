//
//  MusicBlocksScene.swift
//  MusicBlocks
//
//  Created by Jose R. García on 7/3/25.
//

import SpriteKit
import UIKit
import SwiftUI

class MusicBlocksScene: SKScene, AudioControllerDelegate {
    @Environment(\.screenSize) var screenSize
    
    // MARK: - Managers
    private let audioController = AudioController.sharedInstance
    private let gameManager = GameManager.shared
    private var gameEngine: GameEngine!
    private var blocksManager: BlocksManager!
    private var uiManager: GameUIManager!
    
    // MARK: - Game State
    private var lastUpdateTime: TimeInterval = 0
    
    // MARK: - Lifecycle Methods
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        print("🎬 Scene did move to view")
        
        setupManagers()
        setupGame()
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        print("⏹️ Deteniendo juego")
        audioController.stop()
        blocksManager.stopBlockGeneration()
    }
    
    // MARK: - Setup Methods
    private func setupManagers() {
        // Inicializar UI Manager primero para tener acceso al área principal
        uiManager = GameUIManager(scene: self)
        
        // Obtener dimensiones del área principal
        let (mainAreaWidth, mainAreaHeight) = uiManager.getMainAreaDimensions()
        
        // Inicializar BlocksManager con el área principal
        blocksManager = BlocksManager(
            blockSize: CGSize(
                width: mainAreaWidth * 0.9,
                height: mainAreaHeight * 0.15
            ),
            blockSpacing: mainAreaHeight * 0.02,
            mainAreaNode: uiManager.getMainAreaNode(),
            mainAreaHeight: mainAreaHeight
        )
        
        // Inicializar GameEngine con BlocksManager
        gameEngine = GameEngine(blockManager: blocksManager)
        
        // Configurar el delegado de audio
        audioController.delegate = self
    }
    
    private func setupGame() {
        // Cargar nivel desde el perfil del usuario
        let userProfile = UserProfile.load()
        print("Intentando cargar nivel \(userProfile.statistics.currentLevel)")
        
        if gameManager.loadLevel(userProfile.statistics.currentLevel) {
            if let currentLevel = gameManager.currentLevel {
                startLevel(currentLevel)
            }
        } else {
            print("Error al cargar nivel, intentando cargar tutorial")
            if gameManager.loadLevel(0) {
                if let tutorialLevel = gameManager.currentLevel {
                    startLevel(tutorialLevel)
                }
            }
        }
    }
    
    private func startLevel(_ level: GameLevel) {
        print("Iniciando nivel \(level.levelId): \(level.name)")
        
        // Detener audio y limpiar bloques
        audioController.stop()
        blocksManager.clearBlocks()
        
        // Inicializar el motor del juego
        gameEngine.startNewGame()
        
        // Mostrar overlay de inicio de nivel
        uiManager.showLevelStartOverlay(for: level) { [weak self] in
            self?.startGameplay()
        }
    }
    
    private func startGameplay() {
        print("Iniciando gameplay")
        
        // Iniciar el audio
        Task {
            print("🎤 Iniciando motor de audio...")
            await MainActor.run {
                audioController.start()
                print("✅ Motor de audio iniciado")
            }
        }
        
        // Iniciar generación de bloques
        blocksManager.startBlockGeneration()
        
        print("✅ Gameplay iniciado")
    }
    
    // MARK: - Update Methods
    override func update(_ currentTime: TimeInterval) {
        lastUpdateTime = currentTime
        
        // Actualizar estado del juego
        updateGameState()
        
        // Comprobar posición de bloques
        gameEngine.checkBlocksPosition()
    }
    
    private func updateGameState() {
        // Actualizar indicadores de estabilidad
        uiManager.stabilityIndicatorNode.duration = audioController.stabilityDuration
        uiManager.stabilityCounterNode.duration = audioController.stabilityDuration
        
        // Actualizar UI según estado del juego
        updateGameUI()
    }
    
    private func updateGameUI() {
        uiManager.updateUI(score: gameEngine.score, lives: gameEngine.lives)
        
        switch gameEngine.gameState {
        case .playing:
            handleGameplayState()
        case .gameOver(let reason):
            handleGameOver(reason: reason)
        case .paused:
            break // Manejar pausa si es necesario
        case .countdown:
            break // La cuenta atrás la maneja el overlay
        }
    }
    
    // MARK: - Game State Handling
    private func handleGameplayState() {
        switch gameEngine.noteState {
        case .success(let multiplier, let message):
            uiManager.showSuccessOverlay(multiplier: multiplier, message: message)
        case .wrong:
            uiManager.showFailureOverlay()
        default:
            break
        }
    }
    
    private func handleGameOver(reason: GameEngine.GameOverReason) {
        audioController.stop()
        blocksManager.stopBlockGeneration()
        
        // Actualizar estadísticas del juego
        if let currentLevel = gameManager.currentLevel {
            gameManager.updateGameStatistics(
                levelId: currentLevel.levelId,
                score: gameEngine.score,
                completed: gameEngine.score >= currentLevel.requiredScore
            )
        }
        
        // Mostrar overlay de game over
        uiManager.showGameOverOverlay(score: gameEngine.score) { [weak self] in
            self?.setupGame()
        }
    }
    
    // MARK: - AudioControllerDelegate
    func audioController(_ controller: AudioController, didDetectNote note: String, frequency: Float, amplitude: Float, deviation: Double) {
        // Actualizar indicadores de nota
        uiManager.detectedNoteCounterNode?.currentNote = note
        uiManager.detectedNoteCounterNode?.isActive = true
        uiManager.tuningIndicatorNode.deviation = deviation
        uiManager.tuningIndicatorNode.isActive = true
        
        // Procesar nota detectada
        gameEngine.checkNote(
            currentNote: note,
            deviation: deviation,
            isActive: true
        )
    }
    
    func audioControllerDidDetectSilence(_ controller: AudioController) {
        // Actualizar indicadores visuales
        uiManager.detectedNoteCounterNode?.isActive = false
        uiManager.tuningIndicatorNode.isActive = false
        
        // Procesar silencio
        gameEngine.checkNote(
            currentNote: "-",
            deviation: 0,
            isActive: false
        )
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
