//
//  TuningPanelNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 24/2/25.
//

import SpriteKit

class TuningPanelNode: SKNode {
    private let indicatorNode: SKShapeNode
    private let noteLabel: SKLabelNode
    private let frequencyLabel: SKLabelNode
    
    override init() {
        indicatorNode = SKShapeNode(rectOf: CGSize(width: 20, height: 200))
        noteLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        frequencyLabel = SKLabelNode(fontNamed: "Helvetica")
        
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
        
        noteLabel.fontSize = 24
        noteLabel.position = CGPoint(x: 0, y: -120)
        addChild(noteLabel)
        
        frequencyLabel.fontSize = 18
        frequencyLabel.position = CGPoint(x: 0, y: -150)
        addChild(frequencyLabel)
    }
    
    func update(with data: TunerEngine.TunerData) {
        noteLabel.text = data.note
        frequencyLabel.text = String(format: "%.1f Hz", data.frequency)
        
        let color: UIColor = {
            guard data.isActive else { return .gray }
            let absDeviation = abs(data.deviation)
            if absDeviation < 5 { return .green }
            if absDeviation < 15 { return .orange }
            return .red
        }()
        
        indicatorNode.strokeColor = color
    }
}
