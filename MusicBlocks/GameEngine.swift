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
        
        // Crear tracker para objetivos
        objectiveTracker = LevelObjectiveTracker(level: currentLevel)
        
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
        gameState = .gameOver(reason: reason)
        blockManager?.stopBlockGeneration()
        
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
        
        let playTime = gameStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let averageAccuracy = accuracyMeasurements > 0 ? totalAccuracyInGame / Double(accuracyMeasurements) : 0.0
        let requiredScore = gameManager.currentLevel?.requiredScore ?? 0
        let isGameWon = reason != .blocksOverflow && score >= requiredScore
        
        if isGameWon {
            gamesWon += 1
        } else {
            gamesLost += 1
        }
        
        let userProfile = UserProfile.load()
        var updatedProfile = userProfile
        updatedProfile.updateStatistics(
            score: score,
            noteHit: false,
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
        guard case .playing = gameState, !isInSuccessState, !isShowingError else {
            return
        }
        
        guard let currentBlock = blockManager?.getCurrentBlock(), isActive else {
            print("No se procesará nota: no hay bloque activo o no está activa")
            return
        }
        
        print("🎯 Comparando nota detectada (\(currentNote)) con objetivo (\(currentBlock.note)), desviación: \(deviation)")
        
        if currentNote == currentBlock.note {
            handleCorrectNote(deviation: deviation, block: currentBlock)
        } else {
            handleWrongNote()
        }
    }
    
    // MARK: - Note Handling
    /// Maneja la nota correcta: actualiza el progreso del bloque y, si se cumplen los requisitos, registra el éxito.
    private func handleCorrectNote(deviation: Double, block: BlockInfo) {
        if blockManager?.updateCurrentBlockProgress(hitTime: Date()) == true {
            handleSuccess(deviation: deviation, blockConfig: block.config)
        } else {
            noteState = .correct(deviation: deviation)
        }
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
        
        // Añadir notificación para actualizar la UI inmediatamente
        NotificationCenter.default.post(
            name: NSNotification.Name("GameDataUpdated"),
            object: nil,
            userInfo: ["lives": lives, "combo": combo]
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
        
        if let currentBlock = blockManager?.getCurrentBlock() {
            blockHitsByStyle[currentBlock.style] = (blockHitsByStyle[currentBlock.style] ?? 0) + 1
            print("📊 Bloques acertados actualizados:")
            for (style, count) in blockHitsByStyle {
                print("• \(style): \(count)")
            }
        }
        
        let accuracy = calculateAccuracy(deviation: deviation)
        let (baseScore, message) = calculateScore(accuracy: accuracy, blockConfig: blockConfig)
        let comboBonus = calculateComboBonus(baseScore: baseScore)
        let finalScore = baseScore + comboBonus
        score += finalScore
        
        checkForExtraLife(currentScore: score)
        
        // Obtener el estilo del bloque actual
        let blockStyle = blockManager?.getCurrentBlock()?.style ?? "defaultBlock"
        
        // Actualizar TODOS los datos relevantes para CUALQUIER tipo de objetivo
            objectiveTracker?.updateProgress(
                score: score,             // Para objetivos tipo "score"
                noteHit: true,            // Para objetivos tipo "total_notes"
                accuracy: accuracy,       // Para objetivos tipo "note_accuracy"
                blockDestroyed: blockStyle // Para objetivos tipo "block_destruction" y "total_blocks"
            )
            
        // Enviar notificación con TODOS los datos relevantes
        // Enviar notificación después de actualizar el tracker
        // INCORRECTO:
        NotificationCenter.default.post(
            name: NSNotification.Name("GameDataUpdated"),
            object: nil,
            userInfo: [
                "lives": lives,
                "combo": combo,
                "noteState": "wrong" // ERROR: Esto debería ser "success", no "wrong"
            ]
        )

        // CORRECTO:
        NotificationCenter.default.post(
            name: NSNotification.Name("GameDataUpdated"),
            object: nil,
            userInfo: [
                "score": score,
                "lives": lives,
                "combo": combo,
                "noteState": "success",
                "multiplier": finalScore / blockConfig.basePoints,
                "message": "\(message) (\(combo)x Combo!)",
                "blockDestroyed": blockStyle,
                "accuracy": accuracy
            ]
        )
        
        if let primaryComplete = objectiveTracker?.checkObjectives(), primaryComplete {
            endGame(reason: .victory)
        }
        
        noteState = .success(
            multiplier: finalScore / blockConfig.basePoints,
            message: "\(message) (\(combo)x Combo!)"
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isInSuccessState = false
            self?.noteState = .waiting
        }
    }
    
    // MARK: - Score Calculation
    /// Calcula la precisión a partir de la desviación.
    private func calculateAccuracy(deviation: Double) -> Double {
        let absDeviation = abs(deviation)
        if absDeviation > TimeConstants.acceptableDeviation { return 0.0 }
        return 1.0 - (absDeviation / TimeConstants.acceptableDeviation)
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
        let comboMultiplier = min(combo, 10)
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
    /// Recibe la nota detectada y la procesa.
    func audioController(_ controller: AudioController, didDetectNote note: String, frequency: Float, amplitude: Float, deviation: Double) {
        print("AudioControllerDelegate - Nota detectada: \(note), Frecuencia: \(frequency)")
        self.checkNote(currentNote: note, deviation: deviation, isActive: true)
    }
    
    /// Se invoca cuando se detecta silencio.
    func audioControllerDidDetectSilence(_ controller: AudioController) {
        print("AudioControllerDelegate - Silencio detectado.")
        self.checkNote(currentNote: "-", deviation: 0, isActive: false)
    }
    
    /// Devuelve el tiempo requerido para mantener la nota, consultando el bloque actual.
    func audioControllerRequiredHoldTime(_ controller: AudioController) -> TimeInterval {
        if let currentBlock = blockManager?.getCurrentBlock() {
            print("AudioControllerDelegate - Required hold time para el bloque actual: \(currentBlock.config.requiredTime) segundos")
            return currentBlock.config.requiredTime
        }
        print("AudioControllerDelegate - No hay bloque activo, se retorna 1.0 segundo por defecto")
        return 1.0
    }
}
