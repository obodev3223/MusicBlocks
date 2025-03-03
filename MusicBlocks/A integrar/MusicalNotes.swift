//
//  MusicalNotes.swift
//  MusicBlocksPruebas
//
//  Created by Jose R. García on 6/2/25.
//

import CoreGraphics


/// Array con todas las notas disponibles desde La3 hasta Do6, con su nombre y offset para posicionarlas en el pentagrama.
enum MusicalNote: String, CaseIterable {
    case la3 = "La3"
    case laSostenido3 = "La#3"
    case siBemol3 = "Sib3"
    case si3 = "Si3"
    case siSostenido3 = "Si#3"
    case doBemol4 = "Dob4"
    case do4 = "Do4"
    case doSostenido4 = "Do#4"
    case reBemol4 = "Reb4"
    case re4 = "Re4"
    case reSostenido4 = "Re#4"
    case miBemol4 = "Mib4"
    case mi4 = "Mi4"
    case miSostenido4 = "Mi#4"
    case faBemol4 = "Fab4"
    case fa4 = "Fa4"
    case faSostenido4 = "Fa#4"
    case solBemol4 = "Solb4"
    case sol4 = "Sol4"
    case solSostenido4 = "Sol#4"
    case laBemol4 = "Lab4"
    case la4 = "La4"
    case laSostenido4 = "La#4"
    case siBemol4 = "Sib4"
    case si4 = "Si4"
    case siSostenido4 = "Si#4"
    case doBemol5 = "Dob5"
    case do5 = "Do5"
    case doSostenido5 = "Do#5"
    case reBemol5 = "Reb5"
    case re5 = "Re5"
    case reSostenido5 = "Re#5"
    case miBemol5 = "Mib5"
    case mi5 = "Mi5"
    case miSostenido5 = "Mi#5"
    case faBemol5 = "Fab5"
    case fa5 = "Fa5"
    case faSostenido5 = "Fa#5"
    case solBemol5 = "Solb5"
    case sol5 = "Sol5"
    case solSostenido5 = "Sol#5"
    case laBemol5 = "Lab5"
    case la5 = "La5"
    case laSostenido5 = "La#5"
    case siBemol5 = "Sib5"
    case si5 = "Si5"
    case siSostenido5 = "Si#5"
    case doBemol6 = "Dob6"
    case do6 = "Do6"
    
    /// Retorna el offset (posición vertical) para posicionar la nota en el pentagrama.
    var offset: CGPoint {
        switch self {
        case .la3, .laSostenido3:
            return CGPoint(x: 0, y: -48)
        case .si3, .siBemol3, .siSostenido3:
            return CGPoint(x: 0, y: -42)
        case .do4, .doSostenido4, .doBemol4:
            return CGPoint(x: 0, y: -36)
        case .re4, .reBemol4, .reSostenido4:
            return CGPoint(x: 0, y: -30)
        case .mi4, .miBemol4, .miSostenido4:
            return CGPoint(x: 0, y: -24)
        case .fa4, .faSostenido4, .faBemol4:
            return CGPoint(x: 0, y: -18)

        case .sol4, .solBemol4, .solSostenido4:
            return CGPoint(x: 0, y: -12)

        case .la4, .laBemol4, .laSostenido4:
            return CGPoint(x: 0, y: -6)

        case .si4, .siBemol4, .siSostenido4:
            return CGPoint(x: 0, y: 0)
        case .do5, .doSostenido5, .doBemol5:
            return CGPoint(x: 0, y: 6)

        case .re5, .reBemol5, .reSostenido5:
            return CGPoint(x: 0, y: 12)
        
        case .mi5, .miBemol5, .miSostenido5:
            return CGPoint(x: 0, y: 18)
        case .fa5, .faSostenido5, .faBemol5:
            return CGPoint(x: 0, y: 24)
     
        case .sol5, .solBemol5, .solSostenido5:
            return CGPoint(x: 0, y: 30)
        
        case .la5, .laBemol5, .laSostenido5:
            return CGPoint(x: 0, y: 36)

        case .si5, .siBemol5, .siSostenido5:
            return CGPoint(x: 0, y: 42)
        case .do6, .doBemol6:
            return CGPoint(x: 0, y: 48)
        }
    }
}
