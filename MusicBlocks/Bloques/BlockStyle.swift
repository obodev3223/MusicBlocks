//
//  BlockStyle.swift
//  MusicBlocks
//
//  Created by Jose R. García on 3/3/25.
//

import SpriteKit

struct BlockStyle {
    // Identificador y propiedades básicas
    let name: String
    
    // Relleno y borde
    let backgroundColor: SKColor
    let borderColor: SKColor
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    
    // Sombra (opcional)
    let shadowColor: SKColor?
    let shadowOffset: CGSize?
    let shadowBlur: CGFloat?
    
    // Textura
    let fillTexture: SKTexture?
    let textureOpacity: CGFloat
    let textureScale: CGFloat
    
    // Comportamiento especial (opcional)
    let specialBehavior: SpecialBehavior?
    
    enum SpecialBehavior {
        case ghost(fadeOutAlpha: CGFloat, fadeInAlpha: CGFloat, duration: TimeInterval)
        case changing(changeInterval: TimeInterval)
        case explosive(holdTime: TimeInterval)
    }
}

extension BlockStyle {
    static let defaultBlock = BlockStyle(
        name: "defaultBlock",
        backgroundColor: .white,
        borderColor: .black,
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: .gray,
        shadowOffset: CGSize(width: 3, height: -3),
        shadowBlur: 4.0,
        fillTexture: nil,
        textureOpacity: 1.0,
        textureScale: 1.0,
        specialBehavior: nil
    )
    
    static let iceBlock = BlockStyle(
        name: "iceBlock",
        backgroundColor: SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.5),
        borderColor: SKColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0),
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: SKColor.blue,
        shadowOffset: CGSize(width: 2, height: -2),
        shadowBlur: 4.0,
        fillTexture: SKTexture(imageNamed: "iceTexture4"),
        textureOpacity: 0.8,
        textureScale: 1.0,
        specialBehavior: nil
    )
    
    static let hardiceBlock = BlockStyle(
        name: "hardiceBlock",
        backgroundColor: SKColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0),
        borderColor: SKColor.blue,
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: SKColor.darkGray,
        shadowOffset: CGSize(width: 3, height: -3),
        shadowBlur: 5.0,
        fillTexture: SKTexture(imageNamed: "iceTexture3"),
        textureOpacity: 0.2,
        textureScale: 1.0,
        specialBehavior: nil
    )
    
    static let ghostBlock = BlockStyle(
        name: "ghostBlock",
        backgroundColor: SKColor(white: 0.9, alpha: 0.5),
        borderColor: SKColor(white: 0.8, alpha: 0.7),
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: nil,
        shadowOffset: nil,
        shadowBlur: nil,
        fillTexture: SKTexture(imageNamed: "ghostTexture"),
        textureOpacity: 1.0,
        textureScale: 1.0,
        specialBehavior: .ghost(fadeOutAlpha: 0.2, fadeInAlpha: 0.7, duration: 0.5)
    )
    
    static let changingBlock = BlockStyle(
        name: "changingBlock",
        backgroundColor: SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0),
        borderColor: SKColor.magenta,
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: SKColor.purple,
        shadowOffset: CGSize(width: 2, height: -2),
        shadowBlur: 4.0,
        fillTexture: SKTexture(imageNamed: "wavesTexture"),
        textureOpacity: 1.0,
        textureScale: 1.0,
        specialBehavior: .changing(changeInterval: 1.0)
    )
    
    static let explosiveBlock = BlockStyle(
        name: "explosiveBlock",
        backgroundColor: SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0),
        borderColor: SKColor.red,
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: SKColor.red,
        shadowOffset: CGSize(width: 4, height: -4),
        shadowBlur: 6.0,
        fillTexture: SKTexture(imageNamed: "explosionTexture"),
        textureOpacity: 1.0,
        textureScale: 1.0,
        specialBehavior: .explosive(holdTime: 4.0)
    )
}
