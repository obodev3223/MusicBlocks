//
//  MusicBlock.swift
//  MusicBlocks
//
//  Created by Jose R. García on 4/2/25.
//

import SwiftUI
import SpriteKit

/// Clase base para todos los bloques musicales en el juego.
class MusicBlock: SKSpriteNode {
    
    var note: String // Nota asignada al bloque
    var requiredHits: Int // Veces que debe acertarse la nota para destruir el bloque
    var currentHits: Int = 0 // Contador de aciertos actuales
    
    // Propiedades para la visualización de la nota
    private var noteLabel: SKLabelNode?
    private var noteContainer: SKShapeNode?
    private var octaveLabel: SKLabelNode?
    

    
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
        }
        
        required init?(coder aDecoder: NSCoder) {
            self.note = ""
            self.requiredHits = 1
            super.init(coder: aDecoder)
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


