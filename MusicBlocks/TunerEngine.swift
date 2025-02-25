//
//  TunerEngine.swift
//  FrikiTuner
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
        let note: String          // Nota con alteración y octava (ej: "LA4", "DO#5")
        let frequency: Float      // Frecuencia en Hz
        let deviation: Double     // Desviación en cents
        let isActive: Bool        // Si hay suficiente amplitud para detectar
        
        static let inactive = TunerData(note: "-", frequency: 0, deviation: 0, isActive: false)
    }
    
    struct Note: Equatable, Identifiable {
        let id = UUID()
        let name: String         // Nombre de la nota (DO, RE, MI, etc.)
        let alteration: Alteration
        let octave: Int
        
        var fullName: String {
            "\(name)\(alteration.rawValue)\(octave)"
        }
        
        static func == (lhs: Note, rhs: Note) -> Bool {
            return lhs.fullName == rhs.fullName || lhs.isEnharmonicWith(rhs)
        }
        
        func isEnharmonicWith(_ other: Note) -> Bool {
            let enharmonics: [String: String] = [
                "DO#": "RE♭", "RE♭": "DO#",
                "RE#": "MI♭", "MI♭": "RE#",
                "FA#": "SOL♭", "SOL♭": "FA#",
                "SOL#": "LA♭", "LA♭": "SOL#",
                "LA#": "SI♭", "SI♭": "LA#"
            ]
            
            let thisNote = "\(name)\(alteration.rawValue)"
            let otherNote = "\(other.name)\(other.alteration.rawValue)"
            
            return enharmonics[thisNote] == otherNote && octave == other.octave
        }
    }
    
    enum Alteration: String {
        case sharp = "#"
        case flat = "♭"
        case natural = ""
    }
    
    // MARK: - Properties
    
    private let concertPitch: Double = 442.0
    private let availableNotes: [Note]
    
    // MARK: - Initialization
    
    private init() {
        self.availableNotes = TunerEngine.generateAvailableNotes()
    }
    
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
    
    /// Genera una nota aleatoria para práctica
    func generateRandomNote() -> Note? {
        return availableNotes.randomElement()
    }
    
    /// Parsea una nota desde string
    func parseNote(_ noteString: String) -> Note? {
        let pattern = "([A-Z]+)([#♭]?)([0-9])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        if let match = regex?.firstMatch(in: noteString, options: [], range: NSRange(noteString.startIndex..., in: noteString)) {
            let name = String(noteString[Range(match.range(at: 1), in: noteString)!])
            let alterationString = String(noteString[Range(match.range(at: 2), in: noteString)!])
            let octave = Int(String(noteString[Range(match.range(at: 3), in: noteString)!]))!
            
            let alteration: Alteration = alterationString == "#" ? .sharp :
                                       alterationString == "♭" ? .flat : .natural
            
            return Note(name: name, alteration: alteration, octave: octave)
        }
        return nil
    }
    
    // MARK: - Private Methods
    
    private static func generateAvailableNotes() -> [Note] {
        var notes: [Note] = []
        
        func addNote(_ name: String, octave: Int) {
            notes.append(Note(name: name, alteration: .natural, octave: octave))
            
            switch name {
            case "DO": notes.append(Note(name: name, alteration: .sharp, octave: octave))
            case "RE":
                notes.append(Note(name: name, alteration: .flat, octave: octave))
                notes.append(Note(name: name, alteration: .sharp, octave: octave))
            case "MI": notes.append(Note(name: name, alteration: .flat, octave: octave))
            case "FA": notes.append(Note(name: name, alteration: .sharp, octave: octave))
            case "SOL":
                notes.append(Note(name: name, alteration: .flat, octave: octave))
                notes.append(Note(name: name, alteration: .sharp, octave: octave))
            case "LA":
                notes.append(Note(name: name, alteration: .flat, octave: octave))
                notes.append(Note(name: name, alteration: .sharp, octave: octave))
            case "SI": notes.append(Note(name: name, alteration: .flat, octave: octave))
            default: break
            }
        }
        
        // Notas de la octava 3 (empezando desde LA)
        ["LA", "SI"].forEach { name in
            addNote(name, octave: 3)
        }
        
        // Notas de la octava 4 y 5
        for octave in 4...5 {
            ["DO", "RE", "MI", "FA", "SOL", "LA", "SI"].forEach { name in
                addNote(name, octave: octave)
            }
        }
        
        // Nota DO de la octava 6
        addNote("DO", octave: 6)
        
        return notes
    }
    
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
    
    private func getNoteNameAndAlteration(forMIDINote index: Int) -> (String, Alteration) {
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
