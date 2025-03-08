//
//  GameEngine.swift
//  MusicBlocks
//
//  Created by Jose R. García on 7/3/25.
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
    private var objectiveTracker: LevelObjectiveTracker?
    
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
    init(tunerEngine: TunerEngine = .shared, blockManager: BlocksManager?) {
        self.tunerEngine = tunerEngine
        self.blockManager = blockManager
        gameState = .countdown
    }
    
    // MARK: - Game Control
    func startNewGame() {
        guard let currentLevel = gameManager.currentLevel else { return }
        
        // Resetear estado del juego
        resetGameState()
        
        // Inicializar contador de bloques por estilo
        blockHitsByStyle.removeAll()
        for style in currentLevel.allowedStyles {
            blockHitsByStyle[style] = 0
        }
        
        // Inicializar métricas de la partida
        gameStartTime = Date()
        notesHitInGame = 0
        bestStreakInGame = 0
        totalAccuracyInGame = 0.0
        accuracyMeasurements = 0
        
        // Inicializar el tracker de objetivos
        objectiveTracker = LevelObjectiveTracker(level: currentLevel)
        
        // Configurar vidas y puntuación
        lives = currentLevel.lives.initial
        maxExtraLives = currentLevel.lives.extraLives.maxExtra
        scoreThresholdsForExtraLives = currentLevel.lives.extraLives.scoreThresholds
        
        // Iniciar generación de bloques
        blockManager?.startBlockGeneration()
        
        // Cambiar estado
        gameState = .playing
        
        print("🎮 Nuevo juego iniciado - Nivel: \(currentLevel.levelId)")
    }
    
    func pauseGame() {
        guard case .playing = gameState else { return }
        gameState = .paused
        blockManager?.stopBlockGeneration()
    }
    
    func resumeGame() {
        guard case .paused = gameState else { return }
        gameState = .playing
        blockManager?.startBlockGeneration()
    }
    
    func endGame(reason: GameOverReason) {
        gameState = .gameOver(reason: reason)
        blockManager?.stopBlockGeneration()
        
        // Calcular métricas finales
        let playTime = gameStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let averageAccuracy = accuracyMeasurements > 0 ?
        totalAccuracyInGame / Double(accuracyMeasurements) : 0.0
        
        // Determinar si la partida fue ganada o perdida
        let requiredScore = gameManager.currentLevel?.requiredScore ?? 0
        let isGameWon = reason != .blocksOverflow && score >= requiredScore
        
        // Actualizar contadores de partidas
        if isGameWon {
            gamesWon += 1
        } else {
            gamesLost += 1
        }
        
        // Actualizar estadísticas del usuario
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
        
        // Imprimir estadísticas para debug
        print("📊 Estadísticas de la partida:")
        print("⏱️ Tiempo jugado: \(Int(playTime))s")
        print("🎯 Notas acertadas: \(notesHitInGame)")
        print("🔥 Mejor racha: \(bestStreakInGame)")
        print("📏 Precisión promedio: \(Int(averageAccuracy * 100))%")
        print("🎮 Estado: \(isGameWon ? "Victoria" : "Derrota")")
        print("📈 Total partidas - Ganadas: \(gamesWon), Perdidas: \(gamesLost)")
        
        // Imprimir estadísticas finales de bloques por estilo
        print("📊 Resumen final de bloques por estilo:")
        for (style, count) in blockHitsByStyle {
            print("  • \(style): \(count) bloques acertados")
        }
        
        resetGameState()
    }
    
    
    // MARK: - Note Processing
    func checkNote(currentNote: String, deviation: Double, isActive: Bool) {
        guard case .playing = gameState,
              !isInSuccessState,
              !isShowingError else {
            return
        }
        
        guard let currentBlock = blockManager?.getCurrentBlock(),
              isActive else {
            return
        }
        
        print("🎯 Comparando notas:")
        print("   Detectada: \(currentNote)")
        print("   Objetivo: \(currentBlock.note)")
        print("   Desviación: \(deviation)")
        
        if currentNote == currentBlock.note {
            handleCorrectNote(deviation: deviation, block: currentBlock)
        } else {
            handleWrongNote()
        }
    }
    
    // MARK: - Note Handling
    private func handleCorrectNote(deviation: Double, block: BlockInfo) {
        if blockManager?.updateCurrentBlockProgress(hitTime: Date()) == true {
            handleSuccess(deviation: deviation, blockConfig: block.config)
        } else {
            noteState = .correct(deviation: deviation)
        }
        
        combo += 1
    }
    
    private func handleWrongNote() {
        guard !isShowingError else { return }
        
        isShowingError = true
        lives -= 1
        combo = 0
        noteState = .wrong
        blockManager?.resetCurrentBlockProgress()
        
        if lives <= 0 {
            endGame(reason: .noLives)
            return
        }
        
        // Resetear estado de error después de un tiempo
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeConstants.errorDisplayTime) { [weak self] in
            guard let self = self else { return }
            self.isShowingError = false
            self.noteState = .waiting
        }
    }
    
    private func handleSuccess(deviation: Double, blockConfig: Block) {
        isInSuccessState = true
        
        // Incrementar contador de bloques por estilo
        if let currentBlock = blockManager?.getCurrentBlock() {
            blockHitsByStyle[currentBlock.style] = (blockHitsByStyle[currentBlock.style] ?? 0) + 1
            
            // Debug: imprimir contadores actualizados
            print("📊 Bloques acertados por estilo:")
            for (style, count) in blockHitsByStyle {
                print("  • \(style): \(count)")
            }
        }
        
        // Actualizar progreso de objetivos
                objectiveTracker?.updateProgress(
                    score: score,
                    noteHit: true,
                    accuracy: calculateAccuracy(deviation: deviation),
                    blockDestroyed: blockConfig.style
                )
                
                // Comprobar si se han completado los objetivos
                if let (primaryComplete, secondaryComplete) = objectiveTracker?.checkObjectives(),
                   primaryComplete {
                    // Victoria si el objetivo principal está completo
                    endGame(reason: .victory)
                }
        
        // Calcular puntuación con bonus por combo
        let accuracy = calculateAccuracy(deviation: deviation)
        let (baseScore, message) = calculateScore(accuracy: accuracy, blockConfig: blockConfig)
        let comboBonus = calculateComboBonus(baseScore: baseScore)
        let finalScore = baseScore + comboBonus
        
        // Actualizar puntuación
        score += finalScore
        
        // Comprobar vidas extra
        checkForExtraLife(currentScore: score)
        
        // Notificar éxito
        noteState = .success(
            multiplier: finalScore / blockConfig.basePoints,
            message: "\(message) (\(combo)x Combo!)"
        )
        
        // Resetear estado después de un breve delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.isInSuccessState = false
            self.noteState = .waiting
        }
    }
    
    // MARK: - Score Calculation
    private func calculateAccuracy(deviation: Double) -> Double {
        let absDeviation = abs(deviation)
        if absDeviation > TimeConstants.acceptableDeviation {
            return 0.0
        }
        return 1.0 - (absDeviation / TimeConstants.acceptableDeviation)
    }
    
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
    
    private func calculateComboBonus(baseScore: Int) -> Int {
        let comboMultiplier = min(combo, 10) // Máximo multiplicador de 10x
        return baseScore * (comboMultiplier - 1) / 2 // Bonus más equilibrado
    }
    
    // MARK: - Lives Management
    private func checkForExtraLife(currentScore: Int) {
        for threshold in scoreThresholdsForExtraLives {
            if currentScore >= threshold && lives < (gameManager.currentLevel?.lives.initial ?? 3) + maxExtraLives {
                lives += 1
                print("🎉 ¡Vida extra ganada! Vidas actuales: \(lives)")
                
                if let index = scoreThresholdsForExtraLives.firstIndex(of: threshold) {
                    scoreThresholdsForExtraLives.remove(at: index)
                }
                break
            }
        }
    }
    
    // MARK: - State Management
    private func resetGameState() {
        score = 0
        combo = 0
        isShowingError = false
        isInSuccessState = false
        noteState = .waiting
        
        // Resetear métricas
        gameStartTime = nil
        notesHitInGame = 0
        bestStreakInGame = 0
        totalAccuracyInGame = 0.0
        accuracyMeasurements = 0
        
        // Resetear contadores de bloques por estilo
        blockHitsByStyle.removeAll()
    }
    
    // MARK: - Block Monitoring
    func checkBlocksPosition() {
        if blockManager?.hasBlocksBelowLimit() == true {
            print("🔥 Game Over: Bloques han alcanzado la zona límite")
            endGame(reason: .blocksOverflow)
        }
    }
    
    // Añadir nuevo método para obtener el progreso
        func getLevelProgress() -> (primary: Double, secondary: Double?) {
            return objectiveTracker?.getProgress() ?? (0, nil)
        }
    
    // Método público para consultar los bloques acertados por estilo
    func getBlockHitsByStyle() -> [String: Int] {
        return blockHitsByStyle
    }
    
}
