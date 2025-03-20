//
//  GameEngine.swift
//  MusicBlocks
//
//  Created by Jose R. García on 13/3/25.
//

import Foundation
import SpriteKit

class GameEngine: ObservableObject {
    // MARK: - Published Properties
    @Published var score: Int = 0
    @Published var lives: Int = 0
    @Published var gameState: GameState = .countdown
    @Published var noteState: NoteState = .waiting
    @Published var combo: Int = 0
    
    // MARK: - Private Properties
    private let tunerEngine: TunerEngine
    private let gameManager = GameManager.shared
    private weak var blockManager: BlocksManager?
    var objectiveTracker: LevelObjectiveTracker?
    
    // Configuración del nivel
    private var maxExtraLives: Int = 0
    private var scoreThresholdsForExtraLives: [Int] = []
    
    // Constantes de tiempo
    private struct TimeConstants {
        static let errorDisplayTime: TimeInterval = 2.0
        static let silenceThreshold: TimeInterval = 0.3
        static let minimalNoteDetectionTime: TimeInterval = 0.5
        static let acceptableDeviation: Double = 10.0
    }
    
    // Estado del juego
    private var isShowingError: Bool = false
    private var isInSuccessState: Bool = false
    
    // Métricas de partidas
    private var gamesWon: Int = 0
    private var gamesLost: Int = 0
    
    // Métricas de la partida actual
    private var gameStartTime: Date?
    private var notesHitInGame: Int = 0
    private var bestStreakInGame: Int = 0
    private var totalAccuracyInGame: Double = 0.0
    private var accuracyMeasurements: Int = 0
    
    // Seguimiento de bloques por estilo en el nivel actual
    private var blockHitsByStyle: [String: Int] = [:]
    
    // MARK: - Initialization
    /// Inicializa el GameEngine con el TunerEngine y el BlocksManager (que puede ser nil)
    init(tunerEngine: TunerEngine = .shared, blockManager: BlocksManager?) {
        self.tunerEngine = tunerEngine
        self.blockManager = blockManager
        gameState = .countdown
        print("GameEngine inicializado. Estado inicial: \(gameState)")
    }
    
    // MARK: - Game Control
    /// Inicia una nueva partida, reseteando todas las métricas y configurando el nivel actual.
    func startNewGame() {
        guard let currentLevel = gameManager.currentLevel else {
            print("No se pudo iniciar el juego: no hay nivel actual")
            return
        }
        
        print("Iniciando nueva partida para el nivel \(currentLevel.levelId)")
        resetGameState()
        
        // Reiniciar contadores por estilo de bloque
        blockHitsByStyle.removeAll()
        for style in currentLevel.allowedStyles {
            blockHitsByStyle[style] = 0
        }
        
        // Inicializar métricas de partida
        gameStartTime = Date()
        notesHitInGame = 0
        bestStreakInGame = 0
        totalAccuracyInGame = 0.0
        accuracyMeasurements = 0
        
        // En lugar de crear una nueva instancia, usamos la existente si ya hay una
            if objectiveTracker == nil {
                objectiveTracker = LevelObjectiveTracker(level: currentLevel)
            } else {
                objectiveTracker?.resetProgress() // Método nuevo que deberás implementar
            }
        
        // Configurar vidas y puntuación
            lives = currentLevel.lives.initial
            maxExtraLives = currentLevel.lives.extraLives.maxExtra
            scoreThresholdsForExtraLives = currentLevel.lives.extraLives.scoreThresholds
            
            // Añadir notificación para actualizar la UI con los valores iniciales
            NotificationCenter.default.post(
                name: NSNotification.Name("GameDataUpdated"),
                object: nil,
                userInfo: [
                    "score": score,
                    "lives": lives,
                    "resetObjectives": true // Flag para indicar reinicio completo
                ]
            )
        
        // Iniciar generación de bloques
        blockManager?.startBlockGeneration()
        
        // Cambiar estado del juego a 'playing'
        gameState = .playing
        
        print("🎮 Nuevo juego iniciado - Nivel: \(currentLevel.levelId)")
    }
    
    /// Pausa la partida actual.
    func pauseGame() {
        guard case .playing = gameState else { return }
        gameState = .paused
        blockManager?.stopBlockGeneration()
        print("Juego pausado")
    }
    
    /// Reanuda la partida pausada.
    func resumeGame() {
        guard case .paused = gameState else { return }
        gameState = .playing
        blockManager?.startBlockGeneration()
        print("Juego reanudado")
    }
    
    /// Finaliza la partida, calcula estadísticas y actualiza el perfil del usuario.
    func endGame(reason: GameOverReason) {
        // Establecer estado de gameOver
        gameState = .gameOver(reason: reason)
        
        // 1. Detener generación de bloques
        blockManager?.stopBlockGeneration()
        
        // 2. Detener AudioController (NUEVO)
        AudioController.sharedInstance.stop()
        
        // Determinar el string para la razón
        let reasonString: String
        let isVictory: Bool
        
        switch reason {
        case .victory:
            reasonString = "victory"
            isVictory = true
        case .noLives:
            reasonString = "noLives"
            isVictory = false
        case .blocksOverflow:
            reasonString = "blocksOverflow"
            isVictory = false
        }
        
        // Actualización final de la UI antes de terminar
        NotificationCenter.default.post(
            name: NSNotification.Name("GameDataUpdated"),
            object: nil,
            userInfo: [
                "score": score,
                "lives": lives,
                "gameOver": true,
                "reason": reasonString,
                "isVictory": isVictory
            ]
        )
        
        // Resto del código para calcular estadísticas...
        let playTime = gameStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let averageAccuracy = accuracyMeasurements > 0 ? totalAccuracyInGame / Double(accuracyMeasurements) : 0.0
        let requiredScore = gameManager.currentLevel?.requiredScore ?? 0
        let isGameWon = reason != .blocksOverflow && score >= requiredScore
        
        // Actualizar estadísticas de juegos ganados/perdidos
        if isGameWon {
            gamesWon += 1
        } else {
            gamesLost += 1
        }
        
        // Guardar estadísticas del perfil
        let userProfile = UserProfile.load()
        var updatedProfile = userProfile
        updatedProfile.updateStatistics(
            score: score,
            noteHits: notesHitInGame,  // Añadir las notas acertadas durante la partida
            currentStreak: combo,      // Pasar el combo actual como racha
            bestStreak: bestStreakInGame, // Pasar la mejor racha de la partida
            accuracy: averageAccuracy,
            levelCompleted: isGameWon,
            isPerfect: averageAccuracy >= 0.95,
            playTime: playTime,
            gamesWon: gamesWon,
            gamesLost: gamesLost
        )
        
        print("📊 Estadísticas finales:")
        print("Tiempo jugado: \(Int(playTime))s, Notas acertadas: \(notesHitInGame), Mejor racha: \(bestStreakInGame), Precisión: \(Int(averageAccuracy * 100))%")
        print("Estado: \(isGameWon ? "Victoria" : "Derrota")")
        print("Total partidas - Ganadas: \(gamesWon), Perdidas: \(gamesLost)")
        
        let totalBlocksAcertados = blockHitsByStyle.values.reduce(0, +)
        print("Bloques acertados: \(totalBlocksAcertados)")
        for (style, count) in blockHitsByStyle {
            print("• \(style): \(count)")
        }
        
        resetGameState()
    }
    
    // MARK: - Note Processing
    /// Compara la nota detectada con el objetivo y delega el manejo correcto o incorrecto.
    func checkNote(currentNote: String, deviation: Double, isActive: Bool) {
        // Verificar inmediatamente si el juego está en estado gameOver
        if case .gameOver = gameState {
            // Ignorar completamente en estado gameOver
            return
        }
        
        guard case .playing = gameState, !isInSuccessState, !isShowingError else {
            print("⚠️ CheckNote: Estado no válido - inSuccessState: \(isInSuccessState), showingError: \(isShowingError), gameState: \(gameState)")
            return
        }
        
        guard let currentBlock = blockManager?.getCurrentBlock(), isActive else {
            return
        }
        
        print("🎯 CheckNote: Comparando nota \(currentNote) con objetivo \(currentBlock.note), desviación: \(deviation)")
        
        // Usar comparación exacta o enarmónica
        if areMusicallyEquivalent(currentNote, currentBlock.note) {
            print("✓ ACIERTO: Nota correcta \(currentNote) coincide con \(currentBlock.note)")
            handleCorrectNote(deviation: deviation, block: currentBlock)
        } else {
            print("✗ FALLO: Nota incorrecta \(currentNote) ≠ \(currentBlock.note)")
            handleWrongNote()
        }
    }

    /// Determina si dos notas son musicalmente equivalentes (misma nota o enarmónicas)
    private func areMusicallyEquivalent(_ note1: String, _ note2: String) -> Bool {
        return MusicalNote.areNotesEquivalent(note1, note2)
    }
    
    // MARK: - Note Handling
    /// Maneja la nota correcta: actualiza el progreso del bloque y, si se cumplen los requisitos, registra el éxito.
    private func handleCorrectNote(deviation: Double, block: BlockInfo) {
        GameLogger.shared.noteDetection("🎵 HandleCorrectNote - Intento registrado con desviación: \(deviation)")
        
        // Procesamiento secuencial de bloques
        let blockCompleted = blockManager?.updateCurrentBlockProgress(hitTime: Date()) ?? false
        
        // Actualizar estado de acierto
        if blockCompleted {
            GameLogger.shared.noteDetection("🎯 Bloque completado!")
            handleSuccess(deviation: deviation, blockConfig: block.config)
        } else {
            // Aquí solo actualizamos el estado visual pero no iniciamos otra verificación
            noteState = .correct(deviation: deviation)
            GameLogger.shared.noteDetection("🔄 Bloque continúa, progreso actualizado")
        }
        
        // Incrementar combo solo si el bloque no se completó o si se completó exitosamente
        combo += 1
    }
    
    /// Maneja el caso de nota incorrecta: reduce vidas y reinicia el progreso del bloque.
    private func handleWrongNote() {
        guard !isShowingError else { return }
        isShowingError = true
        lives -= 1
        combo = 0
        noteState = .wrong
        blockManager?.resetCurrentBlockProgress()
        
        // Add immediate notification for UI update
        NotificationCenter.default.post(
            name: NSNotification.Name("GameDataUpdated"),
            object: nil,
            userInfo: [
                "lives": lives,
                "combo": combo,
                "noteState": "wrong"  // This explicitly tells UI to show failure overlay
            ]
        )
        
        if lives <= 0 {
            endGame(reason: .noLives)
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeConstants.errorDisplayTime) { [weak self] in
            self?.isShowingError = false
            self?.noteState = .waiting
        }
    }
    
    /// Maneja el éxito al completar el bloque: actualiza estadísticas, suma puntos y verifica objetivos.
    private func handleSuccess(deviation: Double, blockConfig: Block) {
        isInSuccessState = true
        
        // Incrementar contador de bloques por estilo
        if let currentBlock = blockManager?.getCurrentBlock() {
            blockHitsByStyle[currentBlock.style] = (blockHitsByStyle[currentBlock.style] ?? 0) + 1
            print("📊 Bloque estilo \(currentBlock.style) acertado: ahora \(blockHitsByStyle[currentBlock.style]!)")
        }
        
        // 1. Calcular precisión basada en la desviación de afinación
        let accuracy = calculateAccuracy(deviation: deviation)
        print("📏 Precisión calculada: \(Int(accuracy*100))%")
        
        // 2. Obtener puntuación y mensaje según la precisión
        let (baseScore, message) = calculateScore(accuracy: accuracy, blockConfig: blockConfig)
        let comboBonus = calculateComboBonus(baseScore: baseScore)
        let finalScore = baseScore + comboBonus
        score += finalScore
        
        // 3. Preparar mensaje para el overlay
        let comboMessage = combo > 1 ? " (\(combo)x Combo!)" : ""
        let finalMessage = "\(message)\(comboMessage)"
        
        print("🏆 ÉXITO: \(message) con precisión \(Int(accuracy*100))%, puntos: \(finalScore), combo: \(combo)")
        
        // 4. Comprobar si merece vida extra
        checkForExtraLife(currentScore: score)
        
        // 5. Actualizar el progreso de los objetivos
        let blockStyle = blockManager?.getCurrentBlock()?.style ?? "defaultBlock"
        objectiveTracker?.updateProgress(
            score: score,             // Para objetivos tipo "score"
            noteHit: true,            // Para objetivos tipo "total_notes"
            accuracy: accuracy,       // Para objetivos tipo "note_accuracy"
            blockDestroyed: blockStyle // Para objetivos tipo "block_destruction" y "total_blocks"
        )
            
        // 6. Send immediate notification to UI
        NotificationCenter.default.post(
            name: NSNotification.Name("GameDataUpdated"),
            object: nil,
            userInfo: [
                "score": score,
                "lives": lives,
                "combo": combo,
                "noteState": "success",
                "multiplier": finalScore / blockConfig.basePoints,
                "message": finalMessage,
                "blockDestroyed": blockStyle,
                "accuracy": accuracy
            ]
        )
        
        // 7. Comprobar si se han completado los objetivos (victoria)
        if let primaryComplete = objectiveTracker?.checkObjectives(), primaryComplete {
            endGame(reason: .victory)
        }
        
        // 8. Actualizar el estado de la nota para el sistema
        noteState = .success(
            multiplier: finalScore / blockConfig.basePoints,
            message: finalMessage
        )
        
        // 9. Restaurar estado normal después de un breve tiempo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isInSuccessState = false
            self?.noteState = .waiting
        }
    }
    
    // MARK: - Score Calculation
    /// Calcula la precisión a partir de la desviación.
    private func calculateAccuracy(deviation: Double) -> Double {
        // Mayor tolerancia para niños: aceptamos hasta un cuarto de tono de desviación (50 cents)
        let acceptableDeviation: Double = 50.0  // Mayor que antes (10.0)
        
        let absDeviation = abs(deviation)
        if absDeviation > acceptableDeviation { return 0.0 }
        
        // Fórmula mejorada para que pequeñas desviaciones (hasta 10 cents) se consideren "perfectas"
        if absDeviation <= 10.0 {
            return 1.0  // Perfecta afinación para pequeñas desviaciones
        }
        
        // Para el resto, escala lineal más benévola
        return 1.0 - ((absDeviation - 10.0) / (acceptableDeviation - 10.0))
    }
    
    /// Calcula la puntuación base y un mensaje en función de la precisión.
    private func calculateScore(accuracy: Double, blockConfig: Block) -> (score: Int, message: String) {
        guard let thresholds = gameManager.gameConfig?.accuracyThresholds else {
            return (blockConfig.basePoints, "¡Bien!")
        }
        
        if accuracy >= thresholds.perfect.threshold {
            return (Int(Double(blockConfig.basePoints) * thresholds.perfect.multiplier), "¡Perfecto!")
        } else if accuracy >= thresholds.excellent.threshold {
            return (Int(Double(blockConfig.basePoints) * thresholds.excellent.multiplier), "¡Excelente!")
        } else if accuracy >= thresholds.good.threshold {
            return (Int(Double(blockConfig.basePoints) * thresholds.good.multiplier), "¡Bien!")
        }
        
        return (0, "Fallo")
    }
    
    /// Calcula el bono por combo.
    private func calculateComboBonus(baseScore: Int) -> Int {
        // Limitar el multiplicador de combo a 10x como máximo
        let comboMultiplier = min(combo, 10)
        
        // La fórmula de bono:
        // Si el combo es 1, no hay bono adicional
        // Si el combo es mayor, se aplica un bono progresivo
        return baseScore * (comboMultiplier - 1) / 2
    }
    
    // MARK: - Lives Management
    /// Verifica y concede vidas extra si se alcanza el umbral de puntuación.
    private func checkForExtraLife(currentScore: Int) {
        for threshold in scoreThresholdsForExtraLives {
            if currentScore >= threshold && lives < (gameManager.currentLevel?.lives.initial ?? 3) + maxExtraLives {
                lives += 1
                print("🎉 Vida extra ganada. Vidas actuales: \(lives)")
                
                // Añadir notificación para actualizar la UI inmediatamente
                NotificationCenter.default.post(
                    name: NSNotification.Name("GameDataUpdated"),
                    object: nil,
                    userInfo: ["lives": lives]
                )
                
                if let index = scoreThresholdsForExtraLives.firstIndex(of: threshold) {
                    scoreThresholdsForExtraLives.remove(at: index)
                }
                break
            }
        }
    }
    
    // MARK: - State Management
    /// Resetea todas las métricas y estados de la partida.
    private func resetGameState() {
        score = 0
        combo = 0
        isShowingError = false
        isInSuccessState = false
        noteState = .waiting
        gameStartTime = nil
        notesHitInGame = 0
        bestStreakInGame = 0
        totalAccuracyInGame = 0.0
        accuracyMeasurements = 0
        blockHitsByStyle.removeAll()
        print("🔄 Estado del juego reseteado.")
    }
    
    // MARK: - Block Monitoring
    /// Comprueba si algún bloque ha alcanzado la zona límite (danger zone).
    func checkBlocksPosition() {
        if blockManager?.hasBlocksBelowLimit() == true {
            print("🔥 Game Over: Bloques han alcanzado la zona de peligro.")
            endGame(reason: .blocksOverflow)
        }
    }
    
    /// Retorna el progreso del objetivo actual.
    func getLevelProgress() -> Double {
        return objectiveTracker?.getProgress() ?? 0
    }
    
    /// Devuelve el resumen de bloques acertados por estilo.
    func getBlockHitsByStyle() -> [String: Int] {
        return blockHitsByStyle
    }
}

// MARK: - AudioControllerDelegate
extension GameEngine: AudioControllerDelegate {
    func audioController(_ controller: AudioController, didDetectNote note: String, frequency: Float, amplitude: Float, deviation: Double) {
        // Verificar primero si el juego está en estado final
        if case .gameOver = gameState {
            // Si el juego ha terminado, ignorar completamente el procesamiento
            return
        }
        
        // Verificar si hay un bloque en proceso de eliminación
        guard let blockManager = blockManager, !blockManager.isBlockProcessing else {
            print("⚠️ AudioController: Bloque en proceso de eliminación, ignorando nota detectada")
            return
        }
        
        print("AudioControllerDelegate - Nota detectada: \(note), Frecuencia: \(frequency)")
        
        // Publicar notificaciones para actualizar UI
        controller.publishTunerData()
        controller.publishStabilityData()
        
        // Continuar con el procesamiento normal
        self.checkNote(currentNote: note, deviation: deviation, isActive: true)
    }
    
    func audioControllerDidDetectSilence(_ controller: AudioController) {
        // Verificar primero si el juego está en estado final
        if case .gameOver = gameState {
            // Si el juego ha terminado, ignorar completamente el procesamiento
            return
        }
        
        // Publicar notificaciones para actualizar UI (ahora en modo inactivo)
        controller.publishTunerData()
        controller.publishStabilityData()
        
        // Continuar con el procesamiento normal
        self.checkNote(currentNote: "-", deviation: 0, isActive: false)
    }
    
    // Implementación del método requerido para el tiempo de hold
    func audioControllerRequiredHoldTime(_ controller: AudioController) -> TimeInterval {
        // Si el juego ha terminado, devolvemos un valor por defecto
        if case .gameOver = gameState {
            return 1.0
        }
        
        if let currentBlock = blockManager?.getCurrentBlock() {
            GameLogger.shared.audioDetection("Required hold time para el bloque actual: \(currentBlock.config.requiredTime) segundos")
            return currentBlock.config.requiredTime
        }
        GameLogger.shared.audioDetection("AudioControllerDelegate - No hay bloque activo, se retorna 1.0 segundo por defecto")
        return 1.0
    }
}

