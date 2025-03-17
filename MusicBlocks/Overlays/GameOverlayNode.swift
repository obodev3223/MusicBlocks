//
//  GameOverlayNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit
import UIKit

class GameOverlayNode: SKNode {
    // Cambiado de private a internal para que las subclases puedan acceder
    struct Layout {
        static let cornerRadius: CGFloat = 20
        static let padding: CGFloat = 30
        static let iconSize: CGFloat = 40
        static let spacing: CGFloat = 15
        static let backgroundAlpha: CGFloat = 0.7
    }
    
    enum OverlayPosition {
        case bottom    // For success and failure overlays
        case center    // For game over overlay
        
        func getPosition(in scene: SKScene) -> CGPoint {
            switch self {
            case .bottom:
                // Position at 10% from bottom of screen
                return CGPoint(x: scene.size.width/2, y: scene.size.height * 0.1)
            case .center:
                // Position at center of screen
                return CGPoint(x: scene.size.width/2, y: scene.size.height/2)
            }
        }
    }
    
    private let backgroundNode: SKShapeNode
    // Cambiado de private a protected para que las subclases puedan acceder
    let contentNode: SKNode
    
    init(size: CGSize) {
        backgroundNode = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        contentNode = SKNode()
        
        super.init()
        
        setupBackground()
        addChild(contentNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBackground() {
        backgroundNode.fillColor = .white
        backgroundNode.strokeColor = .clear
        backgroundNode.alpha = 0.95
        addChild(backgroundNode)
    }
    
    // Replace the existing show method in GameOverlayNode
    func show(in scene: SKScene, overlayPosition: OverlayPosition = .center, duration: TimeInterval = 0.3) {
        // Set initial state
        alpha = 0
        setScale(0.5)
        
        // Set position using the enum method
        self.position = overlayPosition.getPosition(in: scene)
        
        // Ensure overlay is above other content
        zPosition = 100
        
        let appearAction = SKAction.group([
            SKAction.fadeIn(withDuration: duration),
            SKAction.scale(to: 1.0, duration: duration)
        ])
        
        run(appearAction)
    }
    
    func hide(duration: TimeInterval = 0.3) {
        let disappearAction = SKAction.group([
            SKAction.fadeOut(withDuration: duration),
            SKAction.scale(to: 0.5, duration: duration)
        ])
        
        run(SKAction.sequence([
            disappearAction,
            SKAction.removeFromParent()
        ]))
    }
}
