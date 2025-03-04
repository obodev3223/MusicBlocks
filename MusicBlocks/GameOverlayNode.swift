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

// MARK: - Inicio de Nivel
class LevelStartOverlayNode: GameOverlayNode {
    private var countdownLabel: SKLabelNode?
    private var countdownTimer: Timer?
    private var secondsRemaining: Int = 5
    private var startAction: (() -> Void)?
    
    init(size: CGSize, levelId: Int, levelName: String, startAction: @escaping () -> Void) {
        super.init(size: size)
        self.startAction = startAction
        
        // Título del nivel
        let titleNode = SKLabelNode(text: "Nivel \(levelId)")
        titleNode.fontSize = 36
        titleNode.fontName = "Helvetica-Bold"
        titleNode.fontColor = .purple
        titleNode.position = CGPoint(x: 0, y: 40)
        contentNode.addChild(titleNode)
        
        // Nombre del nivel
        let nameNode = SKLabelNode(text: levelName)
        nameNode.fontSize = 24
        nameNode.fontName = "Helvetica"
        nameNode.fontColor = .darkGray
        nameNode.position = CGPoint(x: 0, y: 0)
        contentNode.addChild(nameNode)
        
        // Etiqueta para la cuenta atrás
        let countdownNode = SKLabelNode(text: "\(secondsRemaining)")
        countdownNode.fontSize = 48
        countdownNode.fontName = "Helvetica-Bold"
        countdownNode.fontColor = .orange
        countdownNode.position = CGPoint(x: 0, y: -50)
        contentNode.addChild(countdownNode)
        self.countdownLabel = countdownNode
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func show(in scene: SKScene, overlayPosition: OverlayPosition = .center, duration: TimeInterval = 0.3) {
        super.show(in: scene, overlayPosition: overlayPosition, duration: duration)
        startCountdown()
    }
    
    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.secondsRemaining -= 1
            self.countdownLabel?.text = "\(self.secondsRemaining)"
            
            // Animar el cambio de número
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            self.countdownLabel?.run(SKAction.sequence([scaleUp, scaleDown]))
            
            if self.secondsRemaining <= 0 {
                timer.invalidate()
                self.hide()
                self.startAction?()
            }
        }
    }
    
    override func hide(duration: TimeInterval = 0.3) {
        countdownTimer?.invalidate()
        countdownTimer = nil
        super.hide(duration: duration)
    }
}

// MARK: - Success Overlay
class SuccessOverlayNode: GameOverlayNode {
    init(size: CGSize, multiplier: Int, message: String) {
        super.init(size: size)
        
        let checkmarkNode = SKLabelNode(text: "✓")
        checkmarkNode.fontSize = 30 // Tamaño reducido
        checkmarkNode.fontName = "Helvetica-Bold"
        checkmarkNode.fontColor = getColor(for: multiplier)
        checkmarkNode.position = CGPoint(x: -60, y: 0) // Ajustado horizontalmente
        contentNode.addChild(checkmarkNode)
        
        let messageNode = SKLabelNode(text: message)
        messageNode.fontSize = 16 // Tamaño reducido
        messageNode.fontName = "Helvetica-Bold"
        messageNode.fontColor = getColor(for: multiplier)
        messageNode.position = CGPoint(x: 0, y: 0)
        contentNode.addChild(messageNode)
        
        if multiplier > 1 {
            let multiplierNode = SKLabelNode(text: "x\(multiplier)")
            multiplierNode.fontSize = 18 // Tamaño reducido
            multiplierNode.fontName = "Helvetica-Bold"
            multiplierNode.fontColor = .orange
            multiplierNode.position = CGPoint(x: 60, y: 0) // Ajustado horizontalmente
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
        xmarkNode.fontSize = 30 // Tamaño reducido
        xmarkNode.fontName = "Helvetica-Bold"
        xmarkNode.fontColor = .red
        xmarkNode.position = CGPoint(x: -90, y: 0) // Ajustado horizontalmente
        contentNode.addChild(xmarkNode)
        
        let messageNode = SKLabelNode(text: "¡Intenta de nuevo!")
        messageNode.fontSize = 16 // Tamaño reducido
        messageNode.fontName = "Helvetica-Bold"
        messageNode.fontColor = .red
        messageNode.position = CGPoint(x: 0, y: 0)
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
