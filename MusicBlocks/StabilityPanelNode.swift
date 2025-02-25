//
//  StabilityPanelNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 24/2/25.
//

import SpriteKit

class StabilityPanelNode: SKNode {
    private let indicatorNode: SKShapeNode
    private let durationLabel: SKLabelNode
    
    override init() {
        indicatorNode = SKShapeNode(rectOf: CGSize(width: 20, height: 200))
        durationLabel = SKLabelNode(fontNamed: "Helvetica")
        
        super.init()
        
        setupNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNodes() {
        indicatorNode.fillColor = .clear
        indicatorNode.strokeColor = .black
        addChild(indicatorNode)
        
        durationLabel.fontSize = 18
        durationLabel.position = CGPoint(x: 0, y: -120)
        addChild(durationLabel)
    }
    
    func update(duration: TimeInterval) {
        durationLabel.text = String(format: "%.1fs", duration)
        
        let fillHeight = min(duration / 10.0, 1.0) * 200
        let fillNode = SKShapeNode(rectOf: CGSize(width: 20, height: fillHeight))
        fillNode.fillColor = .blue
        fillNode.strokeColor = .clear
        fillNode.position = CGPoint(x: 0, y: -100 + fillHeight/2)
        
        indicatorNode.removeAllChildren()
        indicatorNode.addChild(fillNode)
    }
}
