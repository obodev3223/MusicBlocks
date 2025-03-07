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
        totalGamesPlayed = userProfile.statistics.gamesPlayed
        highScores = userProfile.statistics.highScores
        lastPlayedLevel = userProfile.statistics.currentLevel
    }
    
    // MARK: - Level Management
    func loadLevel(_ levelId: Int) -> Bool {
        guard let config = gameConfig else {
            print("❌ Error: No se pudo cargar la configuración del juego")
            return false
        }
        
        // Verificar si el nivel está desbloqueado
        if !isLevelUnlocked(levelId) {
            print("🔒 Nivel \(levelId) bloqueado")
            return false
        }
        
        // Intentar cargar el nivel solicitado
        if let level = GameLevelProcessor.getLevel(from: config, withId: levelId) {
            currentLevel = level
            lastPlayedLevel = levelId
            userProfile.statistics.currentLevel = levelId
            userProfile.save()
            
            print("✅ Nivel \(levelId) cargado: \(level.name)")
            return true
        }
        
        // Si falla, intentar cargar el tutorial
        if let tutorialLevel = GameLevelProcessor.getLevel(from: config, withId: Constants.tutorialLevelId) {
            currentLevel = tutorialLevel
            print("ℹ️ Cargando tutorial por defecto")
            return true
        }
        
        print("❌ Error: No se pudo cargar ningún nivel")
        return false
    }
    
    func isLevelUnlocked(_ levelId: Int) -> Bool {
        // El tutorial siempre está desbloqueado
        if levelId == Constants.tutorialLevelId { return true }
        
        // Verificar progreso del usuario
        let previousLevelCompleted = highScores[levelId - 1] != nil
        return levelId <= Constants.maxUnlockedLevel && previousLevelCompleted
    }
    
    // MARK: - Game Progress
    func updateGameStatistics(levelId: Int, score: Int, completed: Bool) {
        // Actualizar estadísticas
        totalGamesPlayed += 1
        
        // Actualizar high score si es necesario
        if let currentHighScore = highScores[levelId] {
            if score > currentHighScore {
                highScores[levelId] = score
                print("🏆 Nuevo récord en nivel \(levelId): \(score)")
            }
        } else {
            highScores[levelId] = score
            print("🎮 Primera puntuación en nivel \(levelId): \(score)")
        }
        
        // Actualizar perfil de usuario
        userProfile.statistics.gamesPlayed = totalGamesPlayed
        userProfile.statistics.highScores = highScores
        
        // Si completó el nivel, desbloquear el siguiente
        if completed && levelId < Constants.maxUnlockedLevel {
            print("🎉 Nivel \(levelId) completado, desbloqueando siguiente nivel")
            userProfile.statistics.unlockedLevels.insert(levelId + 1)
        }
        
        userProfile.save()
    }
    
    // MARK: - Level Information
    func getLevelInfo(_ levelId: Int) -> (name: String, highScore: Int)? {
        guard let level = gameConfig?.levels.first(where: { $level in
            $level.levelId == levelId
        }) else {
            return nil
        }
        
        return (level.name, highScores[levelId] ?? 0)
    }
    
    func getNextUnlockedLevel() -> Int? {
        let unlockedLevels = userProfile.statistics.unlockedLevels
        return unlockedLevels.sorted().first { levelId in
            !hasCompletedLevel(levelId)
        }
    }
    
    func hasCompletedLevel(_ levelId: Int) -> Bool {
        guard let level = gameConfig?.levels.first(where: { $level in
            $level.levelId == levelId
        }) else {
            return false
        }
        
        return highScores[levelId] ?? 0 >= level.requiredScore
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
