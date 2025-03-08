//
//  BlocksManager.swift
//  MusicBlocks
//
//  Created by Jose R. García on 7/3/25.
//

import SpriteKit

class BlocksManager {
    
    // MARK: - Properties
    private var blockInfos: [BlockInfo] = []
    private var blocks: [SKNode] = []
    private let blockSize: CGSize
    private let blockSpacing: CGFloat
    private weak var mainAreaNode: SKNode?
    private var mainAreaHeight: CGFloat = 0
    private let gameManager = GameManager.shared
    
    // Nuevas propiedades para la generación de bloques
    private var spawnAction: SKAction?
    private var isGeneratingBlocks: Bool = false
    
    // MARK: - Constants
    private struct Constants {
        static let spawnInterval: TimeInterval = 2.5
        static let initialDelay: TimeInterval = 1.0
        static let bottomLimitRatio: CGFloat = 0.15
    }
    
    // MARK: - Initialization
    init(blockSize: CGSize = CGSize(width: 280, height: 120),
         blockSpacing: CGFloat = 1.0,
         mainAreaNode: SKNode?,
         mainAreaHeight: CGFloat) {
        self.blockSize = blockSize
        self.blockSpacing = blockSpacing
        self.mainAreaNode = mainAreaNode
        self.mainAreaHeight = mainAreaHeight
    }
    
    // MARK: - Block Generation Control
    func startBlockGeneration() {
        guard !isGeneratingBlocks else { return }
        isGeneratingBlocks = true
        
        spawnAction = SKAction.sequence([
            SKAction.wait(forDuration: Constants.initialDelay),
            SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.run { [weak self] in
                        self?.spawnBlock()
                    },
                    SKAction.wait(forDuration: Constants.spawnInterval)
                ])
            )
        ])
        
        mainAreaNode?.run(spawnAction!, withKey: "spawnSequence")
        print("✅ Generación de bloques iniciada")
    }
    
    func stopBlockGeneration() {
        if isGeneratingBlocks {
            isGeneratingBlocks = false
            mainAreaNode?.removeAction(forKey: "spawnSequence")
            print("⏹️ Generación de bloques detenida")
        }
    }
    
    // MARK: - Block Generation
    private func generateNote(for blockConfig: Block) -> MusicalNote? {
        guard let randomNoteString = blockConfig.notes.randomElement() else {
            print("Error: No hay notas disponibles en la configuración del bloque")
            return nil
        }
        
        print("Intentando parsear nota: \(randomNoteString)")
        if let note = MusicalNote.parseSpanishFormat(randomNoteString) {
            print("✅ Nota generada correctamente: \(note.fullName)")
            return note
        } else {
            print("❌ Error al parsear la nota: \(randomNoteString)")
            return nil
        }
    }
    
    private func createBlock() -> SKNode {
        guard let currentLevel = gameManager.currentLevel else {
            print("Error: No hay nivel actual")
            return createDefaultBlock()
        }
        
        let blockNode = SKNode()
        blockNode.zPosition = 2
        
        let allowedStyles = currentLevel.allowedStyles
        print("Estilos permitidos: \(allowedStyles)")
        
        guard let randomStyle = allowedStyles.randomElement() else {
            print("Error: No hay estilos permitidos")
            return createDefaultBlock()
        }
        
        guard let config = currentLevel.blocks[randomStyle] else {
            print("Error: No se encontró configuración para el bloque \(randomStyle)")
            return createDefaultBlock()
        }
        
        guard let randomNoteString = config.notes.randomElement(),
              let note = MusicalNote.parseSpanishFormat(randomNoteString),
              let blockStyle = getBlockStyle(for: randomStyle) else {
            return createDefaultBlock()
        }
        
        // Crear contenedor y contenido visual
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
        contentNode.position = .zero
        contentNode.zPosition = 3
        blockNode.addChild(contentNode)
        
        // Guardar metadata del bloque
        let userData = NSMutableDictionary()
        userData.setValue(note.fullName, forKey: "noteName")
        userData.setValue(randomStyle, forKey: "blockStyle")
        userData.setValue(config.requiredHits, forKey: "requiredHits")
        userData.setValue(config.requiredTime, forKey: "requiredTime")
        blockNode.userData = userData
        
        return blockNode
    }
    
    // MARK: - Block Creation Methods
    func spawnBlock() {
        guard let mainAreaNode = mainAreaNode,
              isGeneratingBlocks else {
            print("❌ No se pueden generar bloques: generación detenida o mainAreaNode es nil")
            return
        }
        
        print("Generando nuevo bloque. Bloques actuales: \(blocks.count)")
        
        // Verificar si el último bloque está muy cerca del límite superior
        if let lastBlock = blocks.first {
            let topLimit = mainAreaHeight/2 - blockSize.height/2
            if abs(lastBlock.position.y - topLimit) < blockSize.height {
                print("⏸️ Esperando a que los bloques desciendan")
                return
            }
        }
        
        let newBlock = createBlock()
        
        if let blockInfo = createBlockInfo(for: newBlock) {
            // Calcular posición inicial
            let startY = mainAreaHeight/2 - blockSize.height/2
            newBlock.position = CGPoint(x: 0, y: startY)
            
            // Añadir al área principal
            mainAreaNode.addChild(newBlock)
            
            // Guardar tanto el nodo como la información
            blocks.insert(newBlock, at: 0)
            blockInfos.insert(blockInfo, at: 0)
            
            print("Bloque añadido en posición Y: \(startY)")
            updateBlockPositions()
        }
    }
    
    private func createBlockInfo(for block: SKNode) -> BlockInfo? {
        guard let userData = block.userData,
              let noteData = userData.value(forKey: "noteName") as? String,
              let styleData = userData.value(forKey: "blockStyle") as? String,
              let config = gameManager.getBlockConfig(for: styleData),
              let requiredHits = userData.value(forKey: "requiredHits") as? Int,
              let requiredTime = userData.value(forKey: "requiredTime") as? TimeInterval else {
            print("❌ Error: Bloque creado sin datos válidos")
            return nil
        }
        
        return BlockInfo(
            node: block,
            note: noteData,
            style: styleData,
            config: config,
            requiredHits: requiredHits,
            requiredTime: requiredTime
        )
    }
    
    // MARK: - Block Visual Components
    private func createBlockContainer(with style: BlockStyle) -> SKNode {
        let container = SKNode()
        container.zPosition = 0
        
        if let shadowColor = style.shadowColor,
           let shadowOffset = style.shadowOffset,
           let shadowBlur = style.shadowBlur {
            let shadowNode = createShadowNode(
                color: shadowColor,
                offset: shadowOffset,
                blur: shadowBlur,
                cornerRadius: style.cornerRadius
            )
            container.addChild(shadowNode)
        }
        
        let background = createBackground(with: style)
        container.addChild(background)
        
        return container
    }
    
    private func createShadowNode(color: SKColor, offset: CGSize, blur: CGFloat, cornerRadius: CGFloat) -> SKNode {
        let shadowNode = SKEffectNode()
        shadowNode.shouldRasterize = true
        shadowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": blur])
        shadowNode.zPosition = 1
        
        let shadowShape = SKShapeNode(rectOf: blockSize, cornerRadius: cornerRadius)
        shadowShape.fillColor = color
        shadowShape.strokeColor = .clear
        shadowShape.alpha = 0.5
        
        shadowNode.addChild(shadowShape)
        shadowNode.position = CGPoint(x: offset.width, y: offset.height)
        
        return shadowNode
    }
    
    private func createBackground(with style: BlockStyle) -> SKNode {
        let background = SKShapeNode(rectOf: blockSize, cornerRadius: style.cornerRadius)
        background.fillColor = style.backgroundColor
        background.strokeColor = style.borderColor
        background.lineWidth = style.borderWidth
        background.zPosition = 2
        
        if let texture = style.fillTexture {
            background.fillTexture = texture
            background.alpha = style.textureOpacity
        }
        
        return background
    }
    
    
    // MARK: - Block Position Management
    private func updateBlockPositions() {
        let moveDistance = blockSize.height + blockSpacing
        let moveDuration = 0.5
        let fallingSpeed = gameManager.currentLevel?.fallingSpeed.initial ?? 8.0
        
        for (index, block) in blocks.enumerated() {
            let targetY = (mainAreaHeight/2) - (blockSize.height/2) - (moveDistance * CGFloat(index))
            
            // Crear una acción de movimiento continuo hacia abajo
            let moveDown = SKAction.moveBy(
                x: 0,
                y: -fallingSpeed,  // Velocidad de caída desde la configuración del nivel
                duration: 1.0
            )
            
            // Aplicar el movimiento inicial a la posición correcta
            let moveToPosition = SKAction.moveTo(y: targetY, duration: moveDuration)
            moveToPosition.timingMode = .easeInEaseOut
            
            // Secuencia: primero mover a la posición y luego comenzar la caída
            let sequence = SKAction.sequence([
                moveToPosition,
                SKAction.repeatForever(moveDown)
            ])
            
            block.run(sequence)
        }
    }
    
    // MARK: - Game State Checks
    func hasBlocksBelowLimit() -> Bool {
        let bottomLimit = -mainAreaHeight/2 + (blockSize.height * Constants.bottomLimitRatio)
        return blocks.contains { block in
            block.position.y <= bottomLimit
        }
    }
    
    // MARK: - Public Interface
    var currentBlocks: [SKNode] { blocks }
    
    var blockCount: Int { blocks.count }
    
    func clearBlocks() {
        stopBlockGeneration()
        for block in blocks {
            block.removeFromParent()
        }
        blocks.removeAll()
        blockInfos.removeAll()
    }
    
    func getCurrentBlock() -> BlockInfo? {
        return blockInfos.last
    }
    
    // MARK: - Block Style Management
    private func selectBlockStyleBasedOnWeights(from blocks: [String: Block]) -> BlockStyle {
        var weightedStyles: [(BlockStyle, Double)] = []
        
        for (styleName, blockConfig) in blocks {
            if let style = getBlockStyle(for: styleName) {
                weightedStyles.append((style, blockConfig.weight))
            }
        }
        
        guard !weightedStyles.isEmpty else { return .defaultBlock }
        
        let totalWeight = weightedStyles.reduce(0) { $0 + $1.1 }
        let randomValue = Double.random(in: 0..<totalWeight)
        
        var accumulatedWeight = 0.0
        for (style, weight) in weightedStyles {
            accumulatedWeight += weight
            if randomValue < accumulatedWeight {
                return style
            }
        }
        
        return weightedStyles[0].0
    }
    
    private func getBlockStyle(for styleName: String) -> BlockStyle? {
        print("Buscando estilo: \(styleName)")
        switch styleName {
        case "defaultBlock": return .defaultBlock
        case "iceBlock": return .iceBlock
        case "hardIceBlock": return .hardiceBlock
        case "ghostBlock": return .ghostBlock
        case "changingBlock": return .changingBlock
        default:
            print("⚠️ Estilo no reconocido: \(styleName)")
            return nil
        }
    }
    
    private func createDefaultBlock() -> SKNode {
        let blockNode = SKNode()
        let style = BlockStyle.defaultBlock
        let container = createBlockContainer(with: style)
        blockNode.addChild(container)
        return blockNode
    }
    
    // MARK: - Block State Management
    func getCurrentNote() -> String? {
        return blocks.first?.userData?.value(forKey: "noteName") as? String
    }
    
    func removeLastBlock() {
        guard let lastBlock = blocks.last,
              !blockInfos.isEmpty else { return }
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.3)
        let group = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([group, remove])
        
        lastBlock.run(sequence) { [weak self] in
            guard let self = self else { return }
            self.blocks.removeLast()
            self.blockInfos.removeLast()
            self.updateBlockPositions()
        }
    }
    
    // MARK: - Block Progress Management
    func updateCurrentBlockProgress(hitTime: Date) -> Bool {
        guard let index = blockInfos.indices.last else { return false }
        
        var currentInfo = blockInfos[index]
        
        if currentInfo.holdStartTime == nil {
            currentInfo.holdStartTime = hitTime
            blockInfos[index] = currentInfo
        }
        
        let holdDuration = Date().timeIntervalSince(currentInfo.holdStartTime ?? Date())
        
        if holdDuration >= currentInfo.requiredTime {
            currentInfo.currentHits += 1
            currentInfo.holdStartTime = nil
            blockInfos[index] = currentInfo
            
            if currentInfo.currentHits >= currentInfo.requiredHits {
                removeLastBlock()
                return true
            }
        }
        
        return false
    }
    
    func resetCurrentBlockProgress() {
        guard let index = blockInfos.indices.last else { return }
        var currentInfo = blockInfos[index]
        currentInfo.currentHits = 0
        currentInfo.holdStartTime = nil
        blockInfos[index] = currentInfo
    }
    
}
