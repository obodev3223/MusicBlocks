//
//  GhostBlockEffects.swift
//  MusicBlocks
//
//  Creado por Jose R. García el 20/4/25.
//

import SpriteKit

/// A utility struct for managing visual effects specific to Ghost Block variations
struct GhostBlockEffects {
    
    // MARK: - Constants
    private struct Constants {
        // Niveles de transparencia
        static let maxVisibleAlpha: CGFloat = 0.9    // Más visible
        static let mediumVisibleAlpha: CGFloat = 0.6 // Visibilidad media
        static let lowVisibleAlpha: CGFloat = 0.3    // Poco visible
        static let minVisibleAlpha: CGFloat = 0.1    // Casi invisible
        
        // Duración de cada pulso (corta para que sea más errático)
        static let pulseDuration: TimeInterval = 0.3
        
        // Intervalos entre cambios (muy cortos para parecer pulsante)
        static let minPulseInterval: TimeInterval = 0.1
        static let maxPulseInterval: TimeInterval = 0.2
        
        // Para el timer que comprueba si el efecto sigue activo
        static let effectCheckInterval: TimeInterval = 0.5
    }
    
    // Clave para asociar el timer al bloque en userData
    private static let effectTimerKey = "ghostEffectTimer"
    private static let effectNodeKey = "ghostEffectNode"
    
    // MARK: - Public Methods
    
    /// Starts the ghost effect for a block, applying periodic transparency changes
    /// - Parameter block: The block node to apply effects to
    static func startGhostEffect(for block: SKNode) {
        GameLogger.shared.blockMovement("👻 Iniciando efecto fantasma pulsante para bloque")
        
        // Stop any existing ghost effects
        stopGhostEffect(for: block)
        
        // Create a dedicated node for the ghost effect that won't be affected by block movements
        let ghostEffectNode = SKNode()
        ghostEffectNode.name = "ghostEffectNode"
        block.addChild(ghostEffectNode)
        
        // Store a reference to this node in userData for easy access
        if block.userData == nil {
            block.userData = NSMutableDictionary()
        }
        block.userData?.setValue(ghostEffectNode, forKey: effectNodeKey)
        
        // Apply initial transparency appearance
        applyInitialTransparency(to: block)
        
        // Apply the effect action to the dedicated node instead of the block itself
        // This ensures it won't be removed by block.removeAllActions()
        applyGhostEffectToNode(ghostEffectNode, targetNode: findNodeForTransparency(in: block))
        
        // Set up a timer to check if the effect is still active
        setupEffectMonitor(for: block)
    }
    
    /// Stops the ghost effect for a block
    /// - Parameter block: The block node to stop effects for
    static func stopGhostEffect(for block: SKNode) {
        GameLogger.shared.blockMovement("🛑 Deteniendo efecto fantasma para bloque")
        
        // Remove the ghost effect node if it exists
        if let effectNode = block.userData?.value(forKey: effectNodeKey) as? SKNode {
            effectNode.removeFromParent()
        }
        
        // Stop the effect timer if it exists
        if let timer = block.userData?.value(forKey: effectTimerKey) as? Timer {
            timer.invalidate()
            block.userData?.removeObject(forKey: effectTimerKey)
        }
        
        // Reset transparency
        if let targetNode = findNodeForTransparency(in: block) {
            targetNode.alpha = 1.0
        }
    }
    
    /// Updates the ghost block appearance when hit - vacío ya que este tipo de bloque siempre es de un hit
    /// - Parameters:
    ///   - block: The block node to update
    ///   - currentHits: Number of hits (siempre 1)
    ///   - requiredHits: Total number of hits required (siempre 1)
    ///   - blockSize: Size of the block
    static func updateGhostBlockAppearance(
        block: SKNode,
        currentHits: Int,
        requiredHits: Int,
        blockSize: CGSize
    ) {
        // No hacemos nada aquí ya que este bloque siempre requiere un solo hit
        // y no tiene efectos especiales al ser golpeado
        GameLogger.shared.blockMovement("👻 Bloque fantasma golpeado")
    }
    
    // MARK: - Private Methods
    
    /// Sets up a timer to monitor if the ghost effect is still active
    /// - Parameter block: The block to monitor
    private static func setupEffectMonitor(for block: SKNode) {
        // Cancel any existing timer
        if let timer = block.userData?.value(forKey: effectTimerKey) as? Timer {
            timer.invalidate()
        }
        
        // Create a new timer that checks if the effect is still active
        let timer = Timer.scheduledTimer(withTimeInterval: Constants.effectCheckInterval, repeats: true) { _ in
            // Check if the block still exists and has a parent
            if block.parent == nil {
                // Block has been removed, stop the timer
                if let timer = block.userData?.value(forKey: effectTimerKey) as? Timer {
                    timer.invalidate()
                    block.userData?.removeObject(forKey: effectTimerKey)
                }
                return
            }
            
            // Check if the ghost effect node still exists
            if let effectNode = block.userData?.value(forKey: effectNodeKey) as? SKNode,
               effectNode.parent == block {
                // If the node exists but doesn't have the ghost effect action, reapply it
                if effectNode.action(forKey: "ghostEffect") == nil {
                    // The effect has been removed, reapply it
                    GameLogger.shared.blockMovement("👻 Reactivando efecto fantasma después de una interrupción")
                    applyGhostEffectToNode(effectNode, targetNode: findNodeForTransparency(in: block))
                }
            } else {
                // The ghost effect node has been removed, recreate it
                GameLogger.shared.blockMovement("👻 Recreando nodo de efecto fantasma")
                startGhostEffect(for: block)
            }
        }
        
        // Add the timer to RunLoop.common to ensure it runs during animations
        RunLoop.current.add(timer, forMode: .common)
        
        // Store the timer in userData for later cancellation
        block.userData?.setValue(timer, forKey: effectTimerKey)
    }
    
    /// Applies the ghost effect to a specific node
    /// - Parameters:
    ///   - effectNode: The node where the action will be applied
    ///   - targetNode: The node that will have its transparency modified
    private static func applyGhostEffectToNode(_ effectNode: SKNode, targetNode: SKNode?) {
        guard let targetNode = targetNode else { return }
        
        // Create the pulsing action that will modify the target node's transparency
        let pulsingAction = createPulsingAction(for: targetNode)
        
        // Apply the action to the effect node with a specific key
        effectNode.run(SKAction.repeatForever(pulsingAction), withKey: "ghostEffect")
    }
    
    /// Creates a pulsing action that alternates between different transparency levels
    /// - Parameter targetNode: The node whose transparency will be modified
    /// - Returns: A sequence of fade actions with random intervals
    private static func createPulsingAction(for targetNode: SKNode) -> SKAction {
        // Crear una secuencia de acciones con 5-7 pulsos aleatorios
        let numberOfPulses = Int.random(in: 5...7)
        var pulseActions: [SKAction] = []
        
        // Generar una secuencia de pulsos aleatoria
        for _ in 0..<numberOfPulses {
            // Seleccionar un nivel de transparencia aleatorio para este pulso
            let targetAlpha = randomTransparencyLevel()
            
            // Crear acción de fade con duración aleatoria
            let fadeDuration = Constants.pulseDuration * Double.random(in: 0.8...1.2)
            
            // Usar un bloque run para aplicar el fade al targetNode específico
            // Esto es clave para que el efecto funcione incluso cuando se eliminen acciones del bloque principal
            let fadeAction = SKAction.run {
                targetNode.run(SKAction.fadeAlpha(to: targetAlpha, duration: fadeDuration))
            }
            
            // Añadir pequeña espera entre pulsos (totalmente aleatoria)
            let waitDuration = Double.random(in: Constants.minPulseInterval...Constants.maxPulseInterval)
            let waitAction = SKAction.wait(forDuration: waitDuration + fadeDuration)
            
            // Añadir ambas acciones a la secuencia
            pulseActions.append(fadeAction)
            pulseActions.append(waitAction)
        }
        
        // Crear secuencia completa
        return SKAction.sequence(pulseActions)
    }
    
    /// Generates a random transparency level from predefined values
    /// - Returns: A random alpha value
    private static func randomTransparencyLevel() -> CGFloat {
        // Usar una array de posibles niveles de transparencia
        let alphaLevels = [
            Constants.maxVisibleAlpha,
            Constants.mediumVisibleAlpha,
            Constants.lowVisibleAlpha,
            Constants.minVisibleAlpha
        ]
        
        // Seleccionar un valor aleatorio
        return alphaLevels.randomElement() ?? Constants.mediumVisibleAlpha
    }
    
    /// Sets the initial transparency for a ghost block
    /// - Parameter block: The block node to modify
    private static func applyInitialTransparency(to block: SKNode) {
        // Definir a qué nodo aplicar la transparencia
        let targetNode: SKNode? = findNodeForTransparency(in: block)
        
        // Empezar con visibilidad media para que el efecto sea más notable
        targetNode?.alpha = Constants.mediumVisibleAlpha
    }
    
    /// Finds the appropriate node to apply transparency to
    /// - Parameter block: The block to search in
    /// - Returns: The node that should receive transparency effects
    private static func findNodeForTransparency(in block: SKNode) -> SKNode? {
        // Primero intentamos con el contenedor
        if let container = block.childNode(withName: "container") {
            return container
        }
        
        // Luego intentamos con el background
        if let background = findBackgroundNode(in: block) {
            return background
        }
        
        // Si no hay ninguno, usamos el bloque completo
        return block
    }
    
    /// Finds the background node in a block's hierarchy
    private static func findBackgroundNode(in block: SKNode) -> SKShapeNode? {
        // Direct search in children
        for child in block.children {
            if let background = child as? SKShapeNode,
               background.name == "background" {
                return background
            }
            
            // Search in container
            if let container = child as? SKNode,
               container.name == "container" {
                for subChild in container.children {
                    if let background = subChild as? SKShapeNode,
                       background.name == "background" {
                        return background
                    }
                }
            }
        }
        
        // Deep search as last resort
        return block.childNode(withName: "//background") as? SKShapeNode
    }
}
