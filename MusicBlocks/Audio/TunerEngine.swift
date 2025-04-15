//
//  TunerEngine.swift
//  MusicBlocks
//
//  Created by Jose R. García on 13/3/25.
//  Actualización: Se añade la lógica de acumulación para el hold de la nota.
//

import Foundation

class TunerEngine {
    static let shared = TunerEngine()
    
    // MARK: - Properties para debounce
    private var lastSuccessTime: Date? = nil
    private let minimumSuccessInterval: TimeInterval = 1.0 // 1 segundo entre detecciones exitosas
    
    // MARK: - Types
    struct TunerData {
        let note: String          // Nota con alteración y octava
        let frequency: Float      // Frecuencia en Hz
        let deviation: Double     // Desviación en cents
        let isActive: Bool        // Si hay suficiente amplitud para detectar
        
        static let inactive = TunerData(note: "-", frequency: 0, deviation: 0, isActive: false)
    }
    
    // MARK: - Properties
    private let concertPitch: Double = 442.0
    
    // Propiedades para la acumulación del hold
    private var noteHoldAccumulator: TimeInterval = 0
    private var lastDetectionTime: TimeInterval? = nil
    private var currentStableNote: String = "-"
    
    // Constantes
    private let maxAcceptableDeviation: Double = 50.0  // Un cuarto de tono en cents (~50 cents)
    
    // MARK: - Public Methods
    /// Procesa una frecuencia y amplitud para obtener datos de afinación.
    func processPitch(frequency: Float, amplitude: Float) -> TunerData {
        let minAmplitude: Float = 0.05
        
        guard amplitude > minAmplitude else {
            return .inactive
        }
        
        let (note, deviation) = processFrequency(frequency)
        return TunerData(
            note: note,
            frequency: frequency,
            deviation: deviation,
            isActive: true
        )
    }
    
    /// Parsea una nota desde un string.
    func parseNote(_ noteString: String) -> MusicalNote? {
        return MusicalNote.parse(noteString)
    }
    
    /// Actualiza el acumulador de "hold" para la nota detectada.
    /// - Parameters:
    ///   - note: La nota detectada en este frame.
    ///   - currentTime: El timestamp actual.
    ///   - requiredHoldTime: El tiempo requerido (en segundos) para considerar que la nota se ha mantenido estable.
    /// - Returns: true si el acumulador alcanza o supera el tiempo requerido; false en caso contrario.
    func updateHoldDetection(note: String, currentTime: TimeInterval, requiredHoldTime: TimeInterval) -> Bool {
        // Si la nota actual es la misma que la nota estable (o muy cercana), incrementar el acumulador
        if isNoteWithinTolerance(note, currentStableNote) {
            if let lastTime = lastDetectionTime {
                noteHoldAccumulator += (currentTime - lastTime)
            }
        } else {
            // Es una nota diferente, reiniciar acumulador
            GameLogger.shared.audioDetection("🔄 TunerEngine - Cambio de nota: \(currentStableNote) -> \(note), reiniciando acumulador")
            currentStableNote = note
            noteHoldAccumulator = 0
        }
        lastDetectionTime = currentTime
        
        // Mensaje de debug para seguir el acumulador
        GameLogger.shared.audioDetection("📊 TunerEngine - Nota detectada: \(note), acumulador de hold: \(noteHoldAccumulator.rounded(toDecimalPlaces: 2))/\(requiredHoldTime) segundos")
        
        // Solo se considera válida si:
        // 1. La nota no es un silencio ("-")
        // 2. Se ha mantenido el tiempo requerido
        // 3. Ha pasado suficiente tiempo desde el último éxito
        if note != "-" && noteHoldAccumulator >= requiredHoldTime {
            // Verificar tiempo desde último éxito
            let now = Date()
            if let lastSuccess = lastSuccessTime, now.timeIntervalSince(lastSuccess) < minimumSuccessInterval {
                // Aún no ha pasado suficiente tiempo desde el último éxito
                GameLogger.shared.audioDetection("⏱️ Detección ignorada - Muy pronto desde el último éxito (\(now.timeIntervalSince(lastSuccess))s)")
                return false
            }
            
            // Registrar este éxito
            lastSuccessTime = now
            print("✅ TunerEngine - ÉXITO: la nota \(note) se mantuvo estable por \(noteHoldAccumulator.rounded(toDecimalPlaces: 2)) segundos (requerido: \(requiredHoldTime) segundos)")
            noteHoldAccumulator = 0  // Reiniciar el acumulador al alcanzar el tiempo requerido
            return true
        }
        return false
    }
    
    // MARK: - Private Methods
    private func processFrequency(_ frequency: Float) -> (String, Double) {
        guard frequency > 0 else { return ("-", 0) }
        
        // Constantes para cálculo de notas
        let concertPitch: Double = 442.0
        let halfStepsFromA4 = 12 * log2(Double(frequency) / concertPitch)
        let roundedHalfSteps = round(halfStepsFromA4)
        let deviation = 100 * (halfStepsFromA4 - roundedHalfSteps)
        
        let midiNoteNumber = Int(roundedHalfSteps) + 69
        let octave = (midiNoteNumber / 12) - 1
        let noteIndex = ((midiNoteNumber % 12) + 12) % 12
        
        // Mapeo de índices a notas con sus posibles alteraciones
        let noteMapping: [(String, MusicalNote.Alteration)] = [
            ("DO", .natural),     // 0 - C
            ("DO", .sharp),       // 1 - C#
            ("RE", .natural),     // 2 - D
            ("RE", .sharp),       // 3 - D#
            ("MI", .natural),     // 4 - E
            ("FA", .natural),     // 5 - F
            ("FA", .sharp),       // 6 - F#
            ("SOL", .natural),    // 7 - G
            ("SOL", .sharp),      // 8 - G#
            ("LA", .natural),     // 9 - A
            ("LA", .sharp),       // 10 - A#
            ("SI", .natural)      // 11 - B
        ]
        
        // Determinar la nota más cercana con su alteración
        let (noteName, alteration) = noteMapping[noteIndex]
        
        return ("\(noteName)\(alteration.rawValue)\(octave)", deviation)
    }
    

    
    // MARK: - Nueva función para tolerancia a fluctuaciones
    /// Comprueba si dos notas son consideradas la misma con cierta tolerancia
    private func isNoteWithinTolerance(_ note1: String, _ note2: String) -> Bool {
        // Si es exactamente la misma nota
        if note1 == note2 {
            return true
        }
        
        // Si alguna es silencio, no son compatibles
        if note1 == "-" || note2 == "-" {
            return false
        }
        
        // Comparar bases de notas sin octava
        let baseNote1 = String(note1.prefix(while: { !$0.isNumber }))
        let baseNote2 = String(note2.prefix(while: { !$0.isNumber }))
        
        // Comprobar equivalentes enarmónicos (DO# = REb, etc.)
        let enharmonicPairs = [
            ["DO#", "RE♭"], ["RE#", "MI♭"],
            ["FA#", "SOL♭"], ["SOL#", "LA♭"], ["LA#", "SI♭"]
        ]
        
        for pair in enharmonicPairs {
            if (pair[0] == baseNote1 && pair[1] == baseNote2) ||
                (pair[1] == baseNote1 && pair[0] == baseNote2) {
                return true
            }
        }
        
        return false
    }
}

// Extensión útil para redondear números
extension TimeInterval {
    func rounded(toDecimalPlaces places: Int) -> TimeInterval {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
