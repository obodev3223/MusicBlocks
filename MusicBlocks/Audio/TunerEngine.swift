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
    
    // MARK: - Public Methods
    /// Procesa una frecuencia y amplitud para obtener datos de afinación.
    /// Este método se mantiene sin modificaciones ya que su función es la conversión.
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
        if note == currentStableNote {
            if let lastTime = lastDetectionTime {
                noteHoldAccumulator += (currentTime - lastTime)
            }
        } else {
            currentStableNote = note
            noteHoldAccumulator = 0
        }
        lastDetectionTime = currentTime
        
        // Mensaje de debug para seguir el acumulador
        print("TunerEngine - Nota detectada: \(note), acumulador de hold: \(noteHoldAccumulator) segundos")
        
        // Solo se considera válida si la nota no es un silencio ("-")
        if note != "-" && noteHoldAccumulator >= requiredHoldTime {
            print("TunerEngine - Éxito: la nota \(note) se mantuvo estable por \(noteHoldAccumulator) segundos (requerido: \(requiredHoldTime) segundos)")
            noteHoldAccumulator = 0  // Reiniciar el acumulador al alcanzar el tiempo requerido
            return true
        }
        return false
    }
    
    // MARK: - Private Methods
    private func processFrequency(_ frequency: Float) -> (String, Double) {
        guard frequency > 0 else { return ("-", 0) }
        
        let actualFrequency = Double(frequency)
        let halfStepsFromA4 = 12 * log2(actualFrequency / concertPitch)
        let roundedHalfSteps = round(halfStepsFromA4)
        let deviation = 100 * (halfStepsFromA4 - roundedHalfSteps)
        
        let midiNoteNumber = Int(roundedHalfSteps) + 69
        let octave = (midiNoteNumber / 12) - 1
        let noteIndex = ((midiNoteNumber % 12) + 12) % 12
        
        let (noteName, alteration) = getNoteNameAndAlteration(forMIDINote: noteIndex)
        return ("\(noteName)\(alteration.rawValue)\(octave)", deviation)
    }
    
    private func getNoteNameAndAlteration(forMIDINote index: Int) -> (String, MusicalNote.Alteration) {
        switch index {
        case 0: return ("DO", .natural)
        case 1: return Bool.random() ? ("DO", .sharp) : ("RE", .flat)
        case 2: return ("RE", .natural)
        case 3: return Bool.random() ? ("RE", .sharp) : ("MI", .flat)
        case 4: return ("MI", .natural)
        case 5: return ("FA", .natural)
        case 6: return Bool.random() ? ("FA", .sharp) : ("SOL", .flat)
        case 7: return ("SOL", .natural)
        case 8: return Bool.random() ? ("SOL", .sharp) : ("LA", .flat)
        case 9: return ("LA", .natural)
        case 10: return Bool.random() ? ("LA", .sharp) : ("SI", .flat)
        case 11: return ("SI", .natural)
        default: return ("", .natural)
        }
    }
}
