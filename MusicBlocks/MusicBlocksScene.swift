//
//  MusicBlocksScene.swift
//  MusicBlocks
//
//  Created by Jose R. García on 14/3/25.
//  Actualizado para usar GameSessionManager para gestionar la sesión de juego.
//

import SpriteKit
import UIKit
import SwiftUI

class MusicBlocksScene: SKScene  {
    @Environment(\.screenSize) var screenSize
    
    // MARK: - Managers
    private let audioController = AudioController.sharedInstance
    private let uiSoundController = UISoundController.shared
    private let gameManager = GameManager.shared
    private var gameEngine: GameEngine!
    private var blocksManager: BlocksManager!
    private var uiManager: GameUIManager!
    private var sessionManager: GameSessionManager!
    var objectiveTracker: LevelObjectiveTracker?
    
    // MARK: - Game State
    private var lastUpdateTime: TimeInterval = 0
    private var lastTimeUpdate: TimeInterval = 0
    private let timeUpdateInterval: TimeInterval = 1.0 // Actualizar cada segundo
    
    private var isProcessingNotification = false
    
    // Añadir propiedades para el timer dedicado:
    private var uiUpdateTimer: Timer?
    private let uiUpdateInterval: TimeInterval = 0.1 // Actualizar 10 veces por segundo para fluidez
    
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
        
        // AÑADIR: Detener el timer dedicado
        uiUpdateTimer?.invalidate()
        uiUpdateTimer = nil
        
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
                        self?.sessionManager.navigateToMainMenu()
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
        
        // Paso 7: Inicializar GameSessionManager
        sessionManager = GameSessionManager(
            scene: self,
            gameEngine: gameEngine,
            blocksManager: blocksManager,
            uiManager: uiManager
        )
        
        // Paso 8: Configurar delegado de audio
        audioController.delegate = gameEngine
        
        // Paso 9: Actualizar UI con valores iniciales
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimerActivation(_:)),
            name: NSNotification.Name("ActivateTimers"),
            object: nil
        )
        
        print("✅ Managers inicializados correctamente")
    }
    
    private func setupGame() {
        // Delegar la configuración del juego al GameSessionManager
        sessionManager.setupGame()
    }
    
    // MARK: -  Métodos para activar timers

    @objc func handleTimerActivation(_ notification: Notification) {
        print("⏱️ Recibida notificación para activar timers")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Activar todos los TimeDisplayNode existentes
            self.activateAllTimeDisplayNodes()
            
            // También actualizar el tiempo transcurrido inicial a cero
            if let tracker = self.objectiveTracker {
                tracker.updateProgress(deltaTime: 0) // Sólo para asegurar que comienza desde cero
                let progress = tracker.getCurrentProgress()
                self.uiManager.rightTopBarNode?.updateObjectiveInfo(with: progress)
            }
            
            // AÑADIR: Iniciar el timer dedicado para actualización de UI
            self.startDedicatedUIUpdateTimer()
        }
    }
    
    // Añadir método para iniciar el timer dedicado:
    private func startDedicatedUIUpdateTimer() {
        // Detener timer existente si hay uno
        uiUpdateTimer?.invalidate()
        
        // Crear un nuevo timer que se ejecute en el RunLoop principal
        uiUpdateTimer = Timer.scheduledTimer(
            timeInterval: uiUpdateInterval,
            target: self,
            selector: #selector(updateUITimers),
            userInfo: nil,
            repeats: true
        )
        
        // Añadir el timer al RunLoop común para que no se interrumpa durante animaciones
        if let timer = uiUpdateTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        print("⏱️ Timer dedicado para actualización de UI iniciado")
    }

    // Añadir el método que será llamado por el timer:
    @objc private func updateUITimers() {
        // Solo actualizar si el juego está en estado 'playing'
        guard case .playing = gameEngine.gameState else {
            return
        }
        
        // Forzar actualización de todos los timeDisplayNodes sin actualizar el tiempo del tracker
        // Para asegurar que se muestren los segundos de forma fluida
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Solo actualizamos las vistas, no el modelo (el tiempo del juego)
            if let scene = self.scene {
                self.updateTimeDisplayNodesRecursively(in: scene)
            }
        }
    }
    
    // Método para activar todos los TimeDisplayNode en la jerarquía
    private func activateAllTimeDisplayNodes() {
        if let scene = self.scene {
            activateTimeDisplayNodesRecursively(in: scene)
        }
    }

    // Método recursivo auxiliar
    private func activateTimeDisplayNodesRecursively(in node: SKNode) {
        // Primero buscar en este nodo
        if let timeDisplay = node as? TimeDisplayNode {
            timeDisplay.activateTimer()
        }
        
        // Luego buscar en todos los hijos
        for child in node.children {
            activateTimeDisplayNodesRecursively(in: child)
        }
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
            // Obtener el requiredTime de la notificación (con valor por defecto de 1.0 si no existe)
            let requiredTime = userInfo["requiredTime"] as? TimeInterval ?? 1.0
            
            // Actualizar componentes visuales
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Actualizar indicadores de estabilidad
                self.uiManager.stabilityIndicatorNode.duration = duration
                // Establecer el nuevo maxDuration basado en el requiredTime del bloque actual
                self.uiManager.stabilityIndicatorNode.setMaxDuration(requiredTime)
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
            // Incrementar el tiempo en el tracker (sólo si el juego está en curso)
            tracker.updateProgress(deltaTime: timeUpdateInterval)
            
            // NO ES NECESARIO actualizar los nodos aquí, lo hará el timer dedicado
            // Solo actualizamos el progreso en el modelo
            let progress = tracker.getCurrentProgress()
            GameLogger.shared.timeUpdate("⏱️ Tiempo actualizado en modelo: \(progress.timeElapsed) segundos")
        }
    }

    // Método nuevo para actualizar cada TimeDisplayNode manualmente
    private func updateTimeDisplayNodesRecursively(in node: SKNode) {
        if let timeDisplay = node as? TimeDisplayNode {
            timeDisplay.update() // Forzar la actualización manual del nodo
        }
        
        // Recursivamente actualizar los hijos
        for child in node.children {
            updateTimeDisplayNodesRecursively(in: child)
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
                    self?.sessionManager.navigateToMainMenu()
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
                self?.sessionManager.navigateToMainMenu()
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
