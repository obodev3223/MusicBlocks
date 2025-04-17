//
//  IceBlockEffects.swift
//  MusicBlocks
//
//  Creado por Jose R. García el 17/4/25.
//

import SpriteKit

struct IceBlockEffects {
    /// Método para actualizar la apariencia de los bloques de hielo
    static func updateIceBlockAppearance(
        block: SKNode,
        currentHits: Int,
        requiredHits: Int,
        blockSize: CGSize
    ) {
        // Calcular progreso (0.0 a 1.0)
        let progress = CGFloat(currentHits) / CGFloat(requiredHits)
        
        // Actualizar contador numérico
        updateHitCounter(on: block, currentHits: currentHits, requiredHits: requiredHits, blockSize: blockSize)
        
        // Añadir textura de grietas con intensidad estándar
        addCracksTexture(to: block, progress: progress, blockType: "iceBlock", blockSize: blockSize)
        
        // Aumentar transparencia
        updateTransparency(for: block, progress: progress, blockType: "iceBlock")
        
        // Efecto de "golpe" temporal
        addImpactEffect(to: block)
        
        // Añadir partículas de hielo
        addIceParticles(to: block, intensity: 0.5)

    }
    
    /// Método para actualizar la apariencia de los bloques de hielo duro (con efectos más intensos)
    static func updateHardIceBlockAppearance(
        block: SKNode,
        currentHits: Int,
        requiredHits: Int,
        blockSize: CGSize
    ) {
        // Calcular progreso (0.0 a 1.0)
        let progress = CGFloat(currentHits) / CGFloat(requiredHits)
        
        // Actualizar contador numérico
        updateHitCounter(on: block, currentHits: currentHits, requiredHits: requiredHits, blockSize: blockSize)
        
        // Añadir textura de grietas con mayor intensidad para el hielo duro
        addCracksTexture(to: block, progress: progress, blockType: "hardiceBlock", blockSize: blockSize)
        
        // Cambiar transparencia más lentamente que el bloque normal de hielo
        updateTransparency(for: block, progress: progress * 0.7, blockType: "hardiceBlock")
        
        // Efecto de "golpe" más intenso
        addImpactEffect(to: block, intensity: 1.2)
        
        // Añadir partículas de hielo más intensas
        addIceParticles(to: block, intensity: 1.0)
        
        // Añadir un efecto de brillo temporal para hielo duro
        addFrostGlowEffect(to: block)
    }
    
    // Método para crear partículas de hielo al golpear
    private static func addIceParticles(to block: SKNode, intensity: CGFloat) {
        // Crear el nodo emisor
        let emitter = SKEmitterNode()
        emitter.name = "iceParticles"
        emitter.targetNode = block.parent // Para que las partículas se queden en la escena incluso si el bloque se mueve
        
        // Configurar las partículas
        emitter.particleBirthRate = 15 * intensity
        emitter.numParticlesToEmit = Int(10 * intensity)
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.3
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2 // Emitir en todas direcciones
        
        // Velocidad y tamaño
        emitter.particleSpeed = 20 * intensity
        emitter.particleSpeedRange = 15
        emitter.particleScale = 0.03 + (0.02 * intensity)
        emitter.particleScaleRange = 0.02
        emitter.xAcceleration = 0
        emitter.yAcceleration = -50 // Gravedad sutil
        
        // Color y apariencia
        emitter.particleColor = SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleAlpha = 0.7
        emitter.particleAlphaRange = 0.3
        emitter.particleTexture = SKTexture(imageNamed: "spark") // Usar una textura simple de chispa/partícula
        
        // Colocar el emisor en el centro del bloque
        emitter.position = .zero
        emitter.zPosition = 20
        
        // Añadir el emisor al bloque
        block.addChild(emitter)
        
        // Eliminar el emisor después de un tiempo
        let waitAction = SKAction.wait(forDuration: 0.3)
        let removeAction = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([waitAction, removeAction]))
    }
    
    // Método para añadir un efecto de brillo helado (sólo para bloques duros)
    private static func addFrostGlowEffect(to block: SKNode) {
        // Buscar el nodo de fondo
        guard let background = findBackgroundNode(in: block) else { return }
        
        // Crear un nodo de efecto para aplicar un filtro de brillo
        let glowNode = SKEffectNode()
        glowNode.name = "frostGlow"
        glowNode.zPosition = 2
        
        // Aplicar un filter de brillo
        glowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 3.0])
        glowNode.shouldRasterize = true
        
        // Crear una copia del fondo como forma con resplandor
        let glowShape = SKShapeNode(rectOf: background.frame.size, cornerRadius: 15)
        glowShape.fillColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.5)
        glowShape.strokeColor = .clear
        glowShape.alpha = 0
        
        glowNode.addChild(glowShape)
        
        // Añadir el nodo de brillo
        block.addChild(glowNode)
        
        // Animación de brillo
        let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: 0.1)
        let wait = SKAction.wait(forDuration: 0.1)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let remove = SKAction.removeFromParent()
        
        glowShape.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }
    
    // 5. Método para el contador numérico en la esquina superior derecha
    private static func updateHitCounter(
        on block: SKNode,
        currentHits: Int,
        requiredHits: Int,
        blockSize: CGSize
    ) {
        // Eliminar contador anterior si existe
        block.childNode(withName: "hitCounter")?.removeFromParent()
        
        // Calcular hits restantes
        let remainingHits = requiredHits - currentHits
        
        // Obtener información del estilo para personalizar el contador
        let blockStyle = block.userData?.value(forKey: "blockStyle") as? String ?? "defaultBlock"
        
        // Crear un nuevo nodo contenedor para el contador
        let counterContainer = SKNode()
        counterContainer.name = "hitCounter"
        counterContainer.zPosition = 10
        
        // Posicionarlo en la esquina superior derecha, con un pequeño margen
        counterContainer.position = CGPoint(x: blockSize.width/2 - 15, y: blockSize.height/2 - 15)
        
        // Configurar apariencia según el tipo de bloque
        let counterBg: SKShapeNode
        let radius: CGFloat = 12
        let counterColor: SKColor
        let textColor: SKColor
        
        switch blockStyle {
        case "iceBlock":
            counterBg = SKShapeNode(circleOfRadius: radius)
            counterColor = SKColor(red: 0.8, green: 0.95, blue: 1.0, alpha: 0.9)
            textColor = SKColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 1.0)
        case "hardiceBlock":
            counterBg = SKShapeNode(circleOfRadius: radius)
            counterColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.9)
            textColor = SKColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0)
            
            // Agregar borde más grueso para hardiceBlock
            counterBg.lineWidth = 2.0
            counterBg.strokeColor = SKColor(red: 0.0, green: 0.5, blue: 0.9, alpha: 0.8)
        default:
            counterBg = SKShapeNode(circleOfRadius: radius)
            counterColor = .white
            textColor = .darkGray
        }
        
        counterBg.fillColor = counterColor
        counterBg.strokeColor = textColor.withAlphaComponent(0.3)
        counterBg.lineWidth = 1.5
        counterBg.alpha = 0.85
        counterContainer.addChild(counterBg)
        
        // Crear etiqueta con el número
        let countLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        countLabel.text = "\(remainingHits)"
        countLabel.fontSize = 14
        countLabel.fontColor = textColor
        countLabel.verticalAlignmentMode = .center
        countLabel.horizontalAlignmentMode = .center
        countLabel.position = .zero
        counterContainer.addChild(countLabel)
        
        // Añadir el contador al bloque
        block.addChild(counterContainer)
        
        // Efecto de aparición
        counterContainer.setScale(0)
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.2)
        scaleAction.timingMode = .easeOut
        counterContainer.run(scaleAction)
    }
    
    // 6. Método para añadir grietas utilizando una textura de imagen
    private static func addCracksTexture(
        to block: SKNode,
        progress: CGFloat,
        blockType: String,
        blockSize: CGSize
    ) {
        // Eliminar grietas anteriores si existen
        block.childNode(withName: "cracksTexture")?.removeFromParent()
        
        // Crear nodo de sprite para la textura de grietas
        let cracksTexture = SKSpriteNode(imageNamed: "grietas.png")
        cracksTexture.name = "cracksTexture"
        cracksTexture.zPosition = 5
        
        // Ajustar el tamaño para que cubra todo el bloque
        cracksTexture.size = blockSize
        
        // Calcular la intensidad de la textura basada en el progreso y el tipo de bloque
        let baseAlpha: CGFloat = progress * 0.8
        var textureTint: SKColor
        
        switch blockType {
        case "iceBlock":
            // Para bloques de hielo regular, grietas más claras
            textureTint = SKColor.black.withAlphaComponent(baseAlpha)
        case "hardiceBlock":
            // Para bloques de hielo duro, grietas más azuladas y oscuras
            textureTint = SKColor(red: 0.0, green: 0.1, blue: 0.3, alpha: baseAlpha * 1.2)
        default:
            textureTint = SKColor.black.withAlphaComponent(baseAlpha)
        }
        
        // Configurar el tinte y la mezcla
        cracksTexture.color = textureTint
        cracksTexture.colorBlendFactor = 1.0
        
        // Añadir efecto de mezcla para que la textura se combine con el fondo
        cracksTexture.blendMode = .multiply
        
        // Añadir al bloque
        block.addChild(cracksTexture)
        
        // Añadir efecto de aparición
        cracksTexture.alpha = 0
        cracksTexture.run(SKAction.fadeIn(withDuration: 0.2))
    }
    
    // 7. Método para actualizar transparencia gradualmente
    private static func updateTransparency(
        for block: SKNode,
        progress: CGFloat,
        blockType: String
    ) {
        // Obtener el nodo de fondo del bloque
        guard let background = findBackgroundNode(in: block) else { return }
        
        // Ajustar la transparencia basada en el tipo de bloque
        let startAlpha: CGFloat
        let endAlpha: CGFloat
        
        switch blockType {
        case "iceBlock":
            // El hielo normal se vuelve bastante transparente
            startAlpha = 0.95
            endAlpha = 0.5
        case "hardiceBlock":
            // El hielo duro mantiene más opacidad
            startAlpha = 0.95
            endAlpha = 0.7
        default:
            startAlpha = 0.95
            endAlpha = 0.6
        }
        
        // Calcular nueva alpha basada en el progreso
        let newAlpha = startAlpha - (progress * (startAlpha - endAlpha))
        
        // Animar el cambio gradualmente
        let fadeAction = SKAction.fadeAlpha(to: newAlpha, duration: 0.3)
        fadeAction.timingMode = .easeOut
        background.run(fadeAction)
        
        // Para el hielo, también podemos cambiar sutilmente el color para simular "derretimiento"
        if blockType.contains("ice") {
            // Color base
            var baseColor: SKColor
            var targetColor: SKColor
            
            if blockType == "iceBlock" {
                // Azul claro a un tono más acuoso
                baseColor = SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: newAlpha)
                targetColor = SKColor(red: 0.9, green: 0.95, blue: 1.0, alpha: newAlpha)
            } else {
                // Azul más intenso a un tono más claro
                baseColor = SKColor(red: 0.6, green: 0.8, blue: 1.0, alpha: newAlpha)
                targetColor = SKColor(red: 0.7, green: 0.85, blue: 0.95, alpha: newAlpha)
            }
            
            // Mezclar colores según el progreso
            let blendedColor = blendColors(baseColor, targetColor, percentage: progress)
            
            // Animar el cambio de color
            let colorAction = SKAction.colorize(with: blendedColor, colorBlendFactor: 1.0, duration: 0.3)
            colorAction.timingMode = .easeOut
            background.run(colorAction)
        }
    }
    
    // 8. Método para añadir efecto visual de impacto
    private static func addImpactEffect(to block: SKNode, intensity: CGFloat = 1.0) {
        // Efecto de "golpe" - pulso rápido
        let scaleDown = SKAction.scale(to: 0.97, duration: 0.05 * intensity)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1 * intensity)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        block.run(sequence)
        
        // Pequeño temblor
        let shakeSequence = SKAction.sequence([
            SKAction.moveBy(x: 2 * intensity, y: 0, duration: 0.02),
            SKAction.moveBy(x: -4 * intensity, y: 0, duration: 0.04),
            SKAction.moveBy(x: 2 * intensity, y: 0, duration: 0.02)
        ])
        block.run(shakeSequence)
        
        // Efecto de pulsación en las grietas
        if let cracksTexture = block.childNode(withName: "cracksTexture") as? SKSpriteNode {
            let crackPulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 1.0, duration: 0.05),
                SKAction.fadeAlpha(to: cracksTexture.alpha, duration: 0.1)
            ])
            cracksTexture.run(crackPulse)
        }
    }
    
    // Método para encontrar el nodo de fondo en la jerarquía del bloque
    private static func findBackgroundNode(in block: SKNode) -> SKShapeNode? {
        // Buscar primero en los hijos directos
        for child in block.children {
            if let container = child as? SKNode {
                // Buscar en los hijos del contenedor
                for subChild in container.children {
                    if let background = subChild as? SKShapeNode {
                        return background
                    }
                }
            }
        }
        
        // Si no se encuentra, buscamos más profundamente
        return block.childNode(withName: "//background") as? SKShapeNode
    }
    
    // Función auxiliar para mezclar colores
    private static func blendColors(_ color1: SKColor, _ color2: SKColor, percentage: CGFloat) -> SKColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return SKColor(
            red: r1 + (r2 - r1) * percentage,
            green: g1 + (g2 - g1) * percentage,
            blue: b1 + (b2 - b1) * percentage,
            alpha: a1 + (a2 - a1) * percentage
        )
    }
}
