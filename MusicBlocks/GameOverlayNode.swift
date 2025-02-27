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
    
    func show(in scene: SKScene, duration: TimeInterval = 0.3) {
        alpha = 0
        setScale(0.5)
        
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

// MARK: - Success Overlay
class SuccessOverlayNode: GameOverlayNode {
    init(size: CGSize, multiplier: Int, message: String) {
        super.init(size: size)
        
        let checkmarkNode = SKLabelNode(text: "✓")
        checkmarkNode.fontSize = Layout.iconSize
        checkmarkNode.fontName = "Helvetica-Bold"
        checkmarkNode.fontColor = getColor(for: multiplier)
        checkmarkNode.position = CGPoint(x: 0, y: 10)
        contentNode.addChild(checkmarkNode)
        
        let messageNode = SKLabelNode(text: message)
        messageNode.fontSize = 24
        messageNode.fontName = "Helvetica-Bold"
        messageNode.fontColor = getColor(for: multiplier)
        messageNode.position = CGPoint(x: 0, y: -20)
        contentNode.addChild(messageNode)
        
        if multiplier > 1 {
            let multiplierNode = SKLabelNode(text: "x\(multiplier)")
            multiplierNode.fontSize = 20
            multiplierNode.fontName = "Helvetica-Bold"
            multiplierNode.fontColor = .orange
            multiplierNode.position = CGPoint(x: 0, y: -45)
            contentNode.addChild(multiplierNode)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getColor(for multiplier: Int) -> SKColor {
        switch multiplier {
        case 3: return .purple    // Excelente
        case 2: return .green     // Perfecto
        case 1: return .blue      // Bien
        default: return .gray
        }
    }
}

// MARK: - Failure Overlay
class FailureOverlayNode: GameOverlayNode {
    override init(size: CGSize) {
        super.init(size: size)
        
        let xmarkNode = SKLabelNode(text: "✗")
        xmarkNode.fontSize = Layout.iconSize
        xmarkNode.fontName = "Helvetica-Bold"
        xmarkNode.fontColor = .red
        xmarkNode.position = CGPoint(x: 0, y: 10)
        contentNode.addChild(xmarkNode)
        
        let messageNode = SKLabelNode(text: "¡Intenta de nuevo!")
        messageNode.fontSize = 24
        messageNode.fontName = "Helvetica-Bold"
        messageNode.fontColor = .red
        messageNode.position = CGPoint(x: 0, y: -20)
        contentNode.addChild(messageNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Game Over Overlay
class GameOverOverlayNode: GameOverlayNode {
    private var restartAction: (() -> Void)?
    
    init(size: CGSize, score: Int, restartAction: @escaping () -> Void) {
        super.init(size: size)
        self.restartAction = restartAction
        
        let gameoverNode = SKLabelNode(text: "¡Fin del juego!")
        gameoverNode.fontSize = 36
        gameoverNode.fontName = "Helvetica-Bold"
        gameoverNode.fontColor = .purple
        gameoverNode.position = CGPoint(x: 0, y: 40)
        contentNode.addChild(gameoverNode)
        
        let scoreNode = SKLabelNode(text: "Puntuación final: \(score)")
        scoreNode.fontSize = 24
        scoreNode.fontName = "Helvetica-Bold"
        scoreNode.fontColor = .purple
        scoreNode.position = CGPoint(x: 0, y: 0)
        contentNode.addChild(scoreNode)
        
        setupRestartButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupRestartButton() {
        let buttonSize = CGSize(width: 200, height: 50)
        let buttonNode = SKShapeNode(rectOf: buttonSize, cornerRadius: 10)
        buttonNode.fillColor = .purple
        buttonNode.strokeColor = .clear
        buttonNode.position = CGPoint(x: 0, y: -50)
        buttonNode.name = "restartButton"
        contentNode.addChild(buttonNode)
        
        let buttonLabel = SKLabelNode(text: "Jugar de nuevo")
        buttonLabel.fontSize = 20
        buttonLabel.fontName = "Helvetica-Bold"
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        buttonNode.addChild(buttonLabel)
        
        isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        
        if nodes.contains(where: { $0.name == "restartButton" }) {
            restartAction?()
        }
    }
}

// MARK: - Previews
#if DEBUG
import SwiftUI

struct GameOverlayPreview: PreviewProvider {
    static var previews: some View {
        SpriteView(scene: {
            // Crear la escena directamente
            let scene = SKScene(size: CGSize(width: 400, height: 600))
            scene.backgroundColor = .white
            
            // Agregar el Success Overlay
            let successNode = SuccessOverlayNode(
                size: CGSize(width: 300, height: 200),
                multiplier: 2,
                message: "¡Perfecto!"
            )
            successNode.position = CGPoint(x: 200, y: 450)
            scene.addChild(successNode)
            
            // Agregar el Failure Overlay
            let failureNode = FailureOverlayNode(
                size: CGSize(width: 300, height: 200)
            )
            failureNode.position = CGPoint(x: 200, y: 300)
            scene.addChild(failureNode)
            
            // Agregar el Game Over Overlay
            let gameOverNode = GameOverOverlayNode(
                size: CGSize(width: 300, height: 200),
                score: 1500,
                restartAction: {}
            )
            gameOverNode.position = CGPoint(x: 200, y: 150)
            scene.addChild(gameOverNode)
            
            return scene
        }())
        .frame(width: 400, height: 600)
        .previewLayout(.fixed(width: 400, height: 600))
    }
}
#endif
