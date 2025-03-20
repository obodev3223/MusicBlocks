//
//  LevelStartOverlayNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 17/3/25.
//

import SpriteKit
import UIKit


    // MARK: - Inicio de Nivel
class LevelStartOverlayNode: GameOverlayNode {
    private var countdownLabel: SKLabelNode?
    private var countdownTimer: Timer?
    private var secondsRemaining: Int = 5
    private var startAction: (() -> Void)?
    
    init(size: CGSize, levelId: Int, levelName: String, startAction: @escaping () -> Void) {
        super.init(size: size)
        self.startAction = startAction
        
        // Hacer el fondo más atractivo con un gradiente
        setupBackground()
        
        // Contenedor para el título y nombre del nivel
        let headerContainer = SKNode()
        
        // Título del nivel con estilo mejorado
        let titleNode = SKLabelNode(text: "Nivel \(levelId)")
        titleNode.fontSize = min(40, size.width * 0.12) // Ajuste responsivo
        titleNode.fontName = "Helvetica-Bold"
        titleNode.fontColor = .purple
        titleNode.position = CGPoint(x: 0, y: size.height * 0.2)
        headerContainer.addChild(titleNode)
        
        // Nombre del nivel con estilo mejorado
        let nameNode = SKLabelNode(text: levelName)
        nameNode.fontSize = min(24, size.width * 0.08) // Ajuste responsivo
        nameNode.fontName = "Helvetica"
        nameNode.fontColor = .darkGray
        nameNode.position = CGPoint(x: 0, y: size.height * 0.08)
        headerContainer.addChild(nameNode)
        
        // Línea separadora
        let separatorLine = SKShapeNode(rectOf: CGSize(width: size.width * 0.8, height: 1))
        separatorLine.fillColor = .lightGray
        separatorLine.strokeColor = .clear
        separatorLine.position = CGPoint(x: 0, y: 0)
        headerContainer.addChild(separatorLine)
        
        contentNode.addChild(headerContainer)
        
        // Mensaje "Preparado"
        let readyNode = SKLabelNode(text: "¡Prepárate!")
        readyNode.fontSize = min(28, size.width * 0.09) // Ajuste responsivo
        readyNode.fontName = "Helvetica-Bold"
        readyNode.fontColor = .orange
        readyNode.position = CGPoint(x: 0, y: -size.height * 0.1)
        contentNode.addChild(readyNode)
        
        // Etiqueta para la cuenta atrás con estilo mejorado
        let countdownNode = SKLabelNode(text: "\(secondsRemaining)")
        countdownNode.fontSize = min(64, size.width * 0.2) // Ajuste responsivo
        countdownNode.fontName = "Helvetica-Bold"
        countdownNode.fontColor = .orange
        countdownNode.position = CGPoint(x: 0, y: -size.height * 0.30)
        contentNode.addChild(countdownNode)
        self.countdownLabel = countdownNode
    }
    
    private func setupBackground() {
        // Calcular el tamaño basado en el tamaño del nodo
        let nodeSize = self.calculateAccumulatedFrame().size
        
        // Personalizar el fondo para mejorar la apariencia
        let backgroundNode = SKShapeNode(rectOf: nodeSize, cornerRadius: Layout.cornerRadius)
        let gradientImage = generateGradientImage(
            from: UIColor.systemIndigo,
            to: UIColor.systemBlue.withAlphaComponent(0.7),
            size: nodeSize
        )
        backgroundNode.fillTexture = SKTexture(image: gradientImage)
        backgroundNode.strokeColor = UIColor.white
        backgroundNode.lineWidth = 2
        backgroundNode.alpha = 0.9
        contentNode.addChild(backgroundNode)
    }
    
    // Función auxiliar para generar un fondo con gradiente
    private func generateGradientImage(from startColor: UIColor, to endColor: UIColor, size: CGSize) -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        UIGraphicsBeginImageContext(size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func show(in scene: SKScene, overlayPosition: OverlayPosition = .center, duration: TimeInterval = 0.5) {
        super.show(in: scene, overlayPosition: overlayPosition, duration: duration)
        startCountdown()
    }
    
    private func startCountdown() {
        // Establecer el color inicial según el valor inicial (5)
        updateCountdownColor()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Reproducir un sonido en cada segundo de la cuenta atrás
                    self.playCountdownSound(second: self.secondsRemaining)
            
            self.secondsRemaining -= 1
            self.countdownLabel?.text = "\(self.secondsRemaining)"
            
            // Actualizar el color según el nuevo valor
            self.updateCountdownColor()
            
            // Animar el cambio de número con un efecto más vistoso
            let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
            self.countdownLabel?.run(SKAction.sequence([scaleUp, scaleDown]))
            
            if self.secondsRemaining <= 0 {
                timer.invalidate()
                
                // Reproducir un sonido especial cuando empieza el nivel
                            self.playStartGameSound()
                
                // SOLUCIÓN: Añadir un pequeño retraso entre ocultar el overlay y llamar al startAction
                self.hide(duration: 0.3)
                
                // Esperar a que termine la animación de ocultamiento antes de iniciar el gameplay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.startAction?()
                }
            }
        }
    }
    
    // Añadir los métodos para los sonidos de cuenta atrás
    private func playCountdownSound(second: Int) {
        let pitchModifier: Float = switch second {
            case 5, 4: 0.8
            case 3, 2: 1.0
            case 1: 1.2
            default: 1.0
        }
        
        // Usar AudioController para reproducir sonido
        AudioController.sharedInstance.playUISound(.countdownTick, pitchMultiplier: pitchModifier)
    }

    private func playStartGameSound() {
        // Usar AudioController para reproducir sonido de inicio con pitch más alto
        AudioController.sharedInstance.playUISound(.gameStart)
    }
    
    private func updateCountdownColor() {
        // Asignar colores según el valor de la cuenta atrás
        switch secondsRemaining {
        case 5, 4:
            // 5 y 4 son verdes
            countdownLabel?.fontColor = UIColor.systemGreen
        case 3, 2:
            // 3 y 2 son naranjas
            countdownLabel?.fontColor = UIColor.orange
        case 1, 0:
            // 1 y 0 son rojos
            countdownLabel?.fontColor = UIColor.red
        default:
            // Para cualquier otro número (por seguridad)
            countdownLabel?.fontColor = UIColor.white
        }
    }
    
    override func hide(duration: TimeInterval = 0.3) {
        countdownTimer?.invalidate()
        countdownTimer = nil
        super.hide(duration: duration)
    }
}

    // Añadir preview al final del archivo
    #if DEBUG
    import SwiftUI

    struct LevelStartOverlay_Previews: PreviewProvider {
        static var previews: some View {
            SpriteView(scene: {
                let scene = SKScene(size: CGSize(width: 400, height: 300))
                scene.backgroundColor = .white
                
                let levelStartNode = LevelStartOverlayNode(
                    size: CGSize(width: 350, height: 250),
                    levelId: 1,
                    levelName: "¡Comienza la aventura!",
                    startAction: {}
                )
                levelStartNode.position = CGPoint(x: 200, y: 150)
                scene.addChild(levelStartNode)
                
                return scene
            }())
            .frame(width: 400, height: 300)
            .previewDisplayName("Level Start Overlay")
        }
    }
    #endif

