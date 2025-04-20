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
        static let baseAlpha: CGFloat = 0.7
        static let minAlpha: CGFloat = 0.15
        static let maxAlpha: CGFloat = 0.85
        static let defaultFadeDuration: TimeInterval = 0.5
        static let fasterFadeDuration: TimeInterval = 0.3
        static let slowerFadeDuration: TimeInterval = 0.8
        static let minFlickerInterval: TimeInterval = 1.0
        static let maxFlickerInterval: TimeInterval = 3.0
        static let hitFlashDuration: TimeInterval = 0.2
        static let hitShakeMagnitude: CGFloat = 3.0
    }
    
    // MARK: - Public Methods
    
    /// Starts the ghost effect for a block, applying periodic transparency changes
    /// - Parameters:
    ///   - block: The block node to apply effects to
    ///   - intensity: Intensity of the ghost effect (1.0 = normal, higher = more aggressive)
    static func startGhostEffect(for block: SKNode, intensity: CGFloat = 1.0) {
        GameLogger.shared.blockMovement("👻 Iniciando efecto fantasma para bloque con intensidad \(intensity)")
        
        // Stop any existing ghost effects
        stopGhostEffect(for: block)
        
        // Create a new sequence of fade actions
        let fadeSequence = createRandomFadeSequence(intensity: intensity)
        
        // Apply initial transparent appearance
        applyInitialTransparency(to: block)
        
        // Create and run the repeating action
        let repeatAction = SKAction.repeatForever(fadeSequence)
        block.run(repeatAction, withKey: "ghostEffect")
        
        // Add shimmer particle effect
        addGhostShimmer(to: block, intensity: intensity)
    }
    
    /// Stops the ghost effect for a block
    /// - Parameter block: The block node to stop effects for
    static func stopGhostEffect(for block: SKNode) {
        GameLogger.shared.blockMovement("🛑 Deteniendo efecto fantasma para bloque")
        
        // Remove the ghostEffect action
        block.removeAction(forKey: "ghostEffect")
        
        // Remove shimmer particles
        block.childNode(withName: "ghostShimmer")?.removeFromParent()
    }
    
    /// Updates the ghost block appearance when hit
    /// - Parameters:
    ///   - block: The block node to update
    ///   - currentHits: Number of hits the block has received
    ///   - requiredHits: Total number of hits required to destroy the block
    ///   - blockSize: Size of the block
    static func updateGhostBlockAppearance(
        block: SKNode,
        currentHits: Int,
        requiredHits: Int,
        blockSize: CGSize
    ) {
        let progress = CGFloat(currentHits) / CGFloat(requiredHits)
        
        // Update hit counter
        updateHitCounter(on: block, currentHits: currentHits, requiredHits: requiredHits, blockSize: blockSize)
        
        // Temporarily increase visibility on hit
        flashGhostBlockOnHit(block)
        
        // Apply shake effect
        addShakeEffect(to: block)
        
        // Increase intensity or decrease visibility based on hits
        updateGhostIntensity(for: block, progress: progress)
        
        // Add ghostly particles burst
        addGhostParticlesBurst(to: block, intensity: 1.0 + progress)
    }
    
    /// Changes the ghost effect mode (e.g., more aggressive after being hit)
    /// - Parameters:
    ///   - block: The block node to modify
    ///   - mode: Mode of ghost behavior (normal, aggressive, etc.)
    static func changeGhostEffectMode(for block: SKNode, mode: GhostMode) {
        // Stop current effect
        stopGhostEffect(for: block)
        
        // Apply new effect based on mode
        switch mode {
        case .normal:
            startGhostEffect(for: block, intensity: 1.0)
        case .aggressive:
            startGhostEffect(for: block, intensity: 1.5)
        case .extreme:
            startGhostEffect(for: block, intensity: 2.0)
        }
        
        GameLogger.shared.blockMovement("👻 Modo fantasma cambiado a: \(mode)")
    }
    
    /// Ghost behavior modes
    enum GhostMode {
        case normal
        case aggressive
        case extreme
    }
    
    // MARK: - Private Methods
    
    /// Creates a random sequence of fade actions for ghost blocks
    /// - Parameter intensity: Intensity modifier
    /// - Returns: An SKAction sequence
    private static func createRandomFadeSequence(intensity: CGFloat) -> SKAction {
        let actions = SKAction.sequence([
            createRandomFadeAction(intensity: intensity),
            SKAction.wait(forDuration: randomFlickerInterval(intensity: intensity))
        ])
        
        return actions
    }
    
    /// Creates a random fade action (fade in or out)
    /// - Parameter intensity: Intensity modifier
    /// - Returns: A single fade action
    private static func createRandomFadeAction(intensity: CGFloat) -> SKAction {
        // Decide randomly whether to fade in or out
        let fadeIn = Bool.random()
        
        // Determine target alpha
        let targetAlpha: CGFloat
        if fadeIn {
            // When fading in, use a value between baseAlpha and maxAlpha
            targetAlpha = CGFloat.random(in: Constants.baseAlpha...Constants.maxAlpha)
        } else {
            // When fading out, use a value between minAlpha and baseAlpha
            // More aggressive = potentially more transparent
            let minAlphaAdjusted = max(Constants.minAlpha / intensity, 0.05)
            targetAlpha = CGFloat.random(in: minAlphaAdjusted...Constants.baseAlpha)
        }
        
        // Determine fade duration (more intense = faster changes)
        let fadeDuration: TimeInterval
        if intensity > 1.5 {
            fadeDuration = Constants.fasterFadeDuration / intensity
        } else if intensity < 0.8 {
            fadeDuration = Constants.slowerFadeDuration
        } else {
            fadeDuration = Constants.defaultFadeDuration
        }
        
        return SKAction.fadeAlpha(to: targetAlpha, duration: fadeDuration)
    }
    
    /// Determines a random interval between flickers
    /// - Parameter intensity: Intensity modifier
    /// - Returns: A random time interval
    private static func randomFlickerInterval(intensity: CGFloat) -> TimeInterval {
        // Higher intensity = shorter intervals between flickers
        let minInterval = Constants.minFlickerInterval / intensity
        let maxInterval = Constants.maxFlickerInterval / intensity
        
        return TimeInterval.random(in: minInterval...maxInterval)
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
    
    /// Adds a shimmer particle effect to ghost blocks
    /// - Parameters:
    ///   - block: The block node to modify
    ///   - intensity: Intensity of effect
    private static func addGhostShimmer(to block: SKNode, intensity: CGFloat) {
        // Remove any existing shimmer
        block.childNode(withName: "ghostShimmer")?.removeFromParent()
        
        // Create new emitter
        let emitter = SKEmitterNode()
        emitter.name = "ghostShimmer"
        emitter.targetNode = block
        
        // Particle configuration
        emitter.particleBirthRate = 2 * intensity
        emitter.particleLifetime = 1.5
        emitter.particleLifetimeRange = 0.5
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2
        
        // Particle dynamics
        emitter.particleSpeed = 5
        emitter.particleSpeedRange = 10
        emitter.particleScale = 0.05
        emitter.particleScaleRange = 0.02
        emitter.particleScaleSpeed = -0.03
        
        // Particle appearance
        emitter.particleColor = SKColor.white
        emitter.particleAlpha = 0.3
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -0.1
        emitter.particleBlendMode = .screen
        
        // Position
        emitter.position = .zero
        emitter.zPosition = 5
        
        // Add to block
        block.addChild(emitter)
    }
    
    /// Adds a particle burst when ghost block is hit
    /// - Parameters:
    ///   - block: The block node to modify
    ///   - intensity: Intensity of effect
    private static func addGhostParticlesBurst(to block: SKNode, intensity: CGFloat) {
        let emitter = SKEmitterNode()
        emitter.targetNode = block.parent
        
        // Particle configuration
        emitter.particleBirthRate = 50 * intensity
        emitter.numParticlesToEmit = Int(20 * intensity)
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2
        
        // Particle dynamics
        emitter.particleSpeed = 30 * intensity
        emitter.particleSpeedRange = 20
        emitter.particleScale = 0.05
        emitter.particleScaleRange = 0.03
        emitter.particleScaleSpeed = -0.04
        emitter.yAcceleration = -20
        
        // Particle appearance
        emitter.particleColor = SKColor(white: 0.9, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleAlpha = 0.7
        emitter.particleAlphaRange = 0.3
        emitter.particleAlphaSpeed = -0.8
        emitter.particleBlendMode = .screen
        
        // Position
        emitter.position = .zero
        emitter.zPosition = 10
        
        // Add to block, with auto-removal
        block.addChild(emitter)
        
        let waitAction = SKAction.wait(forDuration: 0.5)
        let removeAction = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([waitAction, removeAction]))
    }
    
    /// Makes the ghost block temporarily more visible when hit
    /// - Parameter block: The block node to modify
    private static func flashGhostBlockOnHit(_ block: SKNode) {
        // Stop the ghost effect temporarily
        let savedAction = block.action(forKey: "ghostEffect")
        block.removeAction(forKey: "ghostEffect")
        
        // Make the block fully visible briefly
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: Constants.hitFlashDuration / 2)
        let fadeOut = SKAction.fadeAlpha(to: Constants.baseAlpha, duration: Constants.hitFlashDuration / 2)
        
        // Apply to the container or background
        if let container = block.childNode(withName: "container") {
            container.run(SKAction.sequence([fadeIn, fadeOut])) {
                // Restore ghost effect
                if let action = savedAction {
                    block.run(action, withKey: "ghostEffect")
                }
            }
        } else if let background = findBackgroundNode(in: block) {
            background.run(SKAction.sequence([fadeIn, fadeOut])) {
                // Restore ghost effect
                if let action = savedAction {
                    block.run(action, withKey: "ghostEffect")
                }
            }
        }
    }
    
    /// Applies a shake effect to the block when hit
    /// - Parameter block: The block node to apply the effect to
    private static func addShakeEffect(to block: SKNode) {
        let magnitude = Constants.hitShakeMagnitude
        
        let shakeSequence = SKAction.sequence([
            SKAction.moveBy(x: magnitude, y: 0, duration: 0.02),
            SKAction.moveBy(x: -magnitude * 2, y: 0, duration: 0.04),
            SKAction.moveBy(x: magnitude, y: 0, duration: 0.02)
        ])
        
        block.run(shakeSequence)
    }
    
    /// Updates the ghost block's behavior intensity based on hit progression
    /// - Parameters:
    ///   - block: The block node to modify
    ///   - progress: Progress from 0.0 to 1.0 representing hit completion
    private static func updateGhostIntensity(for block: SKNode, progress: CGFloat) {
        // Determine the appropriate mode based on progress
        let mode: GhostMode
        
        if progress < 0.33 {
            mode = .normal
        } else if progress < 0.66 {
            mode = .aggressive
        } else {
            mode = .extreme
        }
        
        // Apply the new mode
        changeGhostEffectMode(for: block, mode: mode)
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
        
        let counterContainer = SKNode()
        counterContainer.name = "hitCounter"
        counterContainer.zPosition = 10
        
        // Position in top-right corner with slight margin
        counterContainer.position = CGPoint(x: blockSize.width/2 - 15, y: blockSize.height/2 - 15)
        
        // Configure ghost counter appearance
        let background = SKShapeNode(circleOfRadius: 12)
        background.fillColor = SKColor(white: 1.0, alpha: 0.8)
        background.strokeColor = SKColor(white: 0.8, alpha: 0.5)
        background.lineWidth = 2.0
        background.glowWidth = 2.0
        counterContainer.addChild(background)
        
        // Create label with remaining hits
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = "\(remainingHits)"
        label.fontSize = 14
        label.fontColor = SKColor(white: 0.3, alpha: 0.8)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        counterContainer.addChild(label)
        
        // Add counter to block with appearance animation
        block.addChild(counterContainer)
        
        // Animate counter appearance
        counterContainer.setScale(0)
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.2)
        scaleAction.timingMode = .easeOut
        counterContainer.run(scaleAction)
        
        // Add subtle flickering to counter
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.7)
        let fadeOut = SKAction.fadeAlpha(to: 0.7, duration: 0.7)
        let flicker = SKAction.sequence([fadeIn, fadeOut])
        counterContainer.run(SKAction.repeatForever(flicker))
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
