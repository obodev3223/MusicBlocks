//
//  MusicalNote.swift
//  MusicBlocks
//
//  Created by Jose R. García on 3/3/25.
//

import CoreGraphics
import Foundation

/// Sistema unificado para la gestión de notas musicales
struct MusicalNote: Equatable, Identifiable {
    // MARK: - Types
    enum Alteration: String {
        case sharp = "#"    /// Sostenido
        case flat = "♭"     /// Bemol
        case natural = ""   /// Natural
    }
    
    // MARK: - Properties
    let id = UUID()
    let name: String         // Nombre de la nota (DO, RE, MI, etc.)
    let alteration: Alteration
    let octave: Int
    
    // MARK: - Computed Properties
    var fullName: String {
        "\(name)\(alteration.rawValue)\(octave)"
    }
    
    var displayName: String {
        let baseName = name.capitalized
        return alteration == .natural ? baseName : "\(baseName)\(alteration.rawValue)"
    }
    
    /// Posición vertical de la nota en el pentagrama
    var staffOffset: CGPoint {
        let baseOffset: [String: CGFloat] = [
            "DO": -36,
            "RE": -30,
            "MI": -24,
            "FA": -18,
            "SOL": -12,
            "LA": -6,
            "SI": 0
        ]
        
        guard let offset = baseOffset[name] else { return .zero }
        return CGPoint(x: 0, y: offset + (CGFloat(octave - 4) * 42))
    }
    
    // MARK: - Static Properties
    private static let enharmonicEquivalents: [String: String] = [
        "DO#": "RE♭", "RE♭": "DO#",
        "RE#": "MI♭", "MI♭": "RE#",
        "FA#": "SOL♭", "SOL♭": "FA#",
        "SOL#": "LA♭", "LA♭": "SOL#",
        "LA#": "SI♭", "SI♭": "LA#"
    ]
    
    // MARK: - Static Methods
    /// Genera todas las notas disponibles en el rango del juego
    static func generateAvailableNotes() -> [MusicalNote] {
        var notes: [MusicalNote] = []
        
        func addNote(_ name: String, octave: Int) {
            notes.append(MusicalNote(name: name, alteration: .natural, octave: octave))
            
            switch name {
            case "DO": 
                notes.append(MusicalNote(name: name, alteration: .sharp, octave: octave))
            case "RE":
                notes.append(MusicalNote(name: name, alteration: .flat, octave: octave))
                notes.append(MusicalNote(name: name, alteration: .sharp, octave: octave))
            case "MI": 
                notes.append(MusicalNote(name: name, alteration: .flat, octave: octave))
            case "FA": 
                notes.append(MusicalNote(name: name, alteration: .sharp, octave: octave))
            case "SOL":
                notes.append(MusicalNote(name: name, alteration: .flat, octave: octave))
                notes.append(MusicalNote(name: name, alteration: .sharp, octave: octave))
            case "LA":
                notes.append(MusicalNote(name: name, alteration: .flat, octave: octave))
                notes.append(MusicalNote(name: name, alteration: .sharp, octave: octave))
            case "SI": 
                notes.append(MusicalNote(name: name, alteration: .flat, octave: octave))
            default: break
            }
        }
        
        // Notas de la octava 3 (empezando desde LA)
        ["LA", "SI"].forEach { name in
            addNote(name, octave: 3)
        }
        
        // Notas de las octavas 4 y 5
        for octave in 4...5 {
            ["DO", "RE", "MI", "FA", "SOL", "LA", "SI"].forEach { name in
                addNote(name, octave: octave)
            }
        }
        
        // Nota DO de la octava 6
        addNote("DO", octave: 6)
        
        return notes
    }
    
    /// Parsea una nota desde un string
    static func parse(_ noteString: String) -> MusicalNote? {
        let pattern = "([A-Z]+)([#♭]?)([0-9])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        if let match = regex?.firstMatch(in: noteString, options: [], range: NSRange(noteString.startIndex..., in: noteString)) {
            let name = String(noteString[Range(match.range(at: 1), in: noteString)!])
            let alterationString = String(noteString[Range(match.range(at: 2), in: noteString)!])
            let octave = Int(String(noteString[Range(match.range(at: 3), in: noteString)!]))!
            
            let alteration: Alteration = alterationString == "#" ? .sharp :
                                       alterationString == "♭" ? .flat : .natural
            
            return MusicalNote(name: name, alteration: alteration, octave: octave)
        }
        return nil
    }
    
    // MARK: - Instance Methods
    func isEnharmonicWith(_ other: MusicalNote) -> Bool {
        let thisNote = "\(name)\(alteration.rawValue)"
        let otherNote = "\(other.name)\(other.alteration.rawValue)"
        
        return MusicalNote.enharmonicEquivalents[thisNote] == otherNote && octave == other.octave
    }
    
    // MARK: - Equatable
    static func == (lhs: MusicalNote, rhs: MusicalNote) -> Bool {
        return lhs.fullName == rhs.fullName || lhs.isEnharmonicWith(rhs)
    }
}