//
//  GameManager.swift
//  MusicBlocks
//
//  Created by Jose R. García on 3/3/25.
//

import Foundation

class GameManager {
    static let shared = GameManager()
    
    // Configuración general del juego
    private(set) var gameConfig: GameConfig?
    private(set) var currentLevel: GameLevel?
    
    private init() {
        loadGameConfig()
    }
    
    // MARK: - Configuration Loading
    private func loadGameConfig() {
        gameConfig = GameLevelProcessor.loadGameLevelsFromFile()
    }
    
    // MARK: - Level Management
    func loadLevel(_ levelId: Int) -> Bool {
        guard let config = gameConfig,
              let level = GameLevelProcessor.getLevel(from: config, withId: levelId) else {
            return false
        }
        currentLevel = level
        return true
    }
    
    // MARK: - Game Configuration Accessors
    var accuracyThresholds: AccuracyThresholds? {
        gameConfig?.accuracyThresholds
    }
    
    var availableLevels: [GameLevel] {
        gameConfig?.levels ?? []
    }
    
    // MARK: - Current Level Accessors
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
}