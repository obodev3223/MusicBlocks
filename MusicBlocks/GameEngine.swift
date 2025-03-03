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
    @Published var targetNote: MusicalNote?
    @Published var gameState: GameState = .playing
    @Published var noteState: NoteState = .waiting
    
    // MARK: - Private Properties
        private let tunerEngine: TunerEngine
        private let gameManager = GameManager.shared
        private var noteMatchTime: TimeInterval = 0
        private var maxExtraLives: Int = 0 // Se obtendrá del nivel actual
        private var scoreThresholdsForExtraLives: [Int] = [] // Se obtendrá del nivel actual
        
    
    // Constantes para tiempos
    private let requiredMatchTime: TimeInterval = 1.0
    private let errorDisplayTime: TimeInterval = 2.0
    private let noteGenerationDelay: TimeInterval = 2.0
    private let minimalNoteDetectionTime: TimeInterval = 0.5
    private let acceptableDeviation: Double = 10.0

    
    // Estado de detección de notas
    private let silenceThreshold: TimeInterval = 0.3
    private var lastSilenceTime: Date?
    private var currentNoteStartTime: Date?
    private var lastErrorTime: Date?
    private var isShowingError: Bool = false
    private var currentDetectedNote: MusicalNote?
    private var isInSuccessState: Bool = false
    
    // Umbrales de puntuación
    private struct ScoreThresholds {
        static let good = 0.60
        static let excellent = 0.80
        static let perfect = 0.95
    }
    
    private struct ScoreMultipliers {
        static let good = 1
        static let excellent = 2
        static let perfect = 3
    }
    
    private let baseScore = 100
    
    // MARK: - Types
    enum GameState {
        case playing
        case gameOver
    }
    
    enum NoteState: Equatable {
        case waiting
        case correct(deviation: Double)
        case wrong
        case success(multiplier: Int, message: String)
    }
    
    // MARK: - Initialization
    init(tunerEngine: TunerEngine = .shared) {
        self.tunerEngine = tunerEngine
        setupGame()
    }
    
    // MARK: - Public Methods
    func startNewGame() {
        // Resetear todo al empezar un nuevo juego
        score = 0
        lives = maxLives
        resetNoteDetection()
        isShowingError = false
        lastErrorTime = nil
        lastSilenceTime = nil
        noteMatchTime = 0
        currentDetectedNote = nil
        currentNoteStartTime = nil
        
        gameState = .playing
        generateNewNote()
    }
    
    func checkNote(currentNote: String, deviation: Double, isActive: Bool) {
        // No procesar nada si el juego no está activo o estamos en estado de éxito
        guard gameState == .playing && !isInSuccessState else { return }
        
        // Manejar el silencio
        if !isActive {
            if lastSilenceTime == nil {
                lastSilenceTime = Date()
            }
            
            if let silenceStart = lastSilenceTime,
               Date().timeIntervalSince(silenceStart) >= silenceThreshold {
                resetNoteDetection()
            }
            return
        }
        
        // Si hay señal activa, resetear el tiempo de silencio
        lastSilenceTime = nil
        
        guard let parsedNote = MusicalNote.parse(currentNote),
              let target = targetNote else {
            resetNoteDetection()
            return
        }
        
        // Si es una nota nueva diferente a la que estábamos detectando
        if currentDetectedNote?.fullName != parsedNote.fullName {
            currentDetectedNote = parsedNote
            currentNoteStartTime = Date()
            return
        }
        
        // Procesar la nota detectada
        if parsedNote == target {
            // Si la nota es correcta, siempre mostrar el estado correcto
            noteState = .correct(deviation: deviation)
            
            // Incrementar el tiempo de coincidencia
            noteMatchTime += 0.1
            
            // Si hemos mantenido la nota el tiempo suficiente, proceder al éxito
            if noteMatchTime >= requiredMatchTime {
                handleSuccess(deviation: deviation)
            }
        } else {
            handleWrongNote()
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
    
    
    private func generateNewNote() {
        guard !isShowingError && !isInSuccessState else { return }
        
        resetNoteDetection()
        targetNote = availableNotes.randomElement()
        noteState = .waiting
    }
    
    private func calculateAccuracy(deviation: Double) -> Double {
        let absDeviation = abs(deviation)
        
        // Siempre devolver un valor entre 0 y 1, incluso si la desviación es mayor
        // que la aceptable, para permitir diferentes niveles de puntuación
        if absDeviation > acceptableDeviation {
            return 0.0
        }
        
        return 1.0 - (absDeviation / acceptableDeviation)
    }
    
    private func calculateScore(accuracy: Double, blockBasePoints: Int) -> (score: Int, message: String) {
            guard let thresholds = gameManager.gameConfig?.accuracyThresholds else {
                return (blockBasePoints, "Good") // Valor por defecto si no hay configuración
            }
            
            if accuracy >= thresholds.perfect.threshold {
                return (Int(Double(blockBasePoints) * thresholds.perfect.multiplier), "Excelente!")
            } else if accuracy >= thresholds.excellent.threshold {
                return (Int(Double(blockBasePoints) * thresholds.excellent.multiplier), "Perfecto!")
            } else if accuracy >= thresholds.good.threshold {
                return (Int(Double(blockBasePoints) * thresholds.good.multiplier), "Bien")
            }
            
            return (0, "Fallo") // Sin puntuación si no alcanza el umbral mínimo
        }
    
    private func checkForExtraLife(currentScore: Int) {
        for threshold in scoreThresholdsForExtraLives {
            if currentScore >= threshold && lives < (gameManager.currentLevel?.lives.initial ?? 3) + maxExtraLives {
                lives += 1
                // Eliminar el threshold usado para no dar vidas extra repetidas
                if let index = scoreThresholdsForExtraLives.firstIndex(of: threshold) {
                    scoreThresholdsForExtraLives.remove(at: index)
                }
                break
            }
        }
    }
    
    private func handleWrongNote() {
        guard !isShowingError else { return }
        
        isShowingError = true
        lastErrorTime = Date()
        noteState = .wrong
        lives -= 1
        
        if lives <= 0 {
            gameState = .gameOver
            stopGame()
            return
        }
        
        // Solo programar nueva nota si el juego sigue activo
        DispatchQueue.main.asyncAfter(deadline: .now() + errorDisplayTime + noteGenerationDelay) { [weak self] in
            guard let self = self, self.gameState == .playing else { return }
            self.isShowingError = false
            self.generateNewNote()
        }
    }
    
    private func handleSuccess(deviation: Double, blockConfig: Block) {
        isInSuccessState = true
        
        // Calcular la precisión y la puntuación
        let accuracy = calculateAccuracy(deviation: deviation)
        let (scorePoints, message) = calculateScore(accuracy: accuracy, blockBasePoints: blockConfig.basePoints)
        
        // Actualizar puntuación
        score += scorePoints
        
        // Comprobar si corresponde vida extra
        checkForExtraLife(currentScore: score)
        
        // Actualizar el estado con el mensaje
        noteState = .success(multiplier: scorePoints / blockConfig.basePoints, message: message)
        
        // Programar la siguiente nota
        DispatchQueue.main.asyncAfter(deadline: .now() + noteGenerationDelay) { [weak self] in
            guard let self = self else { return }
            self.isInSuccessState = false
            self.generateNewNote()
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self,
                  self.gameState == .playing else { return }
            self.generateNewNote()
        }
    }
    
    private func stopGame() {
        // Limpiar todos los estados
        resetNoteDetection()
        isShowingError = false
        lastErrorTime = nil
        targetNote = nil
        lastSilenceTime = nil
        noteMatchTime = 0
        currentDetectedNote = nil
        currentNoteStartTime = nil
        
        // Mantener score y lives para mostrarlos en GameOver
        gameState = .gameOver
    }
}
