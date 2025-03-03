//
//  BlockStyle.swift
//  MusicBlocksPruebas
//
//  Created by Jose R. García on 6/2/25.
//

import SpriteKit
import SwiftUI

/// Estructura para definir el estilo visual de un bloque.
struct BlockStyle {
    // Identificador del estilo.
    let name: String
    
    // Relleno y borde.
    let backgroundColor: SKColor
    let borderColor: SKColor
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    
    // Sombra (opcional).
    let shadowColor: SKColor?
    let shadowOffset: CGSize?
    let shadowBlur: CGFloat?
    
    // Brillo o glow (opcional).
    let glowWidth: CGFloat?
    
    // Textura.
    let fillTexture: SKTexture?
    let textureOpacity: CGFloat   // Valor entre 0.0 y 1.0.
    let textureScale: CGFloat     // Factor de escala para la textura.
}

extension BlockStyle {
    /// Estilo predeterminado.
    static let defaultBlock = BlockStyle(
        name: "defaultBlock",
        backgroundColor: .white,
        borderColor: .black,
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: .gray,
        shadowOffset: CGSize(width: 3, height: -3),
        shadowBlur: 4.0,
        glowWidth: 0.0,
        fillTexture: nil,
        textureOpacity: 1.0,
        textureScale: 1.0
    )
    
    /// Estilo tipo "iceBlock": apariencia fría, con tonos azulados.
    static let iceBlock = BlockStyle(
        name: "iceBlock",
        backgroundColor: SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.5),
        borderColor: SKColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0),
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: SKColor.blue,
        shadowOffset: CGSize(width: 2, height: -2),
        shadowBlur: 4.0,
        glowWidth: 2.0,
        fillTexture: SKTexture(imageNamed: "iceTexture4"),
        textureOpacity: 0.8,
        textureScale: 1.0
    )
    
    /// Estilo tipo "hardiceBlock": variante más robusta del iceBlock.
    static let hardiceBlock = BlockStyle(
        name: "hardiceBlock",
        backgroundColor: SKColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0),
        borderColor: SKColor.blue,
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: SKColor.darkGray,
        shadowOffset: CGSize(width: 3, height: -3),
        shadowBlur: 5.0,
        glowWidth: 1.0,
        fillTexture: SKTexture(imageNamed: "iceTexture3"),
        textureOpacity: 0.2,
        textureScale: 1.0
    )
    
    /// Estilo tipo "ghostBlock": aspecto translúcido y etéreo.
    static let ghostBlock = BlockStyle(
        name: "ghostBlock",
        backgroundColor: SKColor(white: 0.9, alpha: 0.5),
        borderColor: SKColor(white: 0.8, alpha: 0.7),
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: nil,
        shadowOffset: nil,
        shadowBlur: nil,
        glowWidth: 2.0,
        fillTexture: SKTexture(imageNamed: "ghostTexture"),
        textureOpacity: 1.0,
        textureScale: 1.0
    )
    
    /// Estilo tipo "changingBlock": con un color distintivo (por ejemplo, morado) que podría actualizarse dinámicamente.
    static let changingBlock = BlockStyle(
        name: "changingBlock",
        backgroundColor: SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0),
        borderColor: SKColor.magenta,
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: SKColor.purple,
        shadowOffset: CGSize(width: 2, height: -2),
        shadowBlur: 4.0,
        glowWidth: 0.0,
        fillTexture: SKTexture(imageNamed: "wavesTexture"),
        textureOpacity: 1.0,
        textureScale: 1.0
    )
    
    /// Estilo tipo "explosiveBlock": apariencia vibrante y llamativa con tonos rojizos/naranjas y alto glow.
    static let explosiveBlock = BlockStyle(
        name: "explosiveBlock",
        backgroundColor: SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0),
        borderColor: SKColor.red,
        borderWidth: 5.0,
        cornerRadius: 20.0,
        shadowColor: SKColor.red,
        shadowOffset: CGSize(width: 4, height: -4),
        shadowBlur: 6.0,
        glowWidth: 4.0,
        fillTexture: SKTexture(imageNamed: "explosionTexture"),
        textureOpacity: 1.0,
        textureScale: 1.0
    )
}

