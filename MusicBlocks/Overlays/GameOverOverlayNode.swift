//
//  GameOverOverlayNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 17/3/25.
//  Actualizado para usar UISoundController para sonidos de UI.
//

import SpriteKit
import UIKit

// MARK: - Game Over Overlay
class GameOverOverlayNode: GameOverlayNode {
    private var restartAction: (() -> Void)?
    private var menuAction: (() -> Void)?
    
    // Referencia al controlador de sonidos de UI
    private let uiSoundController = UISoundController.shared
    
    init(size: CGSize, score: Int, message: String, isVictory: Bool = false,
         restartAction: @escaping () -> Void,
         menuAction: @escaping () -> Void) {
        super.init(size: size)
        self.restartAction = restartAction
        self.menuAction = menuAction
        
        let titleColor: SKColor = isVictory ? .systemGreen : .purple
        let messageColor: SKColor = isVictory ? .systemGreen : .red
        
        // Título Game Over o Victoria
        let gameoverNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        gameoverNode.text = isVictory ? "¡Victoria!" : "¡Fin del juego!"
        gameoverNode.fontSize = 32
        gameoverNode.fontColor = titleColor
        gameoverNode.position = CGPoint(x: 0, y: size.height/2 - 50) // Mover más arriba
        contentNode.addChild(gameoverNode)
        
        // Mensaje específico
        let messageNode = SKLabelNode(fontNamed: "Helvetica")
        messageNode.text = message
        messageNode.fontSize = 16
        messageNode.fontColor = messageColor
        messageNode.position = CGPoint(x: 0, y: size.height/2 - 90) // Posicionar debajo del título
        contentNode.addChild(messageNode)
        
        // Puntuación
        let scoreNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreNode.text = "Puntuación: \(score)"
        scoreNode.fontSize = 20
        scoreNode.fontColor = titleColor
        scoreNode.position = CGPoint(x: 0, y: -20) // Mover más abajo
        contentNode.addChild(scoreNode)
        
        setupButtons(isVictory: isVictory)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    private func setupButtons(isVictory: Bool) {
            let buttonWidth: CGFloat = 150
            let buttonHeight: CGFloat = 50
            let buttonSize = CGSize(width: buttonWidth, height: buttonHeight)
            let spacing: CGFloat = 20
            
            // Botón de menú principal (izquierda)
            let menuButtonNode = SKShapeNode(rectOf: buttonSize, cornerRadius: 10)
            menuButtonNode.fillColor = .darkGray
            menuButtonNode.strokeColor = .clear
            menuButtonNode.position = CGPoint(x: -(buttonWidth/2 + spacing/2), y: -70.0)
            menuButtonNode.name = "menuButton"
            
            let menuLabel = SKLabelNode(text: "Menú Principal")
            menuLabel.fontSize = 16
            menuLabel.fontName = "Helvetica-Bold"
            menuLabel.fontColor = .white
            menuLabel.verticalAlignmentMode = .center
            menuButtonNode.addChild(menuLabel)
            contentNode.addChild(menuButtonNode)
            
            // Botón de reinicio/siguiente nivel (derecha)
            let restartButtonNode = SKShapeNode(rectOf: buttonSize, cornerRadius: 10)
            restartButtonNode.fillColor = isVictory ? .systemGreen : .purple
            restartButtonNode.strokeColor = .clear
            restartButtonNode.position = CGPoint(x: (buttonWidth/2 + spacing/2), y: -70.0)
            restartButtonNode.name = "restartButton"
            
            let buttonText = isVictory ? "Siguiente nivel" : "Intentar de nuevo"
            let restartLabel = SKLabelNode(text: buttonText)
            restartLabel.fontSize = 16
            restartLabel.fontName = "Helvetica-Bold"
            restartLabel.fontColor = .white
            restartLabel.verticalAlignmentMode = .center
            restartButtonNode.addChild(restartLabel)
            contentNode.addChild(restartButtonNode)
        }
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        print("🖱️ Touch detected in GameOverOverlayNode at \(location)")
        
        // Check if touch is on the restart button
        if let restartButton = childNode(withName: "//restartButton") as? SKShapeNode {
            if restartButton.contains(convert(location, to: restartButton.parent!)) {
                print("🖱️ Restart button pressed")
                animateButtonPress(named: "restartButton") {
                    print("🔄 Executing restart action")
                    self.restartAction?()
                }
                return
            }
        }
        
        // Check if touch is on the menu button
        if let menuButton = childNode(withName: "//menuButton") as? SKShapeNode {
            if menuButton.contains(convert(location, to: menuButton.parent!)) {
                print("🖱️ Menu button pressed")
                animateButtonPress(named: "menuButton") {
                    print("🏠 Executing menu action")
                    self.menuAction?()
                }
                return
            }
        }
        
        print("🖱️ Touch was not on any button")
    }
        
    // Añadir animación cuando se presiona un botón
    private func animateButtonPress(named buttonName: String, completion: @escaping () -> Void) {
        guard let button = childNode(withName: "//\(buttonName)") as? SKShapeNode else {
            print("⚠️ Couldn't find button named: \(buttonName)")
            completion() // Still execute the action if button animation fails
            return
        }
        
        // Determinar qué tipo de botón es
        let soundType: UISoundController.UISoundType
        if buttonName == "restartButton" {
            soundType = .buttonTap
        } else if buttonName == "menuButton" {
            soundType = .menuNavigation
        } else {
            soundType = .buttonTap // Por defecto
        }
           
        // Reproducir el sonido apropiado
        uiSoundController.playUISound(soundType)
        
        print("🔄 Animating button: \(buttonName)")
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        
        button.run(sequence) {
            print("✅ Button animation completed: \(buttonName)")
            completion()
        }
    }
}

#if DEBUG
   import SwiftUI

   struct GameOverOverlay_Previews: PreviewProvider {
       static var previews: some View {
           VStack(spacing: 20) {
               SpriteView(scene: {
                   let scene = SKScene(size: CGSize(width: 400, height: 300))
                   scene.backgroundColor = .white
                   
                   // Victoria
                   let victoryNode = GameOverOverlayNode(
                       size: CGSize(width: 300, height: 200),
                       score: 1500,
                       message: "¡Nivel completado!",
                       isVictory: true,
                       restartAction: {},
                       menuAction: {}
                   )
                   victoryNode.position = CGPoint(x: 200, y: 150)
                   scene.addChild(victoryNode)
                   
                   return scene
               }())
               .frame(width: 400, height: 300)
               .previewDisplayName("Game Over (Victory)")
               
               SpriteView(scene: {
                   let scene = SKScene(size: CGSize(width: 400, height: 300))
                   scene.backgroundColor = .white
                   
                   // Derrota
                   let defeatNode = GameOverOverlayNode(
                       size: CGSize(width: 300, height: 200),
                       score: 500,
                       message: "¡Sin vidas!",
                       isVictory: false,
                       restartAction: {},
                       menuAction: {}
                   )
                   defeatNode.position = CGPoint(x: 200, y: 150)
                   scene.addChild(defeatNode)
                   
                   return scene
               }())
               .frame(width: 400, height: 300)
               .previewDisplayName("Game Over (Defeat)")
           }
       }
   }
#endif
