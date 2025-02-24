//
//  GameEngine.swift
//  FrikiTuner
//
//  Created by Jose R. García on 14/2/25.
//

import Foundation

class GameEngine: ObservableObject {
    // MARK: - Published Properties
    @Published var score: Int = 0
    @Published var lives: Int = 3
    @Published var targetNote: TunerEngine.Note?
    @Published var gameState: GameState = .playing
    @Published var noteState: NoteState = .waiting
    
    // MARK: - Public Properties
    let maxLives: Int = 3
    
    // MARK: - Private Properties
    private let tunerEngine: TunerEngine
    
    private var noteMatchTime: TimeInterval = 0
    
    // Constantes para tiempos
    private let requiredMatchTime: TimeInterval = 1.0
    private let errorDisplayTime: TimeInterval = 2.0  // Tiempo que se muestra el error
    private let noteGenerationDelay: TimeInterval = 2.0  // Tiempo antes de generar nueva nota
    private let minimalNoteDetectionTime: TimeInterval = 0.5  // Tiempo mínimo para considerar una nota
    private let acceptableDeviation: Double = 10.0
    
    // Añadir umbral de tiempo para confirmar silencio
    private let silenceThreshold: TimeInterval = 0.3
    private var lastSilenceTime: Date?
    
    // Estado de detección de notas
    private var currentNoteStartTime: Date?
    private var lastErrorTime: Date?
    private var isShowingError: Bool = false
    private var currentDetectedNote: TunerEngine.Note?
    private var isInSuccessState: Bool = false
    
    // Añadir constantes para los umbrales de puntuación
    private struct ScoreThresholds {
        static let good = 0.60     // 60% de precisión
        static let excellent = 0.80 // 80% de precisión
        static let perfect = 0.95   // 95% de precisión
    }

    private struct ScoreMultipliers {
        static let good = 1      // x1 para buena afinación
        static let excellent = 2 // x2 para excelente afinación
        static let perfect = 3   // x3 para afinación perfecta
    }
    
    // Puntuación base por nota correcta
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
        
        guard let parsedNote = tunerEngine.parseNote(currentNote),
              let target = targetNote else {
            resetNoteDetection()
            return
        }
        
        // Si es una nota nueva diferente a la que estábamos detectando
        if currentDetectedNote != parsedNote {
            currentDetectedNote = parsedNote
            currentNoteStartTime = Date()
            return
        }
        
        // Verificar el tiempo mínimo de detección
        guard let startTime = currentNoteStartTime,
              Date().timeIntervalSince(startTime) >= minimalNoteDetectionTime else {
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
    
    // MARK: - Private Methods
    private func setupGame() {
        startNewGame()
    }
    
    private func generateNewNote() {
        guard !isShowingError && !isInSuccessState else { return }
        
        resetNoteDetection()
        targetNote = tunerEngine.generateRandomNote()
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

    private func getScoreMultiplier(accuracy: Double) -> (Int, String) {
        if accuracy >= ScoreThresholds.perfect {
            return (ScoreMultipliers.perfect, "Excelente")
        } else if accuracy >= ScoreThresholds.excellent {
            return (ScoreMultipliers.excellent, "Perfecto")
        } else if accuracy >= ScoreThresholds.good {
            return (ScoreMultipliers.good, "Bien")
        }
        return (1, "Bien")  // Valor por defecto en lugar de (0, "")
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
    
    private func handleSuccess(deviation: Double) {
        isInSuccessState = true
        
        // Calcular la precisión y el multiplicador
        let accuracy = calculateAccuracy(deviation: deviation)
        let (multiplier, message) = getScoreMultiplier(accuracy: accuracy)
        
        // Solo sumar puntuación si hay multiplicador
        if multiplier > 0 {
            let finalScore = baseScore * multiplier
            score += finalScore
        }
        
        // Actualizar el estado con el mensaje y multiplicador
        noteState = .success(multiplier: multiplier, message: message)
        
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
