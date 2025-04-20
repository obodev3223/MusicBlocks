//
//  IceBlockEffects.swift
//  MusicBlocks
//
//  Creado por Jose R. García el 17/4/25.
//

import SpriteKit

/// A utility struct for managing visual effects specific to Ice Block variations
struct IceBlockEffects {
    // MARK: - Public Block Appearance Methods
    
    /// Updates the visual appearance of a standard Ice Block when hit
    /// - Parameters:
    ///   - block: The block node to modify
    ///   - currentHits: Number of hits the block has received
    ///   - requiredHits: Total number of hits required to destroy the block
    ///   - blockSize: Size of the block
    static func updateIceBlockAppearance(
        block: SKNode,
        currentHits: Int,
        requiredHits: Int,
        blockSize: CGSize
    ) {
        _ = calculateProgress(currentHits: currentHits, requiredHits: requiredHits)
        
        updateHitCounter(on: block, currentHits: currentHits, requiredHits: requiredHits, blockSize: blockSize)
        
        updateBlockDamageTexture(
            block: block,
            currentHits: currentHits,
            requiredHits: requiredHits,
            blockType: .iceBlock,
            blockSize: blockSize
        )
        
        addImpactEffect(to: block)
    }

    
    /// Updates the visual appearance of a Hard Ice Block when hit
    /// - Parameters:
    ///   - block: The block node to modify
    ///   - currentHits: Number of hits the block has received
    ///   - requiredHits: Total number of hits required to destroy the block
    ///   - blockSize: Size of the block
    static func updateHardIceBlockAppearance(
        block: SKNode,
        currentHits: Int,
        requiredHits: Int,
        blockSize: CGSize
    ) {
        _ = calculateProgress(currentHits: currentHits, requiredHits: requiredHits)
        
        updateHitCounter(on: block, currentHits: currentHits, requiredHits: requiredHits, blockSize: blockSize)
        
        updateBlockDamageTexture(
            block: block,
            currentHits: currentHits,
            requiredHits: requiredHits,
            blockType: .hardIceBlock,
            blockSize: blockSize
        )
        
        addImpactEffect(to: block, intensity: 1.2)
        addFrostGlowEffect(to: block)
    }

// NUEVO MÉTODO para actualizar la textura según el daño
    private static func updateBlockDamageTexture(
        block: SKNode,
        currentHits: Int,
        requiredHits: Int,
        blockType: BlockType,
        blockSize: CGSize
    ) {
        print("🔍 Buscando nodos correctos en el bloque para actualizar textura...")
        
        // Determinamos el estilo según el tipo de bloque
        let style: BlockStyle
        switch blockType {
        case .iceBlock:
            style = BlockStyle.iceBlock
        case .hardIceBlock:
            style = BlockStyle.hardiceBlock
        }
        
        // Verificamos si hay texturas de daño disponibles
        guard let damageTextures = style.damageTextures,
              !damageTextures.isEmpty else {
            print("⚠️ No hay texturas de daño disponibles")
            return
        }
        
        // Buscar el container que contiene el background
        guard let containerNode = block.childNode(withName: "container") else {
            print("❌ No se encontró el nodo container")
            return
        }
        
        // Calculamos qué textura usar basada en los hits actuales
        let textureIndex = min(currentHits - 1, damageTextures.count - 1)
        if textureIndex < 0 {
            print("⚠️ Índice de textura inválido: \(textureIndex)")
            return
        }
        
        let texture = damageTextures[textureIndex]
        print("✅ Usando textura de daño \(textureIndex + 1) de \(damageTextures.count)")
        
        // Buscar el background dentro del container
        if let backgroundNode = containerNode.childNode(withName: "background") {
            // Verificar si ya existe un nodo de textura
            if let existingTexture = backgroundNode.childNode(withName: "textureCrop") as? SKCropNode {
                // Actualizamos la textura existente
                if let textureSprite = existingTexture.children.first as? SKSpriteNode {
                    // Animación de cambio de textura
                    let fadeOut = SKAction.fadeAlpha(to: 0.7, duration: 0.1)
                    let changeTexture = SKAction.run {
                        textureSprite.texture = texture
                    }
                    let fadeIn = SKAction.fadeAlpha(to: style.textureOpacity, duration: 0.2)
                    let sequence = SKAction.sequence([fadeOut, changeTexture, fadeIn])
                    textureSprite.run(sequence)
                    
                    print("✅ Textura de daño actualizada en nodo existente")
                }
            } else {
                // Si no existe el nodo de textura, creamos uno nuevo
                let maskNode = SKShapeNode(rectOf: blockSize, cornerRadius: style.cornerRadius)
                maskNode.fillColor = .white
                maskNode.strokeColor = .clear
                
                let textureSprite = SKSpriteNode(texture: texture)
                textureSprite.size = blockSize
                textureSprite.alpha = style.textureOpacity
                textureSprite.zPosition = 2
                
                let cropNode = SKCropNode()
                cropNode.name = "textureCrop"
                cropNode.maskNode = maskNode
                cropNode.addChild(textureSprite)
                
                backgroundNode.addChild(cropNode)
                print("✅ Nuevo nodo de textura de daño creado")
            }
        } else {
            // Enfoque alternativo para buscar nodos más profundamente
            let backgroundShape = containerNode.childNode(withName: "background_shape") as? SKShapeNode
            
            if backgroundShape != nil {
                print("🔍 Encontrado nodo background_shape, creando efecto visual alternativo...")
                
                // Si no podemos modificar la textura, al menos modificamos el color/transparencia
                let alphaChange = 1.0 - (CGFloat(currentHits) / CGFloat(requiredHits) * 0.3)
                let colorChange = SKAction.colorize(
                    with: SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: alphaChange),
                    colorBlendFactor: CGFloat(currentHits) / CGFloat(requiredHits) * 0.5,
                    duration: 0.2
                )
                backgroundShape?.run(colorChange)
                
                // Añadir efecto visual para mostrar daño
                let crackEffect = SKSpriteNode(texture: texture)
                crackEffect.name = "damageEffect"
                crackEffect.size = blockSize
                crackEffect.alpha = 0.0
                crackEffect.zPosition = 1.5
                containerNode.addChild(crackEffect)
                
                let fadeIn = SKAction.fadeAlpha(to: 0.5, duration: 0.2)
                crackEffect.run(fadeIn)
                
                print("✅ Aplicado efecto visual alternativo")
            } else {
                print("❌ No se encontró estructura adecuada para aplicar textura de daño")
                // Último intento - buscar cualquier SKShapeNode para aplicar cambio visual
                let shapes = findAllShapeNodes(in: block)
                if let mainShape = shapes.first {
                    print("🔍 Encontrado shape alternativo, aplicando cambio visual básico")
                    
                    // Aplicar un cambio visual básico
                    let fadeAction = SKAction.fadeAlpha(
                        to: 0.8 - (CGFloat(currentHits) / CGFloat(requiredHits) * 0.3),
                        duration: 0.2
                    )
                    mainShape.run(fadeAction)
                }
            }
        }
        
        // Añadir efecto de partículas independientemente de si pudimos cambiar la textura
        addImpactParticles(to: block, intensity: CGFloat(currentHits) / CGFloat(requiredHits))
    }

    // Método auxiliar para encontrar todos los SKShapeNode en un nodo
    private static func findAllShapeNodes(in node: SKNode) -> [SKShapeNode] {
        var shapes: [SKShapeNode] = []
        
        // Verificar si el nodo actual es un SKShapeNode
        if let shape = node as? SKShapeNode {
            shapes.append(shape)
        }
        
        // Buscar en todos los hijos recursivamente
        for child in node.children {
            shapes.append(contentsOf: findAllShapeNodes(in: child))
        }
        
        return shapes
    }

    // Método auxiliar para añadir partículas de impacto
    private static func addImpactParticles(to block: SKNode, intensity: CGFloat) {
        // Crear emitter
        let emitter = SKEmitterNode()
        emitter.name = "impactParticles"
        emitter.targetNode = block.parent
        
        // Configuración de partículas
        emitter.particleBirthRate = 20 * intensity
        emitter.numParticlesToEmit = Int(15 * intensity)
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        
        // Dinámica de partículas
        emitter.particleSpeed = 25 * intensity
        emitter.particleSpeedRange = 10
        emitter.particleScale = 0.03
        emitter.particleScaleRange = 0.02
        emitter.xAcceleration = 0
        emitter.yAcceleration = -10
        
        // Apariencia de partículas
        emitter.particleColor = SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        emitter.particleAlpha = 0.7
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        
        // Posicionamiento
        emitter.position = .zero
        emitter.zPosition = 20
        block.addChild(emitter)
        
        // Auto-destrucción
        let waitAction = SKAction.wait(forDuration: 0.5)
        let removeAction = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([waitAction, removeAction]))
    }

    
    // MARK: - Private Visual Effect Methods
    
    /// Calculates the progress of block destruction
    /// - Parameters:
    ///   - currentHits: Number of hits received
    ///   - requiredHits: Total hits required
    /// - Returns: Progress as a CGFloat between 0.0 and 1.0
    private static func calculateProgress(currentHits: Int, requiredHits: Int) -> CGFloat {
        return CGFloat(currentHits) / CGFloat(requiredHits)
    }
    
    /// Determines the block type for visual effects
    private enum BlockType {
        case iceBlock
        case hardIceBlock
    }
    
    // Blends two colors based on a percentage
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
    
    /// Updates the hit counter display for blocks with multiple hits
    private static func updateHitCounter(
        on block: SKNode,
        currentHits: Int,
        requiredHits: Int,
        blockSize: CGSize
    ) {
        // Remove existing counter
        block.childNode(withName: "hitCounter")?.removeFromParent()
        
        let remainingHits = requiredHits - currentHits
        let blockStyle = block.userData?.value(forKey: "blockStyle") as? String ?? "defaultBlock"
        
        let counterContainer = SKNode()
        counterContainer.name = "hitCounter"
        counterContainer.zPosition = 10
        
        // Position in top-right corner with slight margin
        counterContainer.position = CGPoint(x: blockSize.width/2 - 15, y: blockSize.height/2 - 15)
        
        // Configure counter appearance based on block style
        let (counterBg, counterColor, textColor) = configureCounterStyle(for: blockStyle)
        counterContainer.addChild(counterBg)
        
        // Create label with remaining hits
        let countLabel = createCounterLabel(
            text: "\(remainingHits)",
            color: textColor
        )
        counterContainer.addChild(countLabel)
        
        // Add counter to block with appearance animation
        block.addChild(counterContainer)
        animateCounterAppearance(counterContainer)
    }
    
    /// Configures the visual style of the hit counter
    private static func configureCounterStyle(for blockStyle: String) -> (SKShapeNode, SKColor, SKColor) {
        let radius: CGFloat = 12
        
        switch blockStyle {
        case "iceBlock":
            let background = SKShapeNode(circleOfRadius: radius)
            background.fillColor = SKColor(red: 0.8, green: 0.95, blue: 1.0, alpha: 0.9)
            background.strokeColor = .clear
            return (background,
                    .clear,  // Cambiado de counterColor a .clear
                    SKColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 1.0))
            
        case "hardiceBlock":
            let background = SKShapeNode(circleOfRadius: radius)
            background.fillColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.9)
            background.strokeColor = SKColor(red: 0.0, green: 0.5, blue: 0.9, alpha: 0.8)
            background.lineWidth = 2.0
            return (background,
                    .clear,  // Cambiado de counterColor a .clear
                    SKColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0))
            
        default:
            let background = SKShapeNode(circleOfRadius: radius)
            background.fillColor = .white
            background.strokeColor = .clear
            return (background, .clear, .darkGray)
        }
    }
    
    /// Creates a label for the hit counter
    private static func createCounterLabel(text: String, color: SKColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = text
        label.fontSize = 14
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        return label
    }
    
    /// Animates the counter's appearance
    private static func animateCounterAppearance(_ counterContainer: SKNode) {
        counterContainer.setScale(0)
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.2)
        scaleAction.timingMode = .easeOut
        counterContainer.run(scaleAction)
    }
    
    /// Adds crack texture to the block
    private static func addCracksTexture(
        to block: SKNode,
        progress: CGFloat,
        blockType: BlockType,
        blockSize: CGSize
    ) {
        // Remove existing cracks
        block.childNode(withName: "cracksTexture")?.removeFromParent()
        
        // Create crack texture sprite
        let cracksTexture = SKSpriteNode(imageNamed: "grietas.png")
        cracksTexture.name = "cracksTexture"
        cracksTexture.zPosition = 5
        cracksTexture.size = blockSize
        
        // Determine crack texture appearance
        let baseAlpha: CGFloat = progress * 0.8
        let textureTint: SKColor
        
        switch blockType {
        case .iceBlock:
            textureTint = SKColor.black.withAlphaComponent(baseAlpha)
        case .hardIceBlock:
            textureTint = SKColor(red: 0.0, green: 0.1, blue: 0.3, alpha: baseAlpha * 1.2)
        }
        
        // Configure texture
        cracksTexture.color = textureTint
        cracksTexture.colorBlendFactor = 1.0
        cracksTexture.blendMode = .multiply
        
        // Add to block with fade-in effect
        block.addChild(cracksTexture)
        cracksTexture.alpha = 0
        cracksTexture.run(SKAction.fadeIn(withDuration: 0.2))
    }
    
    /// Updates block transparency based on destruction progress
    private static func updateTransparency(
        for block: SKNode,
        progress: CGFloat,
        blockType: BlockType
    ) {
        // Find background node
        guard let background = findBackgroundNode(in: block) else { return }
        
        // Determine transparency based on block type
        let (startAlpha, endAlpha) = determineAlphaRange(for: blockType)
        let newAlpha = startAlpha - (progress * (startAlpha - endAlpha))
        
        // Animate transparency change
        let fadeAction = SKAction.fadeAlpha(to: newAlpha, duration: 0.3)
        fadeAction.timingMode = .easeOut
        background.run(fadeAction)
        
        // Color blending for ice blocks
        if blockType != .iceBlock { return }
        
        let baseColor = SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: newAlpha)
        let targetColor = SKColor(red: 0.9, green: 0.95, blue: 1.0, alpha: newAlpha)
        
        let blendedColor = blendColors(baseColor, targetColor, percentage: progress)
        let colorAction = SKAction.colorize(with: blendedColor, colorBlendFactor: 1.0, duration: 0.3)
        colorAction.timingMode = .easeOut
        background.run(colorAction)
    }
    
    /// Determines alpha range based on block type
    private static func determineAlphaRange(for blockType: BlockType) -> (CGFloat, CGFloat) {
        switch blockType {
        case .iceBlock:
            return (0.95, 0.5)
        case .hardIceBlock:
            return (0.95, 0.7)
        }
    }
    
    /// Finds the background node in a block's hierarchy
    private static func findBackgroundNode(in block: SKNode) -> SKShapeNode? {
        // Buscar en los hijos directos
        for child in block.children {
            // Intentar convertir directamente a SKShapeNode
            if let background = child as? SKShapeNode,
               background.name == "background" {
                return background
            }
            
            // Si es un contenedor, buscar dentro de sus hijos
            if let container = child as? SKNode {
                for subChild in container.children {
                    if let background = subChild as? SKShapeNode,
                       background.name == "background" {
                        return background
                    }
                }
            }
        }
        
        // Búsqueda profunda como último recurso
        return block.childNode(withName: "//background") as? SKShapeNode
    }
    
    
    
    /// Adds impact effect when block is hit
    private static func addImpactEffect(to block: SKNode, intensity: CGFloat = 1.0) {
        // MEJORA: Pulso de escala más pronunciado
        let scaleDown = SKAction.scale(to: 0.92, duration: 0.05 * intensity) // Más reducción (antes 0.97)
        let scaleUp = SKAction.scale(to: 1.03, duration: 0.08 * intensity)   // Rebote por encima de 1.0
        let scaleNormal = SKAction.scale(to: 1.0, duration: 0.07 * intensity)
        let scaleSequence = SKAction.sequence([scaleDown, scaleUp, scaleNormal])
        block.run(scaleSequence)
        
        // MEJORA: Vibración más pronunciada
        let shakeSequence = SKAction.sequence([
            SKAction.moveBy(x: 3 * intensity, y: 1 * intensity, duration: 0.02),      // Aumentado y añadido movimiento vertical
            SKAction.moveBy(x: -6 * intensity, y: -2 * intensity, duration: 0.03),    // Aumentado y añadido movimiento vertical
            SKAction.moveBy(x: 5 * intensity, y: 2 * intensity, duration: 0.02),      // Nuevo paso
            SKAction.moveBy(x: -3 * intensity, y: 0, duration: 0.02),                 // Nuevo paso
            SKAction.moveBy(x: 1 * intensity, y: -1 * intensity, duration: 0.01)      // Regreso a posición
        ])
        block.run(shakeSequence)
            
        // Añadimos un flash de color para dar feedback visual adicional
        let flashOverlay = SKSpriteNode(color: .white, size: block.calculateAccumulatedFrame().size)
        flashOverlay.alpha = 0
        flashOverlay.zPosition = 100 // Por encima de todo
        flashOverlay.name = "impactFlash"
        block.addChild(flashOverlay)
        
        let flashAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.05),
            SKAction.fadeAlpha(to: 0, duration: 0.1),
            SKAction.removeFromParent()
        ])
        flashOverlay.run(flashAction)
        
    }

    
    /// Adds a frost glow effect for hard ice blocks
    private static func addFrostGlowEffect(to block: SKNode) {
        // Find background node
        guard let background = findBackgroundNode(in: block) else { return }
        
        // Create glow effect node
        let glowNode = SKEffectNode()
        glowNode.name = "frostGlow"
        glowNode.zPosition = 2
        glowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 3.0])
        glowNode.shouldRasterize = true
        
        // Create glow shape
        let glowShape = SKShapeNode(rectOf: background.frame.size, cornerRadius: 15)
        glowShape.fillColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.5)
        glowShape.strokeColor = .clear
        glowShape.alpha = 0
        
        glowNode.addChild(glowShape)
        block.addChild(glowNode)
        
        // Glow animation
        let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: 0.1)
        let wait = SKAction.wait(forDuration: 0.1)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let remove = SKAction.removeFromParent()
        
        glowShape.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }
}

// Añadir función para cambiar la nota del bloque

extension IceBlockEffects {
    
    /// Actualiza el contenido visual del bloque para mostrar una nueva nota
    /// - Parameters:
    ///   - block: El nodo del bloque a modificar
    ///   - newNote: La nueva nota musical a mostrar
    ///   - blockSize: Tamaño del bloque
    static func updateBlockNote(block: SKNode, newNote: MusicalNote, blockSize: CGSize) {
        // Eliminar el contenido actual primero
        block.childNode(withName: "content")?.removeFromParent()
        
        // Obtener el estilo desde userData
        guard let userData = block.userData,
              let styleData = userData.value(forKey: "blockStyle") as? String,
              let blockStyle = getBlockStyle(for: styleData) else {
            print("❌ No se pudo determinar el estilo del bloque para actualizar la nota")
            return
        }
        
        // Crear nuevo contenido con la nueva nota
        let contentNode = BlockContentGenerator.generateBlockContent(
            with: blockStyle,
            blockSize: blockSize,
            desiredNote: newNote,
            baseNoteX: 5,
            baseNoteY: 0,
            leftMargin: 30,
            rightMargin: 30
        )
        contentNode.name = "content"
        contentNode.position = .zero
        contentNode.zPosition = 3
        block.addChild(contentNode)
        
        // Actualizar userData con la nueva nota
        userData.setValue(newNote.fullName, forKey: "noteName")
        
        // Añadir un efecto visual para resaltar el cambio
        animateNoteChange(node: contentNode)
        
        GameLogger.shared.blockMovement("✏️ Nota del bloque actualizada a: \(newNote.fullName)")
    }
    
    /// Genera una animación para destacar el cambio de nota
    /// - Parameter node: El nodo de contenido a animar
    private static func animateNoteChange(node: SKNode) {
        // Escala inicial
        node.setScale(0.85)
        node.alpha = 0.7
        
        // Secuencia de animación
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let group = SKAction.group([scaleUp, fadeIn])
        group.timingMode = .easeOut
        
        // Ejecutar la animación
        node.run(group)
    }
    
    /// Obtiene el estilo de bloque a partir del nombre del estilo
    private static func getBlockStyle(for styleName: String) -> BlockStyle? {
        switch styleName {
        case "iceBlock": return .iceBlock
        case "hardiceBlock": return .hardiceBlock
        default: return nil
        }
    }
}
