//
//  MusicBlock.swift
//  MusicBlocks
//
//  Created by Jose R. García on 4/2/25.
//

import SpriteKit

class MusicBlock: SKSpriteNode {
    let style: BlockStyle
    var note: String
    var currentHits: Int = 0
    
    init(style: BlockStyle, note: String) {
        self.style = style
        self.note = note
        let texture = style.fillTexture ?? SKTexture(imageNamed: style.name)
        super.init(texture: texture, color: .clear, size: texture.size())
        
        self.alpha = style.initialAlpha
        setupPhysics()
        applyStyle()
        
        if let behavior = style.specialBehavior {
            applySpecialBehavior(behavior)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPhysics() {
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.categoryBitMask = 1
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.contactTestBitMask = 2
    }
    
    private func applyStyle() {
        // Aplicar estilo visual básico
        // (Si necesitas más personalización visual, se puede hacer aquí)
    }
    
    private func applySpecialBehavior(_ behavior: BlockStyle.SpecialBehavior) {
        switch behavior {
        case .ghost(let fadeOutAlpha, let fadeInAlpha, let duration):
            let fadeOut = SKAction.fadeAlpha(to: fadeOutAlpha, duration: duration)
            let fadeIn = SKAction.fadeAlpha(to: fadeInAlpha, duration: duration)
            let sequence = SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn]))
            self.run(sequence)
            
        case .changing(let interval):
            // La lógica de cambio de nota se maneja externamente
            break
            
        case .explosive(let holdTime):
            // La lógica de explosión se maneja externamente
            break
        }
    }
    
    func fall(speed: CGFloat, increment: CGFloat) {
        let fallSpeed = speed + increment
        let moveAction = SKAction.moveBy(x: 0, y: -fallSpeed, duration: 1.0)
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    func hit() {
        currentHits += 1
        if currentHits >= style.requiredHits {
            self.removeFromParent()
        }
    }
}
