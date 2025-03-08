//
//  UIContainer.swift 
//  MusicBlocks
//
//  Created by Jose R. García on 8/3/25.
//

import SpriteKit

struct CommonStyle {
    static let containerBackgroundColor: SKColor = .white
    static let containerBackgroundAlpha: CGFloat = 0.85
    static let containerCornerRadius: CGFloat = 12
    static let shadowColor: SKColor = .black
    static let shadowRadius: Float = 4.0
    static let shadowOpacity: Float = 0.2
    static let shadowOffset = CGPoint(x: 0, y: -2)
}

extension SKNode {
    func applyContainerStyle(size: CGSize) {
        // Crear y configurar sombra
        let shadowNode = SKEffectNode()
        shadowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": CommonStyle.shadowRadius])
        shadowNode.shouldRasterize = true
        
        let shadowShape = SKShapeNode(rectOf: size, cornerRadius: CommonStyle.containerCornerRadius)
        shadowShape.fillColor = CommonStyle.shadowColor
        shadowShape.strokeColor = .clear
        shadowShape.alpha = CGFloat(CommonStyle.shadowOpacity)
        shadowShape.position = CommonStyle.shadowOffset
        shadowNode.addChild(shadowShape)
        
        // Crear y configurar contenedor principal
        let container = SKShapeNode(rectOf: size, cornerRadius: CommonStyle.containerCornerRadius)
        container.fillColor = CommonStyle.containerBackgroundColor
        container.strokeColor = .clear
        container.alpha = CommonStyle.containerBackgroundAlpha
        
        // Añadir nodos en orden correcto
        addChild(shadowNode)
        addChild(container)
    }
}
