//
//  BlockStyle.swift
//  MusicBlocks
//
//  Created by Jose R. García on 3/3/25.
//

import SpriteKit

struct BlockStyle {
    // Propiedades existentes
    let name: String
    let backgroundColor: SKColor
    let borderColor: SKColor
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let shadowColor: SKColor?
    let shadowOffset: CGSize?
    let shadowBlur: CGFloat?
    let fillTexture: SKTexture?
    let textureOpacity: CGFloat
    let textureScale: CGFloat
    let specialBehavior: SpecialBehavior?
    
    // NUEVAS PROPIEDADES para texturas de daño
    let damageTextures: [SKTexture]?  // Array de texturas adicionales para mostrar daño
    
    // Enumeración de comportamientos especiales existente
    enum SpecialBehavior {
        case ghost(fadeOutAlpha: CGFloat, fadeInAlpha: CGFloat, duration: TimeInterval)
        case changing(changeInterval: TimeInterval)
        case explosive(holdTime: TimeInterval)
    }
}

// Actualizar las definiciones de estilos específicos
extension BlockStyle {
    static let defaultBlock = BlockStyle(
        name: "defaultBlock",
        backgroundColor: .white,
        borderColor: .black,
        borderWidth: 3.0,
        cornerRadius: 20.0,
        shadowColor: .gray,
        shadowOffset: CGSize(width: 3, height: -3),
        shadowBlur: 4.0,
        fillTexture: nil,
        textureOpacity: 1.0,
        textureScale: 1.0,
        specialBehavior: nil,
        damageTextures: nil  // No tiene texturas de daño
    )
    
    static let iceBlock = BlockStyle(
        name: "iceBlock",
        backgroundColor: .clear,
        borderColor: SKColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0),
        borderWidth: 3.0,
        cornerRadius: 20.0,
        shadowColor: .clear,
        shadowOffset: CGSize(width: 2, height: -2),
        shadowBlur: 4.0,
        fillTexture: SKTexture(imageNamed: "iceTexture"),  // Textura inicial
        textureOpacity: 1.0,
        textureScale: 1.0,
        specialBehavior: nil,
        damageTextures: [
            SKTexture(imageNamed: "iceTexture_damaged_1"),  // Textura después del primer golpe
            SKTexture(imageNamed: "iceTexture_damaged_2")   // Textura después del segundo golpe
        ]
    )
    
    static let hardiceBlock = BlockStyle(
        name: "hardiceBlock",
        backgroundColor: .clear,
        borderColor: SKColor.blue,
        borderWidth: 3.0,
        cornerRadius: 20.0,
        shadowColor: SKColor.darkGray,
        shadowOffset: CGSize(width: 3, height: -3),
        shadowBlur: 3.0,
        fillTexture: SKTexture(imageNamed: "hardIceTexture"),  // Textura inicial
        textureOpacity: 1.0,
        textureScale: 1.0,
        specialBehavior: nil,
        damageTextures: [
            SKTexture(imageNamed: "hardIceTexture_damaged_1"),  // Textura después del primer golpe
            SKTexture(imageNamed: "hardIceTexture_damaged_2"),  // Textura después del segundo golpe
        ]
    )
    
    static let ghostBlock = BlockStyle(
        name: "ghostBlock",
        backgroundColor: SKColor(white: 0.9, alpha: 0.5),
        borderColor: SKColor(white: 0.8, alpha: 0.7),
        borderWidth: 3.0,
        cornerRadius: 20.0,
        shadowColor: nil,
        shadowOffset: nil,
        shadowBlur: nil,
        fillTexture: SKTexture(imageNamed: "ghostTexture"),
        textureOpacity: 1.0,
        textureScale: 1.0,
        specialBehavior: .ghost(fadeOutAlpha: 0.2, fadeInAlpha: 0.7, duration: 0.5),
        damageTextures: nil  // No tiene texturas de daño
    )
    
    static let changingBlock = BlockStyle(
        name: "changingBlock",
        backgroundColor: SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0),
        borderColor: SKColor.magenta,
        borderWidth: 3.0,
        cornerRadius: 20.0,
        shadowColor: SKColor.purple,
        shadowOffset: CGSize(width: 2, height: -2),
        shadowBlur: 4.0,
        fillTexture: SKTexture(imageNamed: "wavesTexture"),
        textureOpacity: 1.0,
        textureScale: 1.0,
        specialBehavior: .changing(changeInterval: 1.0),
        damageTextures: nil  // No tiene texturas de daño
    )
    
    static let explosiveBlock = BlockStyle(
        name: "explosiveBlock",
        backgroundColor: SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0),
        borderColor: SKColor.red,
        borderWidth: 3.0,
        cornerRadius: 20.0,
        shadowColor: SKColor.red,
        shadowOffset: CGSize(width: 4, height: -4),
        shadowBlur: 6.0,
        fillTexture: SKTexture(imageNamed: "explosionTexture"),
        textureOpacity: 1.0,
        textureScale: 1.0,
        specialBehavior: .explosive(holdTime: 4.0),
        damageTextures: nil  // No tiene texturas de daño
    )
}
