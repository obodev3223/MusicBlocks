//
//  MusicalNoteModel.swift
//  MusicBlocks
//
//  Created by Jose R. García on 11/2/25.
//
/// Modelo que gestiona toda la lógica relacionada con notas musicales
/// 
import Foundation

struct MusicalNoteModel {
    /// Enumeración para el tipo de alteración
    enum Alteration: String {
        case sharp = "#"    /// Sostenido
        case flat = "♭"     /// Bemol
        case natural = ""   /// Natural
    }
    
    /// Estructura que representa una nota musical
    struct Note: Equatable, Identifiable {
        let id = UUID()
        let name: String
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
    
    /// Generador de notas disponibles
    static func generateAvailableNotes() -> [Note] {
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
        
        // Notas de la octava 4 y 5 (todas)
        for octave in 4...5 {
            ["DO", "RE", "MI", "FA", "SOL", "LA", "SI"].forEach { name in
                addNote(name, octave: octave)
            }
        }
        
        // Nota DO de la octava 6
        addNote("DO", octave: 6)
        
        return notes
    }
    
    /// Parser de notas desde string
    static func parseNote(_ noteString: String) -> Note? {
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
}
