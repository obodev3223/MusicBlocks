//
//  BlocksManager.swift
//  MusicBlocks
//
//  Created by Jose R. García on 14/3/25.
//  Refactored for improved modularity and readability
//

import SpriteKit

/// Manages the generation, tracking, and interaction of blocks in the game
class BlocksManager {
    // MARK: - Block Management Properties
    
    /// Collection of active block information
    private var blockInfos: [BlockInfo] = []
    
    /// Collection of active block nodes
    private var blocks: [SKNode] = []
    
    /// Size of individual blocks
    private let blockSize: CGSize
    
    /// Spacing between blocks
    private let blockSpacing: CGFloat
    
    /// Node containing the main game area
    private weak var mainAreaNode: SKNode?
    
    /// Height of the main game area
    private var mainAreaHeight: CGFloat = 0
    
    // MARK: - Block Generation Properties
    
    /// Interval between block spawns (in seconds)
    private var spawnInterval: TimeInterval
    
    /// Decrease in spawn interval after each block
    private var spawnIntervalDecrement: TimeInterval
    
    /// Flag indicating if blocks are currently being generated
    private var isGeneratingBlocks: Bool = false
    
    // MARK: - Block Processing State
    
    /// Flag indicating if a block is currently being processed
    public var isProcessingBlock: Bool = false
    
    /// Timestamp of the last block hit
    private var lastHitTime: Date? = nil
    
    /// Timestamp of processing start
    private var processingStartTime: Date?
    
    // MARK: - Dependencies
    
    /// Game manager for level and configuration access
    private let gameManager = GameManager.shared
    
    // MARK: - Initialization
    
    /// Initializes a new BlocksManager
    /// - Parameters:
    ///   - blockSize: Size of individual blocks
    ///   - blockSpacing: Spacing between blocks
    ///   - mainAreaNode: Node containing the main game area
    ///   - mainAreaHeight: Height of the main game area
    init(
        blockSize: CGSize = CGSize(width: 280, height: 120),
        blockSpacing: CGFloat = 1.0,
        mainAreaNode: SKNode?,
        mainAreaHeight: CGFloat
    ) {
        self.blockSize = blockSize
        self.blockSpacing = blockSpacing
        self.mainAreaNode = mainAreaNode
        self.mainAreaHeight = mainAreaHeight
        
        // Configure spawn intervals from current level
        if let fallingSpeed = GameManager.shared.currentLevel?.fallingSpeed {
            self.spawnInterval = fallingSpeed.initial
            self.spawnIntervalDecrement = fallingSpeed.increment
        } else {
            // Default values if no level configuration
            self.spawnInterval = 4.0
            self.spawnIntervalDecrement = 0.0
        }
        
        GameLogger.shared.blockMovement("""
            BlocksManager initialized:
            - Block Size: \(blockSize)
            - Main Area Height: \(mainAreaHeight)
            - Initial Spawn Interval: \(spawnInterval)s
            - Spawn Interval Decrement: \(spawnIntervalDecrement)s
            """)
    }
    
    // MARK: - Block Generation Methods
    
    /// Starts generating blocks
    func startBlockGeneration() {
        guard !isGeneratingBlocks else {
            GameLogger.shared.blockMovement("Block generation already in progress")
            return
        }
        
        isGeneratingBlocks = true
        
        // Initial delay before first block
        let initialDelay = SKAction.wait(forDuration: 1.0)
        let beginAction = SKAction.run { [weak self] in
            self?.spawnLoop()
        }
        
        let sequence = SKAction.sequence([initialDelay, beginAction])
        mainAreaNode?.run(sequence)
        
        GameLogger.shared.blockMovement("Block generation started - Initial spawn interval: \(spawnInterval)s")
    }
    
    /// Recursive loop for block generation
    private func spawnLoop() {
        // Check if block generation should continue
        guard isGeneratingBlocks else {
            GameLogger.shared.blockMovement("Block generation stopped")
            return
        }
        
        // Generate a block
        spawnBlock()
        
        // Adjust spawn interval (accelerate)
        let newInterval = max(spawnInterval - spawnIntervalDecrement, 1.5)
        spawnInterval = newInterval
        
        GameLogger.shared.blockMovement("New spawn interval: \(spawnInterval)s")
        
        // Schedule next block spawn
        let wait = SKAction.wait(forDuration: spawnInterval)
        let nextCall = SKAction.run { [weak self] in
            self?.spawnLoop()
        }
        let sequence = SKAction.sequence([wait, nextCall])
        
        mainAreaNode?.run(sequence)
    }
    
    /// Stops block generation
    func stopBlockGeneration() {
        guard isGeneratingBlocks else {
            GameLogger.shared.blockMovement("Block generation already stopped")
            return
        }
        
        isGeneratingBlocks = false
        mainAreaNode?.removeAllActions()
        
        GameLogger.shared.blockMovement("Block generation stopped")
    }
    
    /// Spawns a new block in the game area
    func spawnBlock() {
        guard let mainAreaNode = mainAreaNode, isGeneratingBlocks else {
            GameLogger.shared.blockMovement("Cannot spawn block: generation stopped or no main area")
            return
        }
        
        // Check available space
        if let firstBlock = blocks.first {
            let topLimit = mainAreaHeight/2 - blockSize.height/2
            let firstBlockTopEdge = firstBlock.position.y + blockSize.height/2
            
            if abs(firstBlockTopEdge - topLimit) < blockSpacing {
                GameLogger.shared.blockMovement("Waiting for space to spawn new block")
                return
            }
        }
        
        // Create and add new block
        let newBlock = createBlock()
        
        if let blockInfo = createBlockInfo(for: newBlock) {
            let startY = mainAreaHeight/2 - blockSize.height/2
            newBlock.position = CGPoint(x: 0, y: startY)
            mainAreaNode.addChild(newBlock)
            blocks.insert(newBlock, at: 0)
            blockInfos.insert(blockInfo, at: 0)
            
            updateBlockPositions()
        } else {
            GameLogger.shared.blockMovement("Failed to create block metadata")
        }
    }
    
    /// Creates a new block based on current level configuration
    private func createBlock() -> SKNode {
        guard let currentLevel = gameManager.currentLevel else {
            GameLogger.shared.blockMovement("No current level, creating default block")
            return createDefaultBlock()
        }
        
        let blockNode = SKNode()
        blockNode.zPosition = 2
        
        // Select block style
        guard let randomStyle = currentLevel.allowedStyles.randomElement(),
              let config = currentLevel.blocks[randomStyle] else {
            GameLogger.shared.blockMovement("Failed to select block style, creating default block")
            return createDefaultBlock()
        }
        
        // Generate note
        guard let randomNoteString = config.notes.randomElement(),
              let note = MusicalNote.parseSpanishFormat(randomNoteString),
              let blockStyle = getBlockStyle(for: randomStyle) else {
            GameLogger.shared.blockMovement("Failed to generate note, creating default block")
            return createDefaultBlock()
        }
        
        // VERIFICAR: Imprimir configuración para debug
            GameLogger.shared.blockMovement("""
                Creando bloque:
                - Estilo: \(randomStyle)
                - Nota: \(randomNoteString)
                - requiredHits: \(config.requiredHits)
                - requiredTime: \(config.requiredTime)
                """)
        
        // Create block container and content
        let container = createBlockContainer(with: blockStyle)
        blockNode.addChild(container)
        
        let contentNode = BlockContentGenerator.generateBlockContent(
            with: blockStyle,
            blockSize: blockSize,
            desiredNote: note,
            baseNoteX: 5,
            baseNoteY: 0,
            leftMargin: 30,
            rightMargin: 30
        )
        contentNode.name = "content"
        contentNode.position = .zero
        contentNode.zPosition = 3
        blockNode.addChild(contentNode)
        
        // Store block metadata
        let userData = NSMutableDictionary()
        userData.setValue(note.fullName, forKey: "noteName")
        userData.setValue(randomStyle, forKey: "blockStyle")
        userData.setValue(config.requiredHits, forKey: "requiredHits")
        userData.setValue(config.requiredTime, forKey: "requiredTime")
        blockNode.userData = userData
        
        // Add hit counter for multi-hit blocks
        if config.requiredHits > 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.updateHitCounter(on: blockNode, currentHits: 0, requiredHits: config.requiredHits)
            }
        }
        
        GameLogger.shared.blockMovement("Block created: Note \(note.fullName), Style: \(randomStyle)")
        return blockNode
    }
    
    /// Creates a default block when block creation fails
    private func createDefaultBlock() -> SKNode {
        let blockNode = SKNode()
        let style = BlockStyle.defaultBlock
        let container = createBlockContainer(with: style)
        blockNode.addChild(container)
        return blockNode
    }
    
    /// Creates block metadata for tracking
    private func createBlockInfo(for block: SKNode) -> BlockInfo? {
        guard let userData = block.userData,
              let noteData = userData.value(forKey: "noteName") as? String,
              let styleData = userData.value(forKey: "blockStyle") as? String,
              let config = gameManager.getBlockConfig(for: styleData),
              let requiredHits = userData.value(forKey: "requiredHits") as? Int,
              let requiredTime = userData.value(forKey: "requiredTime") as? TimeInterval else {
            
            // VERIFICAR: Imprimir info detallada para debug
            GameLogger.shared.blockMovement("""
                ❌ Failed to create BlockInfo:
                - userData exists: \(block.userData != nil)
                - noteData: \(block.userData?.value(forKey: "noteName") as? String ?? "nil")
                - styleData: \(block.userData?.value(forKey: "blockStyle") as? String ?? "nil")
                - requiredHits: \(block.userData?.value(forKey: "requiredHits") ?? "nil")
                - requiredTime: \(block.userData?.value(forKey: "requiredTime") ?? "nil")
                """)
            
            return nil
        }
        
        let info = BlockInfo(
            node: block,
            note: noteData,
            style: styleData,
            config: config,
            requiredHits: requiredHits,
            requiredTime: requiredTime
        )
        
        GameLogger.shared.blockMovement("""
            ✅ BlockInfo Created:
            - Note: \(noteData)
            - Style: \(styleData)
            - Required Hits: \(requiredHits)
            - Required Time: \(requiredTime)
            """)
        
        return info
    }
    
    /// Updates block positions in the game area
    private func updateBlockPositions() {
        GameLogger.shared.blockMovement("Updating positions for \(blocks.count) blocks")
        
        let moveDistance = blockSize.height + blockSpacing
        let moveDuration = 0.5
        
        // Update each block's position
        for (index, block) in blocks.enumerated() {
            let targetY = (mainAreaHeight/2) - (blockSize.height/2) - (moveDistance * CGFloat(index))
            
            let moveToPosition = SKAction.moveTo(y: targetY, duration: moveDuration)
            moveToPosition.timingMode = .easeInEaseOut
            
            block.removeAllActions()
            block.run(moveToPosition)
        }
    }
    
    // MARK: - Block Processing Methods
    
    /// Checks if any block has reached the bottom limit
    /// - Returns: True if any block is below the limit, false otherwise
    func hasBlocksBelowLimit() -> Bool {
        let bottomLimit = -mainAreaHeight/2
        
        return blocks.contains { block in
            let blockBottom = block.position.y - blockSize.height/2
            let hasReachedLimit = blockBottom <= bottomLimit
            
            if hasReachedLimit {
                GameLogger.shared.blockMovement("""
                    Block reached danger zone:
                    - Block Bottom: \(blockBottom)
                    - Bottom Limit: \(bottomLimit)
                    """)
            }
            
            return hasReachedLimit
        }
    }
    
    /// Clears all blocks from the game area
    func clearBlocks() {
        GameLogger.shared.blockMovement("Clearing all blocks")
        
        stopBlockGeneration()
        
        // Remove all block nodes from parent
        for block in blocks {
            block.removeFromParent()
        }
        
        // Clear block collections
        blocks.removeAll()
        blockInfos.removeAll()
        
        GameLogger.shared.blockMovement("Blocks cleared")
    }
    
    /// Retrieves the current active block
    /// - Returns: The current BlockInfo, or nil if no block exists
    func getCurrentBlock() -> BlockInfo? {
        guard let currentBlock = blockInfos.last else {
            GameLogger.shared.blockMovement("No current block")
            return nil
        }
        
        GameLogger.shared.blockMovement("""
            Current Block:
            - Note: \(currentBlock.note)
            - Style: \(currentBlock.style)
            """)
        
        return currentBlock
    }
    
    /// Removes the last block with a completion handler
    /// - Parameter completion: Closure to be called after block removal
    func removeLastBlockWithCompletion(completion: @escaping () -> Void) {
        GameLogger.shared.blockMovement("Removing last block. Current block count: \(blocks.count)")
        
        // Ensure thread-safety with a local flag
        var completionCalled = false
        
        // Wrapper to prevent multiple completion calls
        let safeCompletion = {
            if !completionCalled {
                completionCalled = true
                completion()
            }
        }
        
        // Validate block existence
        guard let lastBlock = blocks.last, !blockInfos.isEmpty else {
            GameLogger.shared.blockMovement("No block to remove")
            safeCompletion()
            return
        }
        
        let nodeID = ObjectIdentifier(lastBlock).hashValue
        GameLogger.shared.blockMovement("Removing block ID: \(nodeID)")
        
        // Safety timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self, weak lastBlock] in
            guard let self = self, let block = lastBlock else { return }
            
            if block.parent != nil {
                GameLogger.shared.blockMovement("Timeout: Force removing block")
                block.removeAllActions()
                block.removeFromParent()
                
                // Ensure block is removed from collections
                if self.blocks.last == block {
                    self.blocks.removeLast()
                }
                if !self.blockInfos.isEmpty {
                    self.blockInfos.removeLast()
                }
                
                self.updateBlockPositions()
                safeCompletion()
            }
        }
        
        // Block removal animation
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.3)
        let group = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([group, remove])
        
        lastBlock.run(sequence) { [weak self, weak lastBlock] in
            guard let self = self, let block = lastBlock else {
                safeCompletion()
                return
            }
            
            GameLogger.shared.blockMovement("Block removal completed for ID: \(nodeID)")
            
            // Remove from collections
            if self.blocks.last == block {
                self.blocks.removeLast()
            }
            if !self.blockInfos.isEmpty {
                self.blockInfos.removeLast()
            }
            
            self.updateBlockPositions()
            safeCompletion()
        }
    }
    
    /// Updates the current block's progress
    /// - Parameter hitTime: Timestamp of the hit
    /// - Returns: True if block is completed, false otherwise
    func updateCurrentBlockProgress(hitTime: Date) -> Bool {
        GameLogger.shared.blockMovement("Updating block progress at \(hitTime)")
        
        // Prevenir procesamiento si ya está procesando o es demasiado pronto después del último golpe
        guard !isProcessingBlock,
              lastHitTime == nil || hitTime.timeIntervalSince(lastHitTime!) >= 0.5 else {
            GameLogger.shared.blockMovement("Block processing skipped")
            return false
        }
        
        // Marcar como procesando y registrar tiempo de golpe
        isProcessingBlock = true
        lastHitTime = hitTime
        setupProcessingTimeout()
        
        // Validar bloque actual
        guard let index = blockInfos.indices.last,
              index < blockInfos.count else {
            GameLogger.shared.blockMovement("No block to process or index out of range")
            isProcessingBlock = false
            return false
        }
        
        var currentInfo = blockInfos[index]
        
        // IMPORTANTE: Verificar que la nota en blockInfo coincide con la del userData
        if let userData = currentInfo.node.userData,
           let currentNodeNote = userData.value(forKey: "noteName") as? String,
           currentNodeNote != currentInfo.note {
            // Hay una discrepancia, actualizar el blockInfo con la nota actualizada
            GameLogger.shared.blockMovement("⚠️ Corrigiendo discrepancia en nota: BlockInfo=\(currentInfo.note), Node=\(currentNodeNote)")
            currentInfo.note = currentNodeNote
        }
        
        // VERIFICAR: Imprimir info para debug
        GameLogger.shared.blockMovement("""
            Procesando golpe:
            - Bloque: \(currentInfo.style)
            - Nota: \(currentInfo.note)
            - Golpes actuales: \(currentInfo.currentHits)
            - Golpes requeridos: \(currentInfo.requiredHits)
            """)
        
        currentInfo.currentHits += 1
        
        GameLogger.shared.blockMovement("""
            Hit registered:
            - Note: \(currentInfo.note)
            - Hits: \(currentInfo.currentHits)/\(currentInfo.requiredHits)
            """)
        
        // Update block appearance for multi-hit blocks
        if currentInfo.requiredHits > 1 && currentInfo.currentHits < currentInfo.requiredHits {
            // Actualizar apariencia visual del bloque
            updateBlockAppearanceForHit(
                node: currentInfo.node,
                style: currentInfo.style,
                currentHits: currentInfo.currentHits,
                requiredHits: currentInfo.requiredHits
            )
            
            // Si es un bloque de hielo o hielo duro, cambiar la nota
            if currentInfo.style == "iceBlock" || currentInfo.style == "hardiceBlock" {
                // Guardar el blockInfo actualizado antes de cambiar la nota
                blockInfos[index] = currentInfo
                
                // Cambiar la nota (esta función se ha modificado para actualizar también blockInfos)
                changeBlockNote(node: currentInfo.node, config: currentInfo.config)
                
                // Recargar el blockInfo después del cambio de nota
                currentInfo = blockInfos[index]
            }
        } else {
            // Guardar el blockInfo actualizado (para casos que no sean bloques de hielo)
            blockInfos[index] = currentInfo
        }
        
        // Check if block is completed
        let isCompleted = currentInfo.currentHits >= currentInfo.requiredHits
        
        if isCompleted {
            GameLogger.shared.blockMovement("Block completed, removing")
            
            removeLastBlockWithCompletion { [weak self] in
                self?.isProcessingBlock = false
                self?.processingStartTime = nil
            }
        } else {
            isProcessingBlock = false
        }
        
        return isCompleted
    }



    // Nueva función a añadir en la clase BlocksManager
    private func changeBlockNote(node: SKNode, config: Block) {
        // Solo proceder si hay notas disponibles en la configuración
        guard !config.notes.isEmpty else { return }
        
        // Obtener la nota actual
        guard let userData = node.userData,
              let currentNoteStr = userData.value(forKey: "noteName") as? String else {
            return
        }
        
        // Seleccionar una nueva nota aleatoria diferente de la actual
        var availableNotes = config.notes
        if let currentIndex = availableNotes.firstIndex(where: { MusicalNote.areNotesEquivalent($0, currentNoteStr) }) {
            availableNotes.remove(at: currentIndex)
        }
        
        // Si no quedan más notas, usar la lista completa
        if availableNotes.isEmpty {
            availableNotes = config.notes
        }
        
        // Seleccionar una nota aleatoria
        guard let randomNoteString = availableNotes.randomElement(),
              let newNote = MusicalNote.parseSpanishFormat(randomNoteString) else {
            return
        }
        
        // Actualizar el bloque con la nueva nota
        IceBlockEffects.updateBlockNote(
            block: node,
            newNote: newNote,
            blockSize: blockSize
        )
        
        GameLogger.shared.blockMovement("Nota del bloque cambiada de \(currentNoteStr) a \(newNote.fullName)")
        
        // IMPORTANTE: También actualizar la nota en blockInfos
        // Encontrar el índice del bloque en blocks
        if let blockIndex = blocks.firstIndex(where: { $0 === node }),
           blockIndex < blockInfos.count {
            var blockInfo = blockInfos[blockIndex]
            
            // Aquí está la parte crítica: actualizar la nota en el blockInfo
            blockInfo.note = newNote.fullName
            blockInfos[blockIndex] = blockInfo
            
            GameLogger.shared.blockMovement("✅ BlockInfo actualizado con nueva nota: \(newNote.fullName)")
        } else {
            GameLogger.shared.blockMovement("❌ No se pudo encontrar el BlockInfo correspondiente para actualizar la nota")
        }
    }
    
    /// Resets the current block's progress
    func resetCurrentBlockProgress() {
        GameLogger.shared.blockMovement("Resetting current block progress")
        
        // Reset processing state
        isProcessingBlock = false
        processingStartTime = nil
        
        // Validate current block
        guard let index = blockInfos.indices.last else {
            GameLogger.shared.blockMovement("No block to reset")
            return
        }
        
        // Reset block's hit count
        var currentInfo = blockInfos[index]
        currentInfo.currentHits = 0
        blockInfos[index] = currentInfo
        
        GameLogger.shared.blockMovement("""
            Block reset:
            - Note: \(currentInfo.note)
            - Hits reset to 0
            """)
    }
    
    /// Sets up a timeout for block processing to prevent stuck states
    private func setupProcessingTimeout() {
        processingStartTime = Date()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.isProcessingBlock else { return }
            
            // Check if processing has taken too long
            if let startTime = self.processingStartTime,
               Date().timeIntervalSince(startTime) >= 2.0 {
                GameLogger.shared.blockMovement("Processing timeout detected - Resetting state")
                self.forceResetProcessingState()
            }
        }
    }
    
    /// Forces a reset of the block processing state
    func forceResetProcessingState() {
        GameLogger.shared.blockMovement("Forcibly resetting block processing state")
        
        isProcessingBlock = false
        processingStartTime = nil
    }
    
    /// Updates the block appearance when hit
    private func updateBlockAppearanceForHit(
        node: SKNode,
        style: String,
        currentHits: Int,
        requiredHits: Int
    ) {
        // Handle different block styles with special visual effects
        switch style {
        case "iceBlock":
            IceBlockEffects.updateIceBlockAppearance(
                block: node,
                currentHits: currentHits,
                requiredHits: requiredHits,
                blockSize: blockSize
            )
        case "hardiceBlock":
            IceBlockEffects.updateHardIceBlockAppearance(
                block: node,
                currentHits: currentHits,
                requiredHits: requiredHits,
                blockSize: blockSize
            )
        default:
            // Default case for blocks without special effects
            GameLogger.shared.blockMovement("No special effects for block style: \(style)")
            break
        }
    }
    
    /// Updates the hit counter for blocks requiring multiple hits
    private func updateHitCounter(on block: SKNode, currentHits: Int, requiredHits: Int) {
        // Remove existing counter
        block.childNode(withName: "hitCounter")?.removeFromParent()
        
        // Only add counter for multi-hit blocks
        guard requiredHits > 1 else { return }
        
        let counterContainer = SKNode()
        counterContainer.name = "hitCounter"
        counterContainer.zPosition = 10
        
        // Position in top-right corner
        counterContainer.position = CGPoint(
            x: blockSize.width/2 - 15,
            y: blockSize.height/2 - 15
        )
        
        // Configure counter style and label
        let background = SKShapeNode(circleOfRadius: 12)
        background.fillColor = .white
        background.strokeColor = .lightGray
        background.lineWidth = 1.5
        counterContainer.addChild(background)
        
        let remainingHits = requiredHits - currentHits
        
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = "\(remainingHits)"
        label.fontSize = 14
        label.fontColor = .darkGray
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        counterContainer.addChild(label)
        
        // VERIFICAR: Imprimir info para debug
        GameLogger.shared.blockMovement("Actualizado contador de hits: \(remainingHits)/\(requiredHits)")
        
        // Add counter to block with animation
        block.addChild(counterContainer)
        counterContainer.setScale(0)
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.2)
        scaleAction.timingMode = .easeOut
        counterContainer.run(scaleAction)
    }
    
    /// Retrieves the block style for a given style name
    private func getBlockStyle(for styleName: String) -> BlockStyle? {
        switch styleName {
        case "defaultBlock": return .defaultBlock
        case "iceBlock": return .iceBlock
        case "hardiceBlock": return .hardiceBlock
        case "ghostBlock": return .ghostBlock
        case "changingBlock": return .changingBlock
        default:
            GameLogger.shared.blockMovement("Unrecognized block style: \(styleName)")
            return nil
        }
    }
    
    /// Creates a block container with the specified style
    private func createBlockContainer(with style: BlockStyle) -> SKNode {
        let container = SKNode()
        container.name = "container"
        container.zPosition = 0
        
        // Add shadow if style defines it
        if let shadowColor = style.shadowColor,
           let shadowOffset = style.shadowOffset,
           let shadowBlur = style.shadowBlur {
            let shadowNode = createShadowNode(
                color: shadowColor,
                offset: shadowOffset,
                blur: shadowBlur,
                cornerRadius: style.cornerRadius
            )
            shadowNode.name = "shadow"
            container.addChild(shadowNode)
        }
        
        // Add background
        let background = createBackground(with: style)
        background.name = "background"
        container.addChild(background)
        
        return container
    }
    
    /// Creates a shadow node for a block
    private func createShadowNode(
        color: SKColor,
        offset: CGSize,
        blur: CGFloat,
        cornerRadius: CGFloat
    ) -> SKNode {
        let shadowNode = SKEffectNode()
        shadowNode.shouldRasterize = true
        shadowNode.filter = CIFilter(
            name: "CIGaussianBlur",
            parameters: ["inputRadius": blur]
        )
        shadowNode.zPosition = 1
        
        let shadowShape = SKShapeNode(
            rectOf: blockSize,
            cornerRadius: cornerRadius
        )
        shadowShape.fillColor = color
        shadowShape.strokeColor = .clear
        shadowShape.alpha = 0.5
        
        shadowNode.addChild(shadowShape)
        shadowNode.position = CGPoint(x: offset.width, y: offset.height)
        
        return shadowNode
    }
    
    /// Creates a background node for a block
    private func createBackground(with style: BlockStyle) -> SKNode {
        let background = SKShapeNode(
            rectOf: blockSize,
            cornerRadius: style.cornerRadius
        )
        background.fillColor = style.backgroundColor
        background.strokeColor = style.borderColor
        background.lineWidth = style.borderWidth
        background.zPosition = 2
        
        // Apply texture if defined
        if let texture = style.fillTexture {
            background.fillTexture = texture
            background.alpha = style.textureOpacity
        }
        
        return background
    }
    
    // MARK: - Public Accessors
    
    /// Current number of blocks
    var blockCount: Int { blocks.count }
    
    /// Current active blocks
    var currentBlocks: [SKNode] { blocks }
    
    /// Retrieves the current note from the first block
    func getCurrentNote() -> String? {
        let note = blocks.first?.userData?.value(forKey: "noteName") as? String
        GameLogger.shared.blockMovement("Current note: \(note ?? "none")")
        return note
    }
}
