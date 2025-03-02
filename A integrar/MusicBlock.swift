//
//  MusicBlock.swift
//  MusicBlocksPruebas
//
//  Created by Jose R. García on 4/2/25.
//

import SwiftUI
import SpriteKit

/// Clase base para todos los bloques musicales en el juego.
class MusicBlock: SKSpriteNode {
    
    var note: String {
            didSet {
                updateNoteDisplay()
            }
        } // Nota asignada al bloque
    var requiredHits: Int // Veces que debe acertarse la nota para destruir el bloque
    var currentHits: Int = 0 // Contador de aciertos actuales
    
    // Propiedades para la visualización de la nota
    private var noteLabel: SKLabelNode?
    private var noteContainer: SKShapeNode?
    private var octaveLabel: SKLabelNode?
    
    // Configuración visual
    private struct NoteDisplayConfig {
        static let fontSize: CGFloat = 24.0
        static let octaveFontSize: CGFloat = 16.0
        static let fontName = "AvenirNext-Bold"
        static let containerPadding: CGFloat = 10.0
        static let containerCornerRadius: CGFloat = 8.0
    }
    
    /// Inicializador del bloque musical
       /// - Parameters:
       ///   - texture: Textura del bloque
       ///   - note: Nota musical asignada
       ///   - requiredHits: Veces necesarias para destruir el bloque
       init(texture: SKTexture, note: String, requiredHits: Int) {
           self.note = note
           self.requiredHits = requiredHits
           super.init(texture: texture, color: .clear, size: texture.size())
           
           self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
           self.physicsBody?.affectedByGravity = false
           self.physicsBody?.categoryBitMask = 1
           self.physicsBody?.collisionBitMask = 0
           self.physicsBody?.contactTestBitMask = 2
           
           setupNoteDisplay()
       }
    
    required init?(coder aDecoder: NSCoder) {
        self.note = ""
        self.requiredHits = 1
        super.init(coder: aDecoder)
    }
    
    
    private func setupNoteDisplay() {
        // Crear contenedor para la nota
        let container = SKShapeNode(rectOf: CGSize(width: size.width * 0.8,
                                                  height: size.height * 0.4),
                                  cornerRadius: NoteDisplayConfig.containerCornerRadius)
        container.fillColor = .black
        container.strokeColor = .white
        container.alpha = 0.7
        container.position = CGPoint(x: 0, y: 0)
        addChild(container)
        noteContainer = container
        
        // Crear label para la nota
        let label = SKLabelNode(fontNamed: NoteDisplayConfig.fontName)
        label.fontSize = NoteDisplayConfig.fontSize
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 0)
        container.addChild(label)
        noteLabel = label
        
        // Crear label para la octava
        let octave = SKLabelNode(fontNamed: NoteDisplayConfig.fontName)
        octave.fontSize = NoteDisplayConfig.octaveFontSize
        octave.fontColor = .white
        octave.verticalAlignmentMode = .bottom
        octave.horizontalAlignmentMode = .right
        octave.position = CGPoint(x: container.frame.width/2 - 5,
                                y: container.frame.height/2 - 5)
        container.addChild(octave)
        octaveLabel = octave
        
        updateNoteDisplay()
    }
    
    private func updateNoteDisplay() {
        guard let musicalNote = MusicalNoteType(rawValue: note) else {
            noteLabel?.text = "?"
            octaveLabel?.text = ""
            return
        }
        
        // Actualizar la nota y la octava
        noteLabel?.text = musicalNote.displayName
        octaveLabel?.text = "\(musicalNote.octave)"
        
        // Ajustar el color según el tipo de nota
        if musicalNote.displayName.contains("#") {
            noteContainer?.fillColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.9)
        } else {
            noteContainer?.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        }
        
        // Animar la actualización
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        noteContainer?.run(pulseAction)
    }
    
    // Método para resaltar la nota cuando se detecta
    func highlightNote(accuracy: Double) {
            let color: UIColor
            if accuracy >= 0.95 {
                color = .green
            } else if accuracy >= 0.8 {
                color = .yellow
            } else {
                color = .red
            }
            
            let originalColor = noteContainer?.fillColor ?? .black // Proporcionamos un valor por defecto
            let highlightAction = SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.noteContainer?.fillColor = color
                },
                SKAction.wait(forDuration: 0.2),
                SKAction.run { [weak self] in
                    self?.noteContainer?.fillColor = originalColor
                }
            ])
            
            noteContainer?.run(highlightAction)
        }

    

    
    /// Hace que el bloque caiga a una velocidad determinada con un incremento opcional
    /// - Parameters:
    ///   - speed: Velocidad inicial de caída
    ///   - increment: Incremento progresivo de la velocidad
    func fall(speed: CGFloat, increment: CGFloat) {
        let fallSpeed = speed + increment
        let moveAction = SKAction.moveBy(x: 0, y: -fallSpeed, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    /// Registra un acierto en la nota correspondiente
    func hit() {
        currentHits += 1
        if currentHits >= requiredHits {
            self.removeFromParent() // Elimina el bloque si se alcanzan los aciertos requeridos
        }
    }
}

// MARK: - Bloques Especiales

/// Bloque de hielo: requiere dos aciertos para destruirse.
class IceBlock: MusicBlock {
    init(note: String) {
        let texture = SKTexture(imageNamed: "iceBlock")
        super.init(texture: texture, note: note, requiredHits: 2)
        self.alpha = 0.9
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

/// Bloque de hielo duro: requiere tres aciertos para destruirse.
class HardIceBlock: MusicBlock {
    init(note: String) {
        let texture = SKTexture(imageNamed: "hardIceBlock")
        super.init(texture: texture, note: note, requiredHits: 3)
        self.alpha = 0.9
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

/// Bloque fantasma: aparece y desaparece mientras cae.
class GhostBlock: MusicBlock {
    init(note: String) {
        let texture = SKTexture(imageNamed: "ghostBlock")
        super.init(texture: texture, note: note, requiredHits: 1)
        self.alpha = 0.7
    }
    
    override func fall(speed: CGFloat, increment: CGFloat) {
        let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.5)
        let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: 0.5)
        let fadeSequence = SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn]))
        self.run(fadeSequence)
        
        super.fall(speed: speed, increment: increment)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

/// Bloque cambiante: la nota asignada cambia mientras cae.
class ChangingBlock: MusicBlock {
    
    private var possibleNotes: [String]
    
    init(notes: [String]) {
            let texture = SKTexture(imageNamed: "changingBlock")
            self.possibleNotes = notes // Inicializar antes del super.init
            let randomNote = notes.randomElement() ?? "do4"
            super.init(texture: texture, note: randomNote, requiredHits: 1)
        }
    
    required init?(coder aDecoder: NSCoder) {
        // Inicializar possibleNotes antes de llamar a super.init
        self.possibleNotes = []
        super.init(coder: aDecoder)
    }
    
    override func fall(speed: CGFloat, increment: CGFloat) {
        let changeNote = SKAction.run {
            self.note = self.possibleNotes.randomElement() ?? "do4"
        }
        let wait = SKAction.wait(forDuration: 1.0)
        let changeSequence = SKAction.repeatForever(SKAction.sequence([changeNote, wait]))
        self.run(changeSequence)
        
        super.fall(speed: speed, increment: increment)
    }
    

}

/// Bloque explosivo: se debe mantener la nota durante un tiempo antes de destruirse.
class ExplosiveBlock: MusicBlock {
    var holdTime: TimeInterval = 4.0 // Segundos que hay que mantener la nota
    
    init(note: String) {
        let texture = SKTexture(imageNamed: "explosiveBlock")
        super.init(texture: texture, note: note, requiredHits: 1)
    }
    
    /// Inicia la cuenta regresiva de destrucción del bloque
    func startHoldCountdown() {
        let wait = SKAction.wait(forDuration: holdTime)
        let remove = SKAction.removeFromParent()
        self.run(SKAction.sequence([wait, remove]))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}


