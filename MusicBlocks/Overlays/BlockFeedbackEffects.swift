//
//  BlockFeedbackEffects.swift
//  MusicBlocks
//
//  Created on April 20, 2025.
//

import SpriteKit

/// Utilidad para añadir efectos visuales de retroalimentación a los bloques musicales
struct BlockFeedbackEffects {
    
    // MARK: - Constants
    private struct Constants {
        // Colores
        static let successColor = SKColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 1.0)  // Verde más brillante
        static let failureColor = SKColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0)  // Rojo más intenso
        
        // Duración de animaciones - VALORES REDUCIDOS para que sean más rápidos
        static let successGlowDuration: TimeInterval = 0.25  // Más corto para que el bloque desaparezca rápido
        static let failureGlowDuration: TimeInterval = 0.2   // Muy corto para no interferir con la animación de caída
        static let borderFlashDuration: TimeInterval = 0.2    // Más rápido
        
        // Propiedades visuales
        static let successGlowRadius: Float = 15.0
        static let failureGlowRadius: Float = 12.0
        static let originalBorderWidth: CGFloat = 3.0
        static let successBorderWidth: CGFloat = 5.0
        static let failureBorderWidth: CGFloat = 4.0
        
        // Propiedades para efectos adicionales
        static let failureShakeIntensity: CGFloat = 3.0  // Reducido para ser menos disruptivo
    }
    
    // MARK: - Success Effects
    
    /// Añade un efecto visual de éxito al bloque
    /// - Parameter block: El nodo del bloque a modificar
    static func showSuccessFeedback(for block: SKNode) {
        // Guardar el color original del borde para restaurarlo después
        saveOriginalBorderColor(for: block)
        
        // Cambiar el color del borde a verde y aumentar su grosor
        changeBorderColor(for: block, to: Constants.successColor, newWidth: Constants.successBorderWidth)
        
        // Añadir efecto de brillo (glow) verde
        addSuccessGlowEffect(to: block)
        
        // Añadir efecto de "pulso" para enfatizar el acierto
        addSuccessPulseEffect(to: block)
        
        // Programar la restauración de la apariencia original
        scheduleAppearanceReset(for: block, duration: Constants.successGlowDuration)
    }
    
    // MARK: - Failure Effects
    
    /// Añade un efecto visual de fallo al bloque
    /// - Parameter block: El nodo del bloque a modificar
    static func showFailureFeedback(for block: SKNode) {
        // Guardar el color original del borde para restaurarlo después
        saveOriginalBorderColor(for: block)
        
        // Cambiar el color del borde a rojo y aumentar su grosor
        changeBorderColor(for: block, to: Constants.failureColor, newWidth: Constants.failureBorderWidth)
        
        // Añadir efecto de brillo (glow) rojo
        addFailureGlowEffect(to: block)
        
        // Añadir un efecto de "sacudida" (shake) para enfatizar el error
        addFailureShakeEffect(to: block)
        
        // Programar la restauración de la apariencia original
        scheduleAppearanceReset(for: block, duration: Constants.failureGlowDuration)
    }
    
    // MARK: - Private Helper Methods
    
    /// Guarda el color original del borde para restaurarlo después
    /// - Parameter block: El nodo del bloque
    private static func saveOriginalBorderColor(for block: SKNode) {
        // Buscar el nodo de fondo del bloque
        guard let backgroundShape = findBackgroundShape(in: block) else { return }
        
        // Guardar el color original del borde en userData
        if block.userData == nil {
            block.userData = NSMutableDictionary()
        }
        
        block.userData?.setValue(backgroundShape.strokeColor, forKey: "originalBorderColor")
        block.userData?.setValue(backgroundShape.lineWidth, forKey: "originalBorderWidth")
    }
    
    /// Cambia el color del borde del bloque
    /// - Parameters:
    ///   - block: El nodo del bloque
    ///   - color: El nuevo color para el borde
    ///   - newWidth: El nuevo ancho del borde
    private static func changeBorderColor(for block: SKNode, to color: SKColor, newWidth: CGFloat = Constants.successBorderWidth) {
        // Buscar el nodo de fondo del bloque
        guard let backgroundShape = findBackgroundShape(in: block) else { return }
        
        // Animación para cambiar el color y grosor del borde
        let colorAction = SKAction.customAction(withDuration: Constants.borderFlashDuration) { node, time in
            // Crear un factor de progreso para la interpolación de color
            let progress = time / CGFloat(Constants.borderFlashDuration)
            
            if let shape = node as? SKShapeNode {
                // Cambiar el color del borde
                shape.strokeColor = color
                
                // Aumentar el grosor del borde durante la primera mitad
                if progress < 0.5 {
                    // 0.0 -> 0.5: aumentar grosor
                    shape.lineWidth = Constants.originalBorderWidth +
                                     (newWidth - Constants.originalBorderWidth) * (progress * 2)
                } else {
                    // 0.5 -> 1.0: disminuir grosor
                    shape.lineWidth = newWidth -
                                     (newWidth - Constants.originalBorderWidth) * ((progress - 0.5) * 2)
                }
            }
        }
        
        backgroundShape.run(colorAction)
    }
    
    /// Añade un efecto de brillo rojo específico para el fallo
    /// - Parameter block: El nodo del bloque
    private static func addFailureGlowEffect(to block: SKNode) {
        // Eliminar cualquier efecto de brillo existente
        block.childNode(withName: "feedbackGlow")?.removeFromParent()
        block.childNode(withName: "feedbackFlash")?.removeFromParent()
        
        // Buscar el nodo de fondo para obtener la forma
        guard let backgroundShape = findBackgroundShape(in: block) else { return }
        
        // 1. EFECTO DE BRILLO (GLOW) PARA EL BORDE
        let glowNode = SKEffectNode()
        glowNode.name = "feedbackGlow"
        glowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": Constants.failureGlowRadius])
        glowNode.shouldRasterize = true
        glowNode.zPosition = -0.5  // Ponerlo detrás del contenido principal
        
        // Crear forma para el brillo usando la misma geometría que el fondo
        let glowShape = SKShapeNode(path: backgroundShape.path!)
        glowShape.fillColor = .clear  // Sin relleno para el fallo
        glowShape.strokeColor = Constants.failureColor
        glowShape.lineWidth = Constants.failureBorderWidth * 1.8  // Más ancho para el fallo
        glowNode.addChild(glowShape)
        
        // Añadir el efecto de brillo al bloque
        block.addChild(glowNode)
        
        // Animación para el brillo (más corta para el fallo)
        let fadeIn = SKAction.fadeIn(withDuration: Constants.failureGlowDuration * 0.2)
        let wait = SKAction.wait(forDuration: Constants.failureGlowDuration * 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: Constants.failureGlowDuration * 0.3)
        let remove = SKAction.removeFromParent()
        
        glowNode.alpha = 0
        glowNode.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
        
        // 2. EFECTO DE DESTELLO (FLASH) PARA TODO EL BLOQUE
        // Calcular el tamaño del bloque
        let blockSize = block.calculateAccumulatedFrame().size
        
        // Crear sprite para el destello que cubre todo el bloque
        let flashNode = SKSpriteNode(color: Constants.failureColor, size: blockSize)
        flashNode.name = "feedbackFlash"
        flashNode.alpha = 0
        flashNode.zPosition = 50  // Por encima de todo para que se vea el destello
        flashNode.blendMode = .add  // Usar blend mode 'add' para un efecto más luminoso
        
        // Asegurar que el destello está centrado en el bloque
        flashNode.position = CGPoint(x: 0, y: 0)
        
        // Añadir el destello al bloque
        block.addChild(flashNode)
        
        // Animación para el destello (más agresiva e intensa para el fallo)
        let flashIn = SKAction.fadeAlpha(to: 0.4, duration: 0.05)  // Más rápido e intenso
        let flashOut = SKAction.fadeAlpha(to: 0, duration: 0.15)
        let flashSequence = SKAction.sequence([flashIn, flashOut, SKAction.removeFromParent()])
        
        flashNode.run(flashSequence)
    }
    
    /// Añade un efecto de sacudida (shake) para el fallo
    /// - Parameter block: El nodo del bloque
    private static func addFailureShakeEffect(to block: SKNode) {
        // Guardar la posición original del bloque
        let originalPosition = block.position
        
        // Secuencia de movimientos para simular sacudida (más sutiles para no interferir con la animación de caída)
        let shakeAction = SKAction.customAction(withDuration: 0.3) { node, elapsedTime in
            // Calcular intensidad basada en el tiempo (decrece con el tiempo)
            let intensity = max(Constants.failureShakeIntensity * (1.0 - elapsedTime / 0.3), 0.01)
            
            // Calcular desplazamiento aleatorio (solo horizontal para no afectar la caída vertical)
            // Aseguramos que intensity sea positivo para evitar el error "Range requires lowerBound <= upperBound"
            let xOffset = CGFloat.random(in: -intensity...intensity)
            
            // Aplicar movimiento relativo a la posición original
            node.position = CGPoint(x: originalPosition.x + xOffset, y: originalPosition.y)
        }
        
        // Restaurar la posición original después del efecto
        let resetAction = SKAction.run {
            // No restauramos completamente para no interferir con animaciones en curso
            // Solo corregimos el componente X para eliminar el efecto lateral
            block.position = CGPoint(x: originalPosition.x, y: block.position.y)
        }
        
        // Ejecutar secuencia con un nombre específico para identificarla
        block.run(SKAction.sequence([shakeAction, resetAction]), withKey: "shakeEffect")
    }
    
    /// Añade líneas de "error" al bloque
    /// - Parameters:
    ///   - block: El nodo del bloque
    ///   - size: El tamaño del bloque
    private static func addErrorLines(to block: SKNode, size: CGSize) {
        // Crear un nodo contenedor para las líneas
        let linesContainer = SKNode()
        linesContainer.name = "errorLines"
        linesContainer.zPosition = 60  // Por encima de otros efectos
        
        // Reducir un poco el tamaño para no salirse del bloque
        let width = size.width * 0.7
        let height = size.height * 0.7
        
        // Crear dos líneas diagonales (formando una X)
        let diagonal1 = SKShapeNode()
        let path1 = CGMutablePath()
        path1.move(to: CGPoint(x: -width/2, y: -height/2))
        path1.addLine(to: CGPoint(x: width/2, y: height/2))
        diagonal1.path = path1
        diagonal1.strokeColor = Constants.failureColor
        diagonal1.lineWidth = 3.0
        diagonal1.alpha = 0.7
        linesContainer.addChild(diagonal1)
        
        let diagonal2 = SKShapeNode()
        let path2 = CGMutablePath()
        path2.move(to: CGPoint(x: width/2, y: -height/2))
        path2.addLine(to: CGPoint(x: -width/2, y: height/2))
        diagonal2.path = path2
        diagonal2.strokeColor = Constants.failureColor
        diagonal2.lineWidth = 3.0
        diagonal2.alpha = 0.7
        linesContainer.addChild(diagonal2)
        
        // Añadir al bloque
        block.addChild(linesContainer)
        
        // Animación: aparecer y desaparecer
        linesContainer.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let wait = SKAction.wait(forDuration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        
        linesContainer.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }
    
    /// Añade un efecto de sacudida (shake) al bloque
    /// - Parameter block: El nodo del bloque
    private static func addShakeEffect(to block: SKNode) {
        // Secuencia de movimientos pequeños para simular sacudida
        let shakeSequence = SKAction.sequence([
            SKAction.moveBy(x: 4, y: 0, duration: 0.05),
            SKAction.moveBy(x: -8, y: 0, duration: 0.05),
            SKAction.moveBy(x: 8, y: 0, duration: 0.05),
            SKAction.moveBy(x: -6, y: 0, duration: 0.05),
            SKAction.moveBy(x: 4, y: 0, duration: 0.05),
            SKAction.moveBy(x: -2, y: 0, duration: 0.05)
        ])
        
        block.run(shakeSequence)
    }
    
    /// Programa la restauración de la apariencia original del bloque
    /// - Parameters:
    ///   - block: El nodo del bloque
    ///   - duration: La duración después de la cual restaurar la apariencia
    private static func scheduleAppearanceReset(for block: SKNode, duration: TimeInterval = Constants.borderFlashDuration) {
        // Programar la restauración del color original después de un tiempo
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            resetBlockAppearance(for: block)
        }
    }
    
    /// Añade un efecto de brillo específico para el éxito
    /// - Parameter block: El nodo del bloque
    private static func addSuccessGlowEffect(to block: SKNode) {
        // Eliminar cualquier efecto de brillo existente
        block.childNode(withName: "feedbackGlow")?.removeFromParent()
        block.childNode(withName: "feedbackFlash")?.removeFromParent()
        
        // Buscar el nodo de fondo para obtener la forma
        guard let backgroundShape = findBackgroundShape(in: block) else { return }
        
        // 1. EFECTO DE BRILLO (GLOW) PARA EL BORDE
        let glowNode = SKEffectNode()
        glowNode.name = "feedbackGlow"
        glowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": Constants.successGlowRadius])
        glowNode.shouldRasterize = true
        glowNode.zPosition = -0.5  // Ponerlo detrás del contenido principal
        
        // Crear forma para el brillo usando la misma geometría que el fondo
        let glowShape = SKShapeNode(path: backgroundShape.path!)
        glowShape.fillColor = Constants.successColor.withAlphaComponent(0.1)  // Un poco de relleno para el éxito
        glowShape.strokeColor = Constants.successColor
        glowShape.lineWidth = Constants.successBorderWidth * 1.5
        glowNode.addChild(glowShape)
        
        // Añadir el efecto de brillo al bloque
        block.addChild(glowNode)
        
        // Animación para el brillo
        let fadeIn = SKAction.fadeIn(withDuration: Constants.successGlowDuration * 0.3)
        let wait = SKAction.wait(forDuration: Constants.successGlowDuration * 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: Constants.successGlowDuration * 0.4)
        let remove = SKAction.removeFromParent()
        
        glowNode.alpha = 0
        glowNode.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
        
        // 2. EFECTO DE DESTELLO (FLASH) PARA TODO EL BLOQUE
        // Calcular el tamaño del bloque
        let blockSize = block.calculateAccumulatedFrame().size
        
        // Crear sprite para el destello que cubre todo el bloque
        let flashNode = SKSpriteNode(color: Constants.successColor, size: blockSize)
        flashNode.name = "feedbackFlash"
        flashNode.alpha = 0
        flashNode.zPosition = 50  // Por encima de todo para que se vea el destello
        flashNode.blendMode = .add  // Usar blend mode 'add' para un efecto más luminoso
        
        // Asegurar que el destello está centrado en el bloque
        flashNode.position = CGPoint(x: 0, y: 0)
        
        // Añadir el destello al bloque
        block.addChild(flashNode)
        
        // Animación para el destello (más rápida que el glow)
        let flashIn = SKAction.fadeAlpha(to: 0.3, duration: 0.1)
        let flashOut = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let flashSequence = SKAction.sequence([flashIn, flashOut, SKAction.removeFromParent()])
        
        flashNode.run(flashSequence)
    }
    

    
    /// Añade un efecto de pulso al bloque para indicar éxito
    /// - Parameter block: El nodo del bloque
    private static func addSuccessPulseEffect(to block: SKNode) {
        // Guardar la escala original del bloque para poder revertir a ella
        let originalScale = block.xScale // Asumimos que xScale y yScale son iguales
        
        // Un pulso es una secuencia de escala: normal -> ligeramente más grande -> normal
        let scaleUp = SKAction.scale(to: originalScale * 1.05, duration: 0.1)
        let scaleDown = SKAction.scale(to: originalScale, duration: 0.15)
        
        // Usar timingMode para un efecto más natural
        scaleUp.timingMode = .easeOut
        scaleDown.timingMode = .easeIn
        
        // Ejecutar la secuencia
        block.run(SKAction.sequence([scaleUp, scaleDown]), withKey: "pulseEffect")
    }
    
    /// Restaura la apariencia original del bloque
    /// - Parameter block: El nodo del bloque
    private static func resetBlockAppearance(for block: SKNode) {
        // Verificar que el bloque aún existe en la escena
        guard block.parent != nil else { return }
        
        // Restaurar el color original del borde
        guard let backgroundShape = findBackgroundShape(in: block),
              let originalColor = block.userData?.value(forKey: "originalBorderColor") as? SKColor,
              let originalWidth = block.userData?.value(forKey: "originalBorderWidth") as? CGFloat else {
            return
        }
        
        // Animación para restaurar el color original
        let resetAction = SKAction.customAction(withDuration: 0.2) { node, time in
            if let shape = node as? SKShapeNode {
                shape.strokeColor = originalColor
                shape.lineWidth = originalWidth
            }
        }
        
        backgroundShape.run(resetAction)
        
        // Eliminar todos los nodos de efectos que pudieran quedar
        block.childNode(withName: "feedbackGlow")?.removeFromParent()
        block.childNode(withName: "feedbackFlash")?.removeFromParent()
        block.childNode(withName: "errorLines")?.removeFromParent()
        
        // NO restauramos la posición ni la escala para evitar interferir con las animaciones de caída
        // ELIMINADO: block.position = .zero
        // ELIMINADO: block.setScale(1.0)
        
        // Eliminamos solo las acciones relacionadas con los efectos visuales
        // pero NO todas las acciones para no interferir con la animación de caída
        // MODIFICADO: No eliminamos todas las acciones
        // ELIMINADO: block.removeAllActions()
    }
    
    /// Busca y devuelve el nodo de forma del fondo del bloque
    /// - Parameter block: El nodo del bloque
    /// - Returns: El nodo de forma del fondo, si se encuentra
    private static func findBackgroundShape(in block: SKNode) -> SKShapeNode? {
        // ESTRATEGIA 1: Buscar por nombre específico en toda la jerarquía
        if let backgroundShape = block.childNode(withName: "//background_shape") as? SKShapeNode {
            return backgroundShape
        }
        
        // ESTRATEGIA 2: Buscar el primer SKShapeNode dentro del nodo "background"
        if let background = block.childNode(withName: "//background") {
            for child in background.children {
                if let shape = child as? SKShapeNode {
                    return shape
                }
            }
            
            // Si el background mismo es un SKShapeNode
            if let shape = background as? SKShapeNode {
                return shape
            }
        }
        
        // ESTRATEGIA 3: Buscar el primer SKShapeNode dentro del contenedor
        if let container = block.childNode(withName: "container") {
            for child in container.children {
                if let shape = child as? SKShapeNode {
                    return shape
                }
            }
        }
        
        // ESTRATEGIA 4: Buscar cualquier SKShapeNode en el primer nivel
        for child in block.children {
            if let shape = child as? SKShapeNode {
                return shape
            }
        }
        
        // ESTRATEGIA 5: Si todo lo demás falla, realizar una búsqueda profunda recursiva
        return findFirstShapeNodeRecursively(in: block)
    }
    
    /// Realiza una búsqueda recursiva para encontrar el primer SKShapeNode
    /// - Parameter node: El nodo a partir del cual buscar
    /// - Returns: El primer SKShapeNode encontrado, o nil si no se encuentra ninguno
    private static func findFirstShapeNodeRecursively(in node: SKNode) -> SKShapeNode? {
        // Primero buscar en los hijos directos
        for child in node.children {
            if let shape = child as? SKShapeNode {
                return shape
            }
            
            // Búsqueda recursiva en los hijos
            if let shape = findFirstShapeNodeRecursively(in: child) {
                return shape
            }
        }
        
        return nil
    }
}
