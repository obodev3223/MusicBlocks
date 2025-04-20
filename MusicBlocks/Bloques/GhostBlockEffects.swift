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
    }
    
    // MARK: - Public Methods
    
    /// Starts the ghost effect for a block, applying periodic transparency changes
    /// - Parameter block: The block node to apply effects to
    static func startGhostEffect(for block: SKNode) {
        GameLogger.shared.blockMovement("👻 Iniciando efecto fantasma pulsante para bloque")
        
        // Stop any existing ghost effects
        stopGhostEffect(for: block)
        
        // Apply initial transparency appearance
        applyInitialTransparency(to: block)
        
        // Create and run a randomized pulsing action
        let pulsingAction = createPulsingAction()
        block.run(SKAction.repeatForever(pulsingAction), withKey: "ghostEffect")
    }
    
    /// Stops the ghost effect for a block
    /// - Parameter block: The block node to stop effects for
    static func stopGhostEffect(for block: SKNode) {
        GameLogger.shared.blockMovement("🛑 Deteniendo efecto fantasma para bloque")
        
        // Remove the ghostEffect action
        block.removeAction(forKey: "ghostEffect")
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
    
    /// Creates a pulsing action that alternates between different transparency levels
    /// - Returns: A sequence of fade actions with random intervals
    private static func createPulsingAction() -> SKAction {
        // Crear una secuencia de acciones con 5-7 pulsos aleatorios
        let numberOfPulses = Int.random(in: 5...7)
        var pulseActions: [SKAction] = []
        
        // Generar una secuencia de pulsos aleatoria
        for _ in 0..<numberOfPulses {
            // Seleccionar un nivel de transparencia aleatorio para este pulso
            let targetAlpha = randomTransparencyLevel()
            
            // Crear acción de fade con duración aleatoria
            let fadeDuration = Constants.pulseDuration * Double.random(in: 0.8...1.2)
            let fadeAction = SKAction.fadeAlpha(to: targetAlpha, duration: fadeDuration)
            
            // Añadir pequeña espera entre pulsos (totalmente aleatoria)
            let waitDuration = Double.random(in: Constants.minPulseInterval...Constants.maxPulseInterval)
            let waitAction = SKAction.wait(forDuration: waitDuration)
            
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
