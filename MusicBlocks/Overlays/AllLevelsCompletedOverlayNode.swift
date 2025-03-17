//
//  AllLevelsCompletedOverlayNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 17/3/25.
//

import SpriteKit
import UIKit

// Extension para añadir color dorado
extension SKColor {
    static let gold = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
}

// MARK: - All Levels Completed Overlay
class AllLevelsCompletedOverlayNode: GameOverlayNode {
    // Acciones para los botones
    private let restartAction: () -> Void
    private let menuAction: () -> Void
    private let overlaySize: CGSize  // Nueva propiedad para almacenar el tamaño
    
    init(size: CGSize, score: Int, restartAction: @escaping () -> Void, menuAction: @escaping () -> Void) {
        self.restartAction = restartAction
        self.menuAction = menuAction
        self.overlaySize = size  // Guardar el tamaño
        super.init(size: size)
        
        // Crear los elementos visuales del overlay
        setupContent(score: score)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupContent(score: Int) {
        // Crear el nodo contenedor
        let container = SKNode()
        contentNode.addChild(container)
        
        // Panel de fondo con borde dorado para dar énfasis especial
        let background = SKShapeNode(rectOf: self.overlaySize, cornerRadius: 20)
        background.fillColor = SKColor.white
        background.strokeColor = SKColor.gold // Color dorado para enfatizar el logro
        background.lineWidth = 3
        background.alpha = 0.95
        container.addChild(background)
        
        // Título grande y festivo
        let titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "¡FELICIDADES!"
        titleLabel.fontSize = 28
        titleLabel.fontColor = SKColor.purple
        titleLabel.position = CGPoint(x: 0, y: self.overlaySize.height/2 - 50)
        container.addChild(titleLabel)
        
        // Descripción del logro
        let descriptionLabel = SKLabelNode(fontNamed: "Helvetica")
        descriptionLabel.text = "¡Has completado todos los niveles!"
        descriptionLabel.fontSize = 20
        descriptionLabel.fontColor = SKColor.darkGray
        descriptionLabel.position = CGPoint(x: 0, y: self.overlaySize.height/2 - 90)
        container.addChild(descriptionLabel)
        
        // Mensaje especial de celebración
        let messageLabel = SKLabelNode(fontNamed: "Helvetica")
        messageLabel.text = "Eres un músico increíble"
        messageLabel.fontSize = 18
        messageLabel.fontColor = SKColor.darkGray
        messageLabel.position = CGPoint(x: 0, y: self.overlaySize.height/2 - 120)
        container.addChild(messageLabel)
        
        // Mostrar la puntuación final
        let scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.text = "Puntuación final: \(score)"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = SKColor.red
        scoreLabel.position = CGPoint(x: 0, y: 0)
        container.addChild(scoreLabel)
        
        // Botón para volver a jugar
        let restartButton = createButton(
            text: "Jugar de nuevo",
            position: CGPoint(x: -80, y: -self.overlaySize.height/2 + 60),
            action: restartAction
        )
        container.addChild(restartButton)
        
        // Botón para ir al menú principal
        let menuButton = createButton(
            text: "Menú principal",
            position: CGPoint(x: 80, y: -self.overlaySize.height/2 + 60),
            action: menuAction
        )
        container.addChild(menuButton)
        
        // Añadir efectos decorativos festivos
        addCelebrationEffects(to: container)
    }
    
    private func createButton(text: String, position: CGPoint, action: @escaping () -> Void) -> SKNode {
        let button = SKNode()
        button.position = position
        button.name = text.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Fondo del botón
        let background = SKShapeNode(rectOf: CGSize(width: 140, height: 40), cornerRadius: 10)
        background.fillColor = SKColor.red
        background.strokeColor = SKColor.clear
        background.alpha = 0.8
        button.addChild(background)
        
        // Texto del botón
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = text
        label.fontSize = 16
        label.fontColor = SKColor.white
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        // Guardar la acción para ser ejecutada cuando se toque el botón
        button.userData = NSMutableDictionary()
        button.userData?.setValue(action, forKey: "action")
        
        return button
    }
    
    // Añadir efectos visuales festivos
    private func addCelebrationEffects(to node: SKNode) {
        // Crear el emisor de confeti programáticamente
        let confetti = SKEmitterNode()
        
        // Configuración del emisor de confeti
        confetti.particleTexture = createConfettiTexture()
        
        // Propiedades de las partículas
        confetti.particleBirthRate = 20 // Número de partículas por segundo
        confetti.particleLifetime = 5 // Duración de vida de cada partícula
        confetti.particleLifetimeRange = 2 // Variación en la duración de vida
        
        // Velocidad y dirección
        confetti.particleSpeed = 300
        confetti.particleSpeedRange = 150
        confetti.emissionAngle = .pi / 2 // Ángulo de emisión (hacia arriba)
        confetti.emissionAngleRange = .pi // Rango de dispersión
        
        // Tamaño de las partículas
        confetti.particleScale = 0.5
        confetti.particleScaleRange = 0.3
        
        // Colores del confeti
        confetti.particleColorBlendFactor = 1.0
        
        // Usar un array de colores para las partículas
        confetti.particleColor = SKColor.red
        confetti.particleColorBlendFactor = 1.0
        
        // Configurar un array de colores
        confetti.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor.red,
                SKColor.blue,
                SKColor.green,
                SKColor.yellow,
                SKColor.purple
            ],
            times: [0.0, 0.2, 0.4, 0.6, 0.8]
        )
        
        // Posición y configuración
        confetti.position = CGPoint(x: 0, y: self.overlaySize.height/2)
        confetti.zPosition = -1
        confetti.particleAlphaSpeed = -0.5 // Desvanecimiento
        
        // Gravedad y rotación
        confetti.particleRotation = .pi
        confetti.particleRotationSpeed = 10
        
        // Usar SKAction para simular gravedad y movimiento
        let fallAction = SKAction.moveBy(x: 0, y: -200, duration: 3)
        confetti.run(fallAction)
        
        // Añadir al nodo
        node.addChild(confetti)
        
        // Acción para limitar la duración del confeti
        let waitAction = SKAction.wait(forDuration: 3)
        let removeAction = SKAction.removeFromParent()
        confetti.run(SKAction.sequence([waitAction, removeAction]))
    }
    
    // Ejemplo de creación de textura de confeti
    func createConfettiTexture() -> SKTexture {
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // Generar un color aleatorio
        let randomColor = UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
        
        // Dibujar un cuadrado con color aleatorio
        context?.setFillColor(randomColor.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image!)
    }
    
    // Manejar toques en los botones
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if let actionDict = node.userData, let action = actionDict.value(forKey: "action") as? () -> Void {
                action()
                return
            }
            
            if let parent = node.parent, let actionDict = parent.userData,
               let action = actionDict.value(forKey: "action") as? () -> Void {
                action()
                return
            }
        }
    }
}

#if DEBUG
    import SwiftUI

    struct AllLevelsCompletedOverlay_Previews: PreviewProvider {
        static var previews: some View {
            SpriteView(scene: {
                let scene = SKScene(size: CGSize(width: 400, height: 500))
                scene.backgroundColor = .white
                
                let overlayNode = AllLevelsCompletedOverlayNode(
                    size: CGSize(width: 350, height: 400),
                    score: 3500,
                    restartAction: {},
                    menuAction: {}
                )
                overlayNode.position = CGPoint(x: 200, y: 250)
                scene.addChild(overlayNode)
                
                return scene
            }())
            .frame(width: 400, height: 500)
            .previewDisplayName("All Levels Completed Overlay")
        }
    }
    #endif
