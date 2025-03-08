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
        
        func endGame(reason: GameOverReason) {  // Ya no necesita GameEngine.GameOverReason
            gameState = .gameOver(reason: reason)
            blockManager?.stopBlockGeneration()
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
        }
        
        // MARK: - Block Monitoring
        func checkBlocksPosition() {
            if blockManager?.hasBlocksBelowLimit() == true {
                endGame(reason: .blocksOverflow)
            }
        }

}
