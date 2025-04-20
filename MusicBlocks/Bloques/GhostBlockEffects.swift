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
        // Transparencia base y límites
        static let baseAlpha: CGFloat = 0.7
        static let minAlpha: CGFloat = 0.05  // Más transparente
        static let maxAlpha: CGFloat = 0.9
        
        // Duraciones de las transiciones (más rápidas)
        static let fadeDuration: TimeInterval = 0.2
        
        // Intervalos entre cambios (más cortos y radicales)
        static let minFlickerInterval: TimeInterval = 0.3
        static let maxFlickerInterval: TimeInterval = 0.7
    }
    
    // MARK: - Public Methods
    
    /// Starts the ghost effect for a block, applying periodic transparency changes
    /// - Parameter block: The block node to apply effects to
    static func startGhostEffect(for block: SKNode) {
        GameLogger.shared.blockMovement("👻 Iniciando efecto fantasma para bloque")
        
        // Stop any existing ghost effects
        stopGhostEffect(for: block)
        
        // Create a new sequence of fade actions
        let fadeSequence = createRandomFadeSequence()
        
        // Apply initial transparent appearance
        applyInitialTransparency(to: block)
        
        // Create and run the repeating action
        let repeatAction = SKAction.repeatForever(fadeSequence)
        block.run(repeatAction, withKey: "ghostEffect")
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
    
    /// Creates a random sequence of fade actions for ghost blocks
    /// - Returns: An SKAction sequence
    private static func createRandomFadeSequence() -> SKAction {
        let actions = SKAction.sequence([
            createRandomFadeAction(),
            SKAction.wait(forDuration: randomFlickerInterval())
        ])
        
        return actions
    }
    
    /// Creates a random fade action (fade in or out)
    /// - Returns: A single fade action
    private static func createRandomFadeAction() -> SKAction {
        // Decide randomly whether to fade in or out with mayor probabilidad de desvanecerse
        let fadeIn = Bool.random() && Bool.random()  // 25% probabilidad de aparecer, 75% de desaparecer
        
        // Determine target alpha
        let targetAlpha: CGFloat
        if fadeIn {
            // When fading in, use a value between baseAlpha and maxAlpha
            targetAlpha = CGFloat.random(in: Constants.baseAlpha...Constants.maxAlpha)
        } else {
            // When fading out, use a value between minAlpha and baseAlpha
            // Más probabilidad de desaparecer casi por completo
            targetAlpha = CGFloat.random(in: Constants.minAlpha...(Constants.baseAlpha * 0.6))
        }
        
        // Duración fija más corta para transiciones más rápidas y radicales
        return SKAction.fadeAlpha(to: targetAlpha, duration: Constants.fadeDuration)
    }
    
    /// Determines a random interval between flickers
    /// - Returns: A random time interval
    private static func randomFlickerInterval() -> TimeInterval {
        return TimeInterval.random(in: Constants.minFlickerInterval...Constants.maxFlickerInterval)
    }
    
    /// Sets the initial transparency for a ghost block
    /// - Parameter block: The block node to modify
    private static func applyInitialTransparency(to block: SKNode) {
        // Apply transparency to the container and background
        if let container = block.childNode(withName: "container") {
            container.alpha = Constants.baseAlpha
        } else if let background = findBackgroundNode(in: block) {
            background.alpha = Constants.baseAlpha
        } else {
            // Fallback - apply to whole block
            block.alpha = Constants.baseAlpha
        }
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
