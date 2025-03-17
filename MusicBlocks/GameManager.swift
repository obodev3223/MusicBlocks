//
//  GameManager.swift
//  MusicBlocks
//
//  Created by Jose R. García on 7/3/25.
//

import Foundation

class GameManager {
    // MARK: - Singleton
    static let shared = GameManager()
    
    // MARK: - Properties
    private(set) var gameConfig: GameConfig?
    private(set) var currentLevel: GameLevel?
    private var userProfile: UserProfile
    
    // MARK: - Game Statistics
    private(set) var totalGamesPlayed: Int = 0
    private(set) var highScores: [Int: Int] = [:] // [levelId: highScore]
    private(set) var lastPlayedLevel: Int = 0
    
    // MARK: - Constants
    private struct Constants {
        static let maxUnlockedLevel = 10
        static let tutorialLevelId = 0
        static let defaultLives = 3
    }
    
    // MARK: - Initialization
    private init() {
        userProfile = UserProfile.load()
        loadGameConfig()
        loadStatistics()
    }
    
    // MARK: - Configuration Loading
    private func loadGameConfig() {
        if let config = GameLevelProcessor.loadGameLevelsFromFile() {
            print("✅ Configuración del juego cargada")
            print("📊 Número de niveles: \(config.levels.count)")
            gameConfig = config
        } else {
            print("❌ Error al cargar la configuración del juego")
        }
    }
    
    private func loadStatistics() {
        totalGamesPlayed = userProfile.statistics.totalGamesPlayed
        lastPlayedLevel = userProfile.statistics.currentLevel
    }
    
    // MARK: - Level Management
    func loadLevel(_ levelId: Int) -> Bool {
        guard let config = gameConfig else {
            print("❌ Error: No se pudo cargar la configuración del juego")
            return false
        }
        
        print("🔄 Attempting to load level \(levelId)")
        
        // Check if we're trying to load a level beyond the last available level
        let highestLevelId = getHighestAvailableLevelId()
        if levelId > highestLevelId {
            print("🏆 Intentando cargar nivel \(levelId) que está más allá del último nivel disponible (\(highestLevelId))")
            // This will be handled by the UI to show congratulations
            userProfile.hasCompletedAllLevels = true
            userProfile.save()
            return false
        }
        
        // Check if the level is unlocked
        if !isLevelUnlocked(levelId) {
            print("🔒 Nivel \(levelId) bloqueado - no se puede cargar")
            return false
        }
        
        // Check if the level exists
        if !levelExists(levelId) {
            print("❌ Error: Nivel \(levelId) no existe en la configuración")
            return false
        }
        
        // Load the requested level
        if let level = GameLevelProcessor.getLevel(from: config, withId: levelId) {
            currentLevel = level
            lastPlayedLevel = levelId
            userProfile.statistics.currentLevel = levelId
            userProfile.save()
            
            print("✅ Nivel \(levelId) cargado: \(level.name)")
            return true
        }
        
        print("❌ Error: No se pudo cargar el nivel \(levelId)")
        return false
    }
    
    // New method to check if a level exists
    func levelExists(_ levelId: Int) -> Bool {
        guard let config = gameConfig else { return false }
        let level = config.levels.first(where: { $0.levelId == levelId })
        let exists = level != nil
        print("🔍 Checking if level \(levelId) exists: \(exists ? "✅ Yes" : "❌ No")")
        return exists
    }
    
    // Get the highest available level ID
    func getHighestAvailableLevelId() -> Int {
        guard let config = gameConfig else { return 0 }
        let highestId = config.levels.map { $0.levelId }.max() ?? 0
        print("📊 Highest available level ID: \(highestId)")
        return highestId
    }
    
    func isLevelUnlocked(_ levelId: Int) -> Bool {
        // Tutorial is always unlocked
        if levelId == Constants.tutorialLevelId { return true }
        
        // Debug logging
        print("🔍 Checking if level \(levelId) is unlocked")
        
        // Better logic - only check if the previous level was completed (has high score)
        let previousLevelCompleted = highScores[levelId - 1] != nil
        print("🔑 Previous level (\(levelId - 1)) completion status: \(previousLevelCompleted ? "✅ Completed" : "❌ Not completed")")
        
        // If we've already played this level before, it's definitely unlocked
        if highScores[levelId] != nil {
            print("🔓 Level \(levelId) is already played before, unlocked")
            return true
        }
        
        // Simple rule: you can play level N if you've completed level N-1
        return previousLevelCompleted
    }
    
    // MARK: - Game Progress
    func updateGameStatistics(levelId: Int, score: Int, completed: Bool) {
        // Update local statistics
        totalGamesPlayed += 1
        
        // Update high score if necessary
        if let currentHighScore = highScores[levelId] {
            if score > currentHighScore {
                highScores[levelId] = score
                print("🏆 Nuevo récord en nivel \(levelId): \(score)")
            }
        } else {
            highScores[levelId] = score
            print("🎮 Primera puntuación en nivel \(levelId): \(score)")
        }
        
        // Update user profile
        userProfile.updateStatistics(
            score: score,
            accuracy: calculateAccuracyForLevel(score),
            levelCompleted: completed,
            isPerfect: isLevelPerfect(score),
            playTime: calculatePlayTime()
        )
        
        // If level was completed, update progress to next level
        if completed {
            let nextLevelId = levelId + 1
            print("🎯 Nivel \(levelId) completado! Actualizando progreso a nivel \(nextLevelId)")
            
            // Check if the next level exists before updating
            if levelExists(nextLevelId) {
                if nextLevelId > userProfile.statistics.currentLevel {
                    userProfile.statistics.currentLevel = nextLevelId
                    print("⬆️ Avanzando al siguiente nivel: \(nextLevelId)")
                }
            } else {
                // The player has completed all available levels
                print("🏆 ¡Felicidades! Has completado todos los niveles disponibles")
                userProfile.hasCompletedAllLevels = true
            }
        }
        
        userProfile.save()
    }
    
    // MARK: - Helper Methods
    private func calculateAccuracyForLevel(_ score: Int) -> Double {
        guard let level = currentLevel, level.requiredScore > 0 else { return 0.0 }
        return Double(score) / Double(level.requiredScore)
    }

    private func isLevelPerfect(_ score: Int) -> Bool {
        guard let level = currentLevel else { return false }
        let perfectThreshold = level.requiredScore * 3 / 2 // 150% del score requerido
        return score >= perfectThreshold
    }
    
    private func calculatePlayTime() -> TimeInterval {
        // Implementar lógica para calcular el tiempo de juego de la sesión actual
        return 60.0 // Por ahora retornamos un valor fijo de 1 minuto
    }
    
    // MARK: - Level Information
    func getLevelInfo(_ levelId: Int) -> (name: String, highScore: Int)? {
        guard let level = gameConfig?.levels.first(where: { level in
            level.levelId == levelId
        }) else {
            return nil
        }
        
        return (level.name, highScores[levelId] ?? 0)
    }
    
    func getNextUnlockedLevel() -> Int? {
        // El nivel actual siempre está desbloqueado
        let currentLevel = userProfile.statistics.currentLevel
        if !hasCompletedLevel(currentLevel) {
            return currentLevel
        }
        return nil
    }
    
    func hasCompletedLevel(_ levelId: Int) -> Bool {
        guard let level = gameConfig?.levels.first(where: { level in
            level.levelId == levelId
        }) else {
            return false
        }
        
        let currentScore = highScores[levelId] ?? 0
        return currentScore >= level.requiredScore
    }
    
    // MARK: - Level Configuration Access
    var accuracyThresholds: AccuracyThresholds? {
        gameConfig?.accuracyThresholds
    }
    
    var availableLevels: [GameLevel] {
        gameConfig?.levels ?? []
    }
    
    var currentLevelBlocks: [String: Block]? {
        currentLevel?.blocks
    }
    
    var currentLevelSpeed: FallingSpeed? {
        currentLevel?.fallingSpeed
    }
    
    var currentLevelStyles: [String]? {
        currentLevel?.allowedStyles
    }
    
    // MARK: - Game State Validation
    func isValidStyle(_ style: String) -> Bool {
        currentLevel?.allowedStyles.contains(style) ?? false
    }
    
    func getBlockConfig(for style: String) -> Block? {
        currentLevel?.blocks[style]
    }
    
    // MARK: - User Progress
    func resetProgress() {
        userProfile = UserProfile()
        userProfile.save()
        loadStatistics()
    }
    
    func getProgressSummary() -> String {
        """
        🎮 Partidas jugadas: \(totalGamesPlayed)
        🏆 Niveles completados: \(highScores.count)
        📊 Último nivel jugado: \(lastPlayedLevel)
        """
    }
    
}
