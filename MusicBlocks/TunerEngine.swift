//
//  TunerEngine.swift
//  MusicBlocks
//
//  Created by Jose R. García on 13/2/25.
//
/// TunerEngine: Motor central para el procesamiento de notas musicales y afinación
///
/// Características principales:
/// - Genera notas aleatorias para práctica
/// - Procesa frecuencias para obtener notas y desviaciones
/// - Mantiene la lógica de afinación centralizada
/// - Proporciona estructuras de datos consistentes
///
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
    
    // MARK: - Public Methods
        /// Procesa una frecuencia y amplitud para obtener datos de afinación
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
        
        /// Parsea una nota desde string
        func parseNote(_ noteString: String) -> MusicalNote? {
            return MusicalNote.parse(noteString)
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
