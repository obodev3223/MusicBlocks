//
//  MusicalNoteType.swift
//  MusicBlocksPruebas
//
//  Created by Jose R. García on 5/2/25.
//

import SwiftUI

// MARK: - Musical Note Management
enum MusicalNoteType: String {
    case do4 = "do4"
    case doSharp4 = "do#4"
    case re4 = "re4"
    case reSharp4 = "re#4"
    case mi4 = "mi4"
    case fa4 = "fa4"
    case faSharp4 = "fa#4"
    case sol4 = "sol4"
    case solSharp4 = "sol#4"
    case la4 = "la4"
    case laSharp4 = "la#4"
    case si4 = "si4"
    // Octava 5
    case do5 = "do5"
    case doSharp5 = "do#5"
    case re5 = "re5"
    case reSharp5 = "re#5"
    case mi5 = "mi5"
    case fa5 = "fa5"
    case faSharp5 = "fa#5"
    case sol5 = "sol5"
    case solSharp5 = "sol#5"
    case la5 = "la5"
    case laSharp5 = "la#5"
    case si5 = "si5"
    
    // Propiedades de visualización
    var displayName: String {
        switch self {
        case .doSharp4, .doSharp5: return "Do#"
        case .reSharp4, .reSharp5: return "Re#"
        case .faSharp4, .faSharp5: return "Fa#"
        case .solSharp4, .solSharp5: return "Sol#"
        case .laSharp4, .laSharp5: return "La#"
        default:
            return String(rawValue.prefix(while: { !$0.isNumber })).capitalized
        }
    }
    
    var octave: Int {
        return Int(String(rawValue.last!))!
    }
}
