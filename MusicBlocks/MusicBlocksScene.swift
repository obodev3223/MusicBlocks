//
//  MusicBlocksScene.swift
//  MusicBlocks
//
//  Created by Jose R. García on 14/3/25.
//

import SpriteKit
import UIKit
import SwiftUI

class MusicBlocksScene: SKScene  {
    @Environment(\.screenSize) var screenSize
    
    // MARK: - Managers
    private let audioController = AudioController.sharedInstance
    private let gameManager = GameManager.shared
    private var gameEngine: GameEngine!
    private var blocksManager: BlocksManager!
    private var uiManager: GameUIManager!
    var objectiveTracker: LevelObjectiveTracker?
    
    // MARK: - Game State
    private var lastUpdateTime: TimeInterval = 0
    private var lastTimeUpdate: TimeInterval = 0
    private let timeUpdateInterval: TimeInterval = 1.0 // Actualizar cada segundo
    
    private var isProcessingNotification = false
    
    // MARK: - Lifecycle Methods
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        print("🎬 Scene did move to view")
        
        setupManagers()
        setupGame()
        
        // Añadir observador para actualizaciones de todos los datos del juego
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGameDataUpdate(_:)),
            name: NSNotification.Name("GameDataUpdated"),
            object: nil
        )
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        print("⏹️ Deteniendo juego")
        
        // Detener todos los sistemas
        audioController.stop()
        blocksManager.stopBlockGeneration()
        
        // Eliminar todos los observadores
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Score Update Handler
    @objc func handleGameDataUpdate(_ notification: Notification) {
        // Evitar procesamiento recursivo
        if isProcessingNotification { return }
        isProcessingNotification = true
        
        // Extraer datos de la notificación
        let userData = notification.userInfo ?? [:]
        
        // Debug solo si hay cambios significativos
        if let score = userData["score"] as? Int, let lives = userData["lives"] as? Int {
            print("🔄 handleGameDataUpdate: score=\(score), lives=\(lives)")
        }
        
        // 1. Actualizar UI básica
        let score = userData["score"] as? Int ?? gameEngine.score
        let lives = userData["lives"] as? Int ?? gameEngine.lives
        uiManager.updateUI(score: score, lives: lives)
        
        // 2. Actualizar objetivos si es necesario
        if let progress = objectiveTracker?.getCurrentProgress() {
            uiManager.rightTopBarNode?.updateObjectiveInfo(with: progress)
        }
        
        // 3. Manejar overlays según el estado de la notificación
        // Solo mostrar overlays si estamos en modo de juego y el juego no está pausado ni en countdown
        if case .playing = gameEngine.gameState {
            if let noteState = userData["noteState"] as? String {
                switch noteState {
                case "success":
                    let multiplier = userData["multiplier"] as? Int ?? 1
                    let message = userData["message"] as? String ?? "¡Bien!"
                    print("🎮 Mostrando overlay de éxito: \(message), multiplier: \(multiplier)")
                    
                    // Show success overlay immediately without any delay
                    DispatchQueue.main.async {
                        self.uiManager.showSuccessOverlay(multiplier: multiplier, message: message)
                    }
                    
                case "wrong":
                    print("🎮 Mostrando overlay de fallo")
                    
                    // Show failure overlay immediately without any delay
                    DispatchQueue.main.async {
                        self.uiManager.showFailureOverlay()
                    }
                    
                default:
                    break
                }
            }
        }
        
        // 4. Manejar game over como caso especial
        if let gameOver = userData["gameOver"] as? Bool, gameOver {
            // Asegurarse de detener AudioController antes de mostrar el overlay
            audioController.stop()
            
            let isVictory = userData["isVictory"] as? Bool ?? false
            let reasonText = userData["reason"] as? String ?? ""
            
            var message: String
            switch reasonText {
            case "victory":
                message = "¡Nivel completado!"
            case "noLives":
                message = "¡Te has quedado sin vidas!"
            case "blocksOverflow":
                message = "¡Los bloques han alcanzado la zona de peligro!"
            default:
                message = "Fin del juego"
            }
            
            print("🎮 Mostrando overlay de fin de juego: \(message)")
            
            // Pequeño retraso para asegurar que todo esté detenido antes de mostrar el overlay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                
                self.uiManager.showGameOverOverlay(
                    score: score,
                    message: message,
                    isVictory: isVictory,
                    onRestart: { [weak self] in
                        self?.setupGame()
                    },
                    onMenu: { [weak self] in
                        self?.navigateToMainMenu()
                    }
                )
            }
        }
           
           isProcessingNotification = false
       }
    
    // MARK: - Setup Methods
    private func setupManagers() {
        // Paso 1: Cargar el nivel primero
        let userProfile = UserProfile.load()
        let targetLevelId = userProfile.statistics.currentLevel
        
        if !gameManager.loadLevel(targetLevelId) {
            print("⚠️ Error al cargar nivel \(targetLevelId), cargando tutorial...")
            _ = gameManager.loadLevel(0)
        }
        
        // Paso 2: Crear un único objectiveTracker y compartirlo
        if let currentLevel = gameManager.currentLevel {
            objectiveTracker = LevelObjectiveTracker(level: currentLevel)
        }
        
        // Paso 3: Inicializar UI Manager (con el objectiveTracker ya creado)
        uiManager = GameUIManager(scene: self)
        uiManager.objectiveTracker = objectiveTracker
        
        // Paso 4: Obtener dimensiones del área principal (después de crear el UI Manager)
        let (mainAreaWidth, mainAreaHeight) = uiManager.getMainAreaDimensions()
        
        // Paso 5: Inicializar BlocksManager
        blocksManager = BlocksManager(
            blockSize: CGSize(width: mainAreaWidth * 0.9, height: mainAreaHeight * 0.15),
            blockSpacing: mainAreaHeight * 0.02,
            mainAreaNode: uiManager.getMainAreaNode(),
            mainAreaHeight: mainAreaHeight
        )
        
        // Paso 6: Inicializar GameEngine con todas las dependencias
        gameEngine = GameEngine(blockManager: blocksManager)
        gameEngine.objectiveTracker = objectiveTracker
        
        // Paso 7: Configurar delegado de audio
        audioController.delegate = gameEngine
        
        // Paso 8: Actualizar UI con valores iniciales
        if let currentLevel = gameManager.currentLevel {
            uiManager.updateUI(score: 0, lives: currentLevel.lives.initial)
        }
        
        // Añadir observadores para las notificaciones de audio
           NotificationCenter.default.addObserver(
               self,
               selector: #selector(handleAudioTunerUpdate(_:)),
               name: .audioTunerDataUpdated,
               object: nil
           )
           
           NotificationCenter.default.addObserver(
               self,
               selector: #selector(handleAudioStabilityUpdate(_:)),
               name: .audioStabilityUpdated,
               object: nil
           )
        
        print("✅ Managers inicializados correctamente")
    }
    
    private func setupGame() {
        // Cargar nivel desde el perfil del usuario, pero solo si no está ya cargado
        // o si estamos forzando una nueva carga
        let userProfile = UserProfile.load()
        let targetLevelId = userProfile.statistics.currentLevel
        
        // Check if the player has completed all levels
        if userProfile.hasCompletedAllLevels {
            print("🏆 El jugador ha completado todos los niveles disponibles")
            // Show the congratulations overlay with the final score
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                // Get the last score or use a default value
                let finalScore = GameManager.shared.highScores[targetLevelId - 1] ?? 1000
                self.uiManager.showAllLevelsCompletedOverlay(
                    score: finalScore,
                    onRestart: { [weak self] in
                        // Reset the flag and load the first level again
                        var updatedProfile = userProfile
                        updatedProfile.hasCompletedAllLevels = false
                        updatedProfile.statistics.currentLevel = 0 // Back to tutorial
                        updatedProfile.save()
                        self?.setupGame()
                    },
                    onMenu: { [weak self] in
                        self?.navigateToMainMenu()
                    }
                )
            }
            return
        }
        
        // More detailed logging for level loading
        print("📋 Intentando cargar nivel \(targetLevelId) (nivel actual: \(gameManager.currentLevel?.levelId ?? -1))")
        
        // Solo cargar si es necesario
        if gameManager.currentLevel == nil || gameManager.currentLevel?.levelId != targetLevelId {
            print("🔄 Necesario cargar nuevo nivel...")
            
            if gameManager.loadLevel(targetLevelId) {
                print("✅ Nivel \(targetLevelId) cargado correctamente")
            } else {
                print("⚠️ Error al cargar nivel \(targetLevelId), intentando cargar tutorial")
                if gameManager.loadLevel(0) {
                    print("✅ Tutorial (nivel 0) cargado como respaldo")
                } else {
                    print("❌ Error crítico: No se pudo cargar ningún nivel")
                    return
                }
            }
            
            // Crear un nuevo tracker para el nivel cargado
            if let currentLevel = gameManager.currentLevel {
                print("🎯 Creando nuevo tracker de objetivos para nivel \(currentLevel.levelId)")
                objectiveTracker = LevelObjectiveTracker(level: currentLevel)
                gameEngine.objectiveTracker = objectiveTracker
            }
        } else {
            print("ℹ️ Usando nivel ya cargado: \(gameManager.currentLevel?.levelId ?? -1)")
            
            // Resetear el tracker existente si ya existe uno
            if objectiveTracker != nil {
                print("🔄 Reseteando tracker de objetivos existente")
                objectiveTracker?.resetProgress()
            } else if let currentLevel = gameManager.currentLevel {
                print("🎯 Creando tracker de objetivos para nivel ya cargado")
                objectiveTracker = LevelObjectiveTracker(level: currentLevel)
                gameEngine.objectiveTracker = objectiveTracker
            }
        }
        
        // Iniciar el nivel si está cargado
        if let currentLevel = gameManager.currentLevel {
            startLevel(currentLevel)
        }
    }
    
    private func startLevel(_ level: GameLevel) {
        print("Iniciando nivel \(level.levelId): \(level.name)")
        
        // Detener audio y limpiar bloques
        audioController.stop()
        blocksManager.clearBlocks()
        
        // Configurar UI antes del overlay
        if let tracker = objectiveTracker {
            uiManager.configureTopBars(withLevel: level, objectiveTracker: tracker)
        }
        uiManager.updateUI(score: 0, lives: level.lives.initial)
        
        // Mostrar overlay de inicio de nivel
        uiManager.showLevelStartOverlay(for: level) { [weak self] in
            self?.startGameplay()
        }
    }
    
    private func startGameplay() {
        print("🎮 Iniciando gameplay")
        
        // IMPORTANTE: Pausar el procesamiento de notificaciones durante la inicialización
        isProcessingNotification = true
        
        // Asegurar que todos los managers estén correctamente enlazados
        if objectiveTracker !== gameEngine.objectiveTracker {
            print("⚠️ Corrigiendo desincronización en objectiveTracker")
            gameEngine.objectiveTracker = objectiveTracker
        }
        
        // Usar SKActions para una secuencia controlada de inicialización
        let startGameEngineAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.gameEngine.startNewGame()
            print("✅ Motor de juego iniciado")
        }
        
        let waitForEngineAction = SKAction.wait(forDuration: 0.8)
        
        let startAudioAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.audioController.start()
            print("✅ Motor de audio iniciado")
            // Reactivar procesamiento de notificaciones después de iniciar el audio
            self.isProcessingNotification = false
        }
        
        let waitForAudioAction = SKAction.wait(forDuration: 0.3)
        
        let startBlocksAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.blocksManager.startBlockGeneration()
            print("✅ Generación de bloques iniciada")
        }
        
        // Ejecutar la secuencia completa
        let startupSequence = SKAction.sequence([
            startGameEngineAction,
            waitForEngineAction,
            startAudioAction,
            waitForAudioAction,
            startBlocksAction
        ])
        
        // Ejecutar la secuencia en la escena
        run(startupSequence)
    }
    
    // MARK: -  Métodos para manejar las notificaciones
    @objc func handleAudioTunerUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        // Extraer datos de la notificación
        if let note = userInfo["note"] as? String,
           let isActive = userInfo["isActive"] as? Bool,
           let deviation = userInfo["deviation"] as? Double {
            
            // Actualizar componentes visuales
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Actualizar contador de nota detectada
                self.uiManager.detectedNoteCounterNode?.currentNote = note
                self.uiManager.detectedNoteCounterNode?.isActive = isActive
                
                // Actualizar indicador de afinación
                self.uiManager.tuningIndicatorNode.deviation = deviation
                self.uiManager.tuningIndicatorNode.isActive = isActive
            }
        }
    }

    @objc func handleAudioStabilityUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        // Extraer datos de la notificación
        if let duration = userInfo["duration"] as? TimeInterval {
            
            // Actualizar componentes visuales
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Actualizar indicadores de estabilidad
                self.uiManager.stabilityIndicatorNode.duration = duration
                self.uiManager.stabilityCounterNode.duration = duration
            }
        }
    }
    // MARK: - Update Methods
    override func update(_ currentTime: TimeInterval) {
        // Mantener la actualización original
        lastUpdateTime = currentTime
        
        // Si el juego está en curso, comprobar la posición de los bloques
        if case .playing = gameEngine.gameState {
            // Comprobar posición de bloques primero
            gameEngine.checkBlocksPosition()
            
            // Actualizar el tiempo si ha pasado el intervalo
            if currentTime - lastTimeUpdate >= timeUpdateInterval {
                lastTimeUpdate = currentTime
                updateTimeDisplay()
            }
            
            // Luego actualizar el estado del juego
            updateGameState()
        }
    }

    // Método para actualizar la información del tiempo
    private func updateTimeDisplay() {
        guard case .playing = gameEngine.gameState else { return }
        
        if let tracker = objectiveTracker {
            // Incrementar el tiempo en el tracker
            tracker.updateProgress(deltaTime: timeUpdateInterval)
            
            // Obtener el progreso actualizado
            let progress = tracker.getCurrentProgress()
            
            // Debug
            print("⏱️ Tiempo actualizado: \(progress.timeElapsed) segundos (restantes: \(Int(180 - progress.timeElapsed))s)")
            
            // Actualizar directamente el componente de UI
            DispatchQueue.main.async {
                self.uiManager.rightTopBarNode?.updateObjectiveInfo(with: progress)
            }
        }
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
    
    private func handleGameOver(reason: GameOverReason) {
        audioController.stop()
        blocksManager.stopBlockGeneration()
        
        // Actualizar estadísticas del juego
        if let currentLevel = gameManager.currentLevel {
            // Actualizar con el estado de victoria
            gameManager.updateGameStatistics(
                levelId: currentLevel.levelId,
                score: gameEngine.score,
                completed: reason == .victory
            )
        }
        
        // Determinar el mensaje según la razón
        let message = switch reason {
        case .blocksOverflow:
            "¡Los bloques han alcanzado la zona de peligro!"
        case .noLives:
            "¡Te has quedado sin vidas!"
        case .victory:
            "¡Nivel completado!"
        }
        
        print("🔴 Game Over: \(message)")
        
        // Check if player has completed all levels after this victory
        let userProfile = UserProfile.load()
        if userProfile.hasCompletedAllLevels && reason == .victory {
            print("🏆 ¡El jugador ha completado todos los niveles disponibles!")
            // Show special congratulations overlay
            uiManager.showAllLevelsCompletedOverlay(
                score: gameEngine.score,
                onRestart: { [weak self] in
                    // Reset game with first level
                    var updatedProfile = userProfile
                    updatedProfile.hasCompletedAllLevels = false
                    updatedProfile.statistics.currentLevel = 0 // Back to tutorial
                    updatedProfile.save()
                    self?.setupGame()
                },
                onMenu: { [weak self] in
                    self?.navigateToMainMenu()
                }
            )
            return
        }
        
        // Regular game over overlay
        uiManager.showGameOverOverlay(
            score: gameEngine.score,
            message: message,
            isVictory: reason == .victory,
            onRestart: { [weak self] in
                self?.setupGame()
            },
            onMenu: { [weak self] in
                self?.navigateToMainMenu()
            }
        )
    }
    
    // MARK: - Navigation Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        // Check if we're in game over state
        if case .gameOver = gameEngine.gameState {
            print("👆 Touch detected while in game over state")
        }
    }

    // Make sure navigateToMainMenu is properly implemented and visible
    func navigateToMainMenu() {
        print("🏠 Navigating to main menu...")
        
        // Reproducir sonido de botón
            AudioController.sharedInstance.playButtonSoundWithVolume()
        
        // Detener todo el audio y la generación de bloques
        audioController.stop()
        blocksManager.stopBlockGeneration()
        
        // Guardar datos del jugador si es necesario
        if let currentLevel = gameManager.currentLevel {
            gameManager.updateGameStatistics(
                levelId: currentLevel.levelId,
                score: gameEngine.score,
                completed: false  // No se considera completado al salir manualmente
            )
        }
        
        print("📱 Posting NavigateToMainMenu notification")
        // Utilizar NotificationCenter para informar a la vista SwiftUI que debe navegar al menú principal
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToMainMenu"),
            object: nil
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
