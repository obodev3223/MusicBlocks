//
//  GameEngine.swift
//  MusicBlocks
//
//  Created by Jose R. García on 14/2/25.
//

import Foundation

class GameEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var score: Int = 0
    @Published var lives: Int = 0 // Se inicializará con el valor del nivel
    @Published var gameState: GameState = .playing
    @Published var noteState: NoteState = .waiting
    
    // MARK: - Private Properties
    private let tunerEngine: TunerEngine
    private let gameManager = GameManager.shared
    private weak var blockManager: BlocksManager?
    private var noteMatchTime: TimeInterval = 0
    private var maxExtraLives: Int = 0 // Se obtendrá del nivel actual
    private var scoreThresholdsForExtraLives: [Int] = [] // Se obtendrá del nivel actual
    
    // Constantes para tiempos
    private let errorDisplayTime: TimeInterval = 2.0
    private let silenceThreshold: TimeInterval = 0.3
    private let minimalNoteDetectionTime: TimeInterval = 0.5
    private let acceptableDeviation: Double = 10.0
    
    // Estado de detección de notas
    private var lastSilenceTime: Date?
    private var currentNoteStartTime: Date?
    private var lastErrorTime: Date?
    private var isShowingError: Bool = false
    private var currentDetectedNote: MusicalNote?
    private var isInSuccessState: Bool = false
    
    // Propiedades para el tracking
    private var currentTargetNote: String?
    private var currentTargetConfig: Block?
    private var noteHoldStartTime: Date?
    private var requiredHoldTime: TimeInterval = 0
    private var currentHits: Int = 0
    private var requiredHits: Int = 0
    
    // Propiedad para el nivel actual
    var currentLevel: GameLevel? {
        gameManager.currentLevel
    }
    
    // MARK: - Types
    enum GameState {
        case countdown     // Cuenta atrás inicial
        case playing      // Jugando
        case gameOver     // Fin del juego
    }
    
    enum NoteState: Equatable {
        case waiting
        case correct(deviation: Double)
        case wrong
        case success(multiplier: Int, message: String)
    }
    
    // MARK: - Initialization
    init(tunerEngine: TunerEngine = .shared, blockManager: BlocksManager?) {
            self.tunerEngine = tunerEngine
            self.blockManager = blockManager 
            gameState = .countdown
        }
    
    // MARK: - Public Methods
    func startNewGame() {
        guard let currentLevel = gameManager.currentLevel else { return }
        
        // Resetear todo al empezar un nuevo juego
        score = 0
        lives = currentLevel.lives.initial
        maxExtraLives = currentLevel.lives.extraLives.maxExtra
        scoreThresholdsForExtraLives = currentLevel.lives.extraLives.scoreThresholds
        
        resetNoteDetection()
        isShowingError = false
        lastErrorTime = nil
        lastSilenceTime = nil
        noteMatchTime = 0
        currentDetectedNote = nil
        currentNoteStartTime = nil
        
        // Iniciar en estado de cuenta atrás
        gameState = .playing // Cambiamos a playing después de la cuenta atrás
    }
    
    // Método para inicializar el juego
    func initialize(withLevel level: GameLevel) {
            print("Inicializando GameEngine con nivel: \(level.levelId)")

            // Asegurarnos de que GameManager tiene el nivel correcto
            if gameManager.currentLevel?.levelId != level.levelId {
                _ = gameManager.loadLevel(level.levelId)
            }
            
            // Inicializar el resto de propiedades
            lives = level.lives.initial
            maxExtraLives = level.lives.extraLives.maxExtra
            scoreThresholdsForExtraLives = level.lives.extraLives.scoreThresholds
            gameState = .countdown
            
            // Reset de estado
            score = 0
            isShowingError = false
            lastErrorTime = nil
            lastSilenceTime = nil
            noteMatchTime = 0
            currentDetectedNote = nil
            currentNoteStartTime = nil
            
            print("GameEngine inicializado con nivel \(level.levelId)")
            print("Vidas iniciales: \(lives)")
            print("Vidas extra máximas: \(maxExtraLives)")
        }
    
    
    func checkNote(currentNote: String, deviation: Double, isActive: Bool) {
        guard gameState == .playing && !isInSuccessState && !isShowingError else {
            print("🔒 GameEngine - No procesando: playing=\(gameState == .playing), success=\(isInSuccessState), error=\(isShowingError)")
            return
        }
        
        guard let currentBlock = blockManager?.getCurrentBlock(),
              isActive else {
            print("⚠️ GameEngine - Sin bloque actual o audio inactivo")
            return
        }
        
        print("🎯 GameEngine - Comparando notas:")
        print("   Detectada: \(currentNote)")
        print("   Objetivo: \(currentBlock.note)")
        print("   Desviación: \(deviation)")
        
        if currentNote == currentBlock.note {
            print("✅ Nota correcta")
            if blockManager?.updateCurrentBlockProgress(hitTime: Date()) == true {
                print("🎉 Bloque completado")
                handleSuccess(deviation: deviation, blockConfig: currentBlock.config)
            } else {
                print("⏳ Manteniendo nota correcta")
                noteState = .correct(deviation: deviation)
            }
        } else {
            print("❌ Nota incorrecta")
            blockManager?.resetCurrentBlockProgress()
            handleWrongNote()
        }
    }
    
    private func resetNoteTracking() {
            noteHoldStartTime = nil
            currentHits = 0
            if !isShowingError && !isInSuccessState {
                noteState = .waiting
            }
        }
    
    // MARK: - Game Setup
    private func setupGame() {
        guard let currentLevel = gameManager.currentLevel else {
            print("Error: No hay nivel actual configurado")
            return
        }
        
        // Inicializar vidas desde la configuración del nivel
        lives = currentLevel.lives.initial
        
        // Configurar vidas extra
        maxExtraLives = currentLevel.lives.extraLives.maxExtra
        scoreThresholdsForExtraLives = currentLevel.lives.extraLives.scoreThresholds
        
        startNewGame()
    }
    
    private func calculateAccuracy(deviation: Double) -> Double {
        let absDeviation = abs(deviation)
        if absDeviation > acceptableDeviation {
            return 0.0
        }
        return 1.0 - (absDeviation / acceptableDeviation)
    }
    
    private func calculateScore(accuracy: Double, blockBasePoints: Int) -> (score: Int, message: String) {
        guard let thresholds = gameManager.gameConfig?.accuracyThresholds else {
            return (blockBasePoints, "Bien")
        }
        
        if accuracy >= thresholds.perfect.threshold {
            return (Int(Double(blockBasePoints) * thresholds.perfect.multiplier), "¡Perfecto!")
        } else if accuracy >= thresholds.excellent.threshold {
            return (Int(Double(blockBasePoints) * thresholds.excellent.multiplier), "¡Excelente!")
        } else if accuracy >= thresholds.good.threshold {
            return (Int(Double(blockBasePoints) * thresholds.good.multiplier), "¡Bien!")
        }
        
        return (0, "Fallo")
    }
    
    private func checkForExtraLife(currentScore: Int) {
        for threshold in scoreThresholdsForExtraLives {
            if currentScore >= threshold && lives < (currentLevel?.lives.initial ?? 3) + maxExtraLives {
                lives += 1
                print("¡Vida extra ganada! Vidas actuales: \(lives)")
                
                // Eliminar el threshold usado
                if let index = scoreThresholdsForExtraLives.firstIndex(of: threshold) {
                    scoreThresholdsForExtraLives.remove(at: index)
                }
                break
            }
        }
    }
    
    private func handleSuccess(deviation: Double, blockConfig: Block) {
            isInSuccessState = true
            
            // Calcular puntuación
            let accuracy = calculateAccuracy(deviation: deviation)
            let (scorePoints, message) = calculateScore(accuracy: accuracy, blockBasePoints: blockConfig.basePoints)
            
            // Actualizar puntuación
            score += scorePoints
            
            // Comprobar vidas extra
            checkForExtraLife(currentScore: score)
            
            // Notificar éxito
            noteState = .success(multiplier: scorePoints / blockConfig.basePoints, message: message)
            
            // Eliminar el bloque
            blockManager?.removeLastBlock()
            
            // Resetear tracking después de un breve delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                self.isInSuccessState = false
                self.resetNoteTracking()
                self.currentTargetNote = nil
                self.currentTargetConfig = nil
                self.noteState = .waiting
            }
        }
    
    private func handleWrongNote() {
            guard !isShowingError else { return }
            
            isShowingError = true
            lives -= 1
            noteState = .wrong
            
            // Verificar game over
            if lives <= 0 {
                gameState = .gameOver
                stopGame()
                return
            }
            
            // Resetear estado de error después de un tiempo
            DispatchQueue.main.asyncAfter(deadline: .now() + errorDisplayTime) { [weak self] in
                guard let self = self else { return }
                self.isShowingError = false
                self.resetNoteTracking()
                self.noteState = .waiting
            }
        }   
    
    
    private func resetNoteDetection() {
        currentDetectedNote = nil
        currentNoteStartTime = nil
        noteMatchTime = 0
        if !isShowingError && !isInSuccessState {
            noteState = .waiting
        }
    }
    
    private func handleFailure() {
        lives -= 1
        
        if lives <= 0 {
            gameState = .gameOver
            stopGame()
            return
        }
        
        // Ya no necesitamos generar una nueva nota
        // solo restablecer el estado para seguir detectando
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self,
                  self.gameState == .playing else { return }
            self.resetNoteDetection()
            self.noteState = .waiting
        }
    }
    
    private func stopGame() {
        // Limpiar todos los estados
        resetNoteDetection()
        isShowingError = false
        lastErrorTime = nil
        lastSilenceTime = nil
        noteMatchTime = 0
        currentDetectedNote = nil
        currentNoteStartTime = nil
        
        // Mantener score y lives para mostrarlos en GameOver
        gameState = .gameOver
    }
}
