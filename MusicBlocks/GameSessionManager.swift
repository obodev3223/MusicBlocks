//
//  GameSessionManager.swift
//  MusicBlocks
//
//  Created on 4/4/25.
//

import Foundation
import SpriteKit

/// El `GameSessionManager` se encarga de gestionar la sesión actual de juego, 
/// coordinando la interacción entre el motor de juego, el administrador de bloques
/// y el gestor de UI.
class GameSessionManager {
    // MARK: - Propiedades
    let gameManager = GameManager.shared
    let audioController = AudioController.sharedInstance
    let uiSoundController = UISoundController.shared
    
    private weak var scene: SKScene?
    private weak var gameEngine: GameEngine!
    private weak var blocksManager: BlocksManager!
    private weak var uiManager: GameUIManager!
    private var objectiveTracker: LevelObjectiveTracker? // Eliminado el weak
    
    // MARK: - Inicialización
    init(scene: SKScene, gameEngine: GameEngine, blocksManager: BlocksManager, uiManager: GameUIManager) {
        self.scene = scene
        self.gameEngine = gameEngine
        self.blocksManager = blocksManager
        self.uiManager = uiManager
        self.objectiveTracker = uiManager.objectiveTracker
    }
    
    // MARK: - Gestión de Nivel
    func setupGame() {
        let userProfile = UserProfile.load()
        let targetLevelId = userProfile.statistics.currentLevel
        
        // Verificar si el jugador ha completado todos los niveles
        if userProfile.hasCompletedAllLevels {
            print("🏆 El jugador ha completado todos los niveles disponibles")
            showAllLevelsCompletedOverlay(userProfile: userProfile, targetLevelId: targetLevelId)
            return
        }
        
        print("📋 Intentando cargar nivel \(targetLevelId) (nivel actual: \(gameManager.currentLevel?.levelId ?? -1))")
        
        // Solo cargar si es necesario
        if gameManager.currentLevel == nil || gameManager.currentLevel?.levelId != targetLevelId {
            print("🔄 Necesario cargar nuevo nivel...")
            loadLevel(targetLevelId)
        } else {
            print("ℹ️ Usando nivel ya cargado: \(gameManager.currentLevel?.levelId ?? -1)")
            resetExistingLevel()
        }
        
        // Iniciar el nivel si está cargado
        if let currentLevel = gameManager.currentLevel {
            startLevel(currentLevel)
        }
    }
    
    private func loadLevel(_ levelId: Int) {
        if gameManager.loadLevel(levelId) {
            print("✅ Nivel \(levelId) cargado correctamente")
        } else {
            print("⚠️ Error al cargar nivel \(levelId), intentando cargar nivel 1")
            if gameManager.loadLevel(1) {
                print("✅ Nivel 1 cargado como respaldo")
            } else {
                print("❌ Error crítico: No se pudo cargar ningún nivel")
                return
            }
        }
        
        // Crear un nuevo tracker para el nivel cargado
        if let currentLevel = gameManager.currentLevel {
            print("🎯 Creando nuevo tracker de objetivos para nivel \(currentLevel.levelId)")
            self.objectiveTracker = LevelObjectiveTracker(level: currentLevel)
            gameEngine.objectiveTracker = self.objectiveTracker
            uiManager.objectiveTracker = self.objectiveTracker
        }
    }
    
    private func resetExistingLevel() {
        // Resetear el tracker existente si ya existe uno
        if objectiveTracker != nil {
            print("🔄 Reseteando tracker de objetivos existente")
            objectiveTracker?.resetProgress()
        } else if let currentLevel = gameManager.currentLevel {
            print("🎯 Creando tracker de objetivos para nivel ya cargado")
            self.objectiveTracker = LevelObjectiveTracker(level: currentLevel)
            gameEngine.objectiveTracker = self.objectiveTracker
            uiManager.objectiveTracker = self.objectiveTracker
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
        
        // Asegurar que todos los managers estén correctamente enlazados
        if objectiveTracker !== gameEngine.objectiveTracker {
            print("⚠️ Corrigiendo desincronización en objectiveTracker")
            gameEngine.objectiveTracker = objectiveTracker
        }
        
        // Crear una secuencia de acciones para iniciar todo de manera ordenada
        guard let scene = scene else { return }
        
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
        }
        
        let waitForAudioAction = SKAction.wait(forDuration: 0.3)
                
        let startBlocksAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.blocksManager.startBlockGeneration()
            print("✅ Generación de bloques iniciada")
            
            // Establecer el maxDuration inicial basado en el primer bloque
            if let firstBlock = self.blocksManager.getCurrentBlock() {
                self.uiManager.stabilityIndicatorNode.setMaxDuration(firstBlock.requiredTime)
            }
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
        scene.run(startupSequence)
    }
    
    func navigateToMainMenu() {
        print("🏠 Navigating to main menu...")
        
        // Reproducir sonido de botón
        uiSoundController.playUISound(.buttonTap)
        
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
    
    // MARK: - Gestión de Overlays
    private func showAllLevelsCompletedOverlay(userProfile: UserProfile, targetLevelId: Int) {
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
                    updatedProfile.statistics.currentLevel = 1 // Back to tutorial
                    updatedProfile.save()
                    self?.setupGame()
                },
                onMenu: { [weak self] in
                    self?.navigateToMainMenu()
                }
            )
        }
    }
}
