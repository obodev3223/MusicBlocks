//
//  SuccessOverlayNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 17/3/25.
//

import SpriteKit
import UIKit

// MARK: - Success Overlay
class SuccessOverlayNode: GameOverlayNode {
    init(size: CGSize, multiplier: Int, message: String) {
        // Hacer el overlay más ancho si el mensaje es largo
        let adjustedSize = CGSize(
            width: max(size.width, min(CGFloat(message.count) * 10.0 + 150.0, 500.0)), // Convertir a CGFloat
            height: size.height
        )
        
        super.init(size: adjustedSize)
        
        // Debug
        GameLogger.shared.overlaysUpdates("🎮 Creando SuccessOverlayNode: multiplier=\(multiplier), mensaje='\(message)'")
        
        // Calculamos posiciones basadas en el ancho total
        let totalWidth = adjustedSize.width - (Layout.padding * 2)
        let checkmarkX = -totalWidth/2 + 30.0 // Convertir a CGFloat
        
        // Checkmark a la izquierda
        let checkmarkNode = SKLabelNode(text: "✓")
        checkmarkNode.fontSize = 30
        checkmarkNode.fontName = "Helvetica-Bold"
        checkmarkNode.fontColor = getColor(for: multiplier)
        checkmarkNode.position = CGPoint(x: checkmarkX, y: 0)
        checkmarkNode.horizontalAlignmentMode = .left
        contentNode.addChild(checkmarkNode)
        
        // Mensaje en el centro
        let messageNode = SKLabelNode(text: message)
        messageNode.fontSize = 16
        messageNode.fontName = "Helvetica-Bold"
        messageNode.fontColor = getColor(for: multiplier)
        messageNode.position = CGPoint(x: 0, y: 0)
        messageNode.horizontalAlignmentMode = .center
        contentNode.addChild(messageNode)
        
        // Multiplicador a la derecha
        if multiplier > 1 {
            let multiplierNode = SKLabelNode(text: "x\(multiplier)")
            multiplierNode.fontSize = 18
            multiplierNode.fontName = "Helvetica-Bold"
            multiplierNode.fontColor = .orange
            multiplierNode.position = CGPoint(x: totalWidth/2 - 20.0, y: 0) 
            multiplierNode.horizontalAlignmentMode = .right
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

#if DEBUG
   import SwiftUI

   struct SuccessOverlay_Previews: PreviewProvider {
       static var previews: some View {
           SpriteView(scene: {
               let scene = SKScene(size: CGSize(width: 400, height: 200))
               scene.backgroundColor = .white
               
               let successNode = SuccessOverlayNode(
                   size: CGSize(width: 300, height: 80),
                   multiplier: 2,
                   message: "¡Perfecto!"
               )
               successNode.position = CGPoint(x: 200, y: 100)
               scene.addChild(successNode)
               
               return scene
           }())
           .frame(width: 400, height: 200)
           .previewDisplayName("Success Overlay")
       }
   }
   #endif
