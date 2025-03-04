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
    var gameConfig: GameConfig?
    var currentLevel: GameLevel?
    
    private init() {
        loadGameConfig()
    }
    
    // MARK: - Configuration Loading
    private func loadGameConfig() {
        gameConfig = GameLevelProcessor.loadGameLevelsFromFile()
    }
    
    // MARK: - Level Management
    func loadLevel(_ levelId: Int) -> Bool {
            guard let config = gameConfig else {
                print("Error: No se pudo cargar la configuración del juego")
                return false
            }
            
            // Intentar cargar el nivel solicitado
            if let level = GameLevelProcessor.getLevel(from: config, withId: levelId) {
                currentLevel = level
                print("Nivel \(levelId) cargado correctamente")
                return true
            }
            
            // Si no se encuentra el nivel solicitado, cargar el tutorial
            if let tutorialLevel = GameLevelProcessor.getLevel(from: config, withId: 0) {
                currentLevel = tutorialLevel
                print("Cargando nivel tutorial por defecto")
                return true
            }
            
            print("Error: No se pudo cargar ningún nivel")
            return false
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
