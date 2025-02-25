//
//  OverlayNodes.swift
//  MusicBlocks
//
//  Created by Jose R. García on 24/2/25.
//

import SpriteKit

class TargetNoteNode: SKNode {
    private let labelNode: SKLabelNode
    private let backgroundNode: SKShapeNode
    
    override init() {
        labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        backgroundNode = SKShapeNode(rectOf: CGSize(width: 200, height: 100),
                                   cornerRadius: 20)
        
        super.init()
        
        setupNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNodes() {
        backgroundNode.fillColor = .white
        backgroundNode.strokeColor = UIColor.gray.withAlphaComponent(0.2)
        addChild(backgroundNode)
        
        labelNode.fontSize = 48
        labelNode.position = CGPoint(x: 0, y: -10)
        addChild(labelNode)
    }
    
    func update(note: String?) {
        labelNode.text = note ?? "-"
    }
    
    func fadeOut() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        run(fadeOut)
    }
    
    func reset() {
        alpha = 1.0
    }
}

class SuccessNode: SKNode {
    private let labelNode: SKLabelNode
    
    override init() {
        labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        super.init()
        
        labelNode.fontSize = 32
        addChild(labelNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(multiplier: Int, message: String) {
        labelNode.text = "\(message) (x\(multiplier))"
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        
        run(SKAction.sequence([fadeIn, wait, fadeOut]))
    }
}

class FailureNode: SKNode {
    private let labelNode: SKLabelNode
    
    override init() {
        labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        super.init()
        
        labelNode.text = "¡Intenta de nuevo!"
        labelNode.fontSize = 32
        addChild(labelNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        
        run(SKAction.sequence([fadeIn, wait, fadeOut]))
    }
}
