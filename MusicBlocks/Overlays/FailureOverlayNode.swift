//
//  FailureOverlayNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 17/3/25.
//

import SpriteKit
import UIKit

// MARK: - Failure Overlay
class FailureOverlayNode: GameOverlayNode {
    override init(size: CGSize) {
        super.init(size: size)
        
        let xmarkNode = SKLabelNode(text: "✗")
        xmarkNode.fontSize = 30 // Tamaño reducido
        xmarkNode.fontName = "Helvetica-Bold"
        xmarkNode.fontColor = .red
        xmarkNode.position = CGPoint(x: -90, y: -5) // Ajustado horizontalmente
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

#if DEBUG
   import SwiftUI

   struct FailureOverlay_Previews: PreviewProvider {
       static var previews: some View {
           SpriteView(scene: {
               let scene = SKScene(size: CGSize(width: 400, height: 200))
               scene.backgroundColor = .white
               
               let failureNode = FailureOverlayNode(
                   size: CGSize(width: 300, height: 80)
               )
               failureNode.position = CGPoint(x: 200, y: 100)
               scene.addChild(failureNode)
               
               return scene
           }())
           .frame(width: 400, height: 200)
           .previewDisplayName("Failure Overlay")
       }
   }
   #endif
