//
//  BlocksManager.swift
//  MusicBlocks
//
//  Created by Jose R. García on 3/3/25.
//

import SpriteKit

class BlocksManager {
    
    // MARK: - Properties
    private let blockSize: CGSize
    private let blockSpacing: CGFloat
    private var blocks: [SKNode] = []
    private weak var mainAreaNode: SKNode?
    private var mainAreaHeight: CGFloat = 0
    private let gameManager = GameManager.shared
    
    // MARK: - Initialization
    init(blockSize: CGSize = CGSize(width: 270, height: 110),
         blockSpacing: CGFloat = 2.0,
         mainAreaNode: SKNode?,
         mainAreaHeight: CGFloat) {
        self.blockSize = blockSize
        self.blockSpacing = blockSpacing
        self.mainAreaNode = mainAreaNode
        self.mainAreaHeight = mainAreaHeight
    }
    
    // MARK: - Note Generation
    private func generateNote(for blockConfig: Block) -> MusicalNote? {
        // Seleccionar una nota aleatoria de las permitidas para este tipo de bloque
        guard let randomNoteString = blockConfig.notes.randomElement(),
              let note = MusicalNote.parse(randomNoteString) else {
            return nil
        }
        return note
    }
    
    // MARK: - Block Management Methods
    func spawnBlock() {
        guard let mainAreaNode = mainAreaNode else {
            print("Error: mainAreaNode is nil")
            return
        }
        
        if blocks.count >= 6 {
            print("Max blocks reached")
            return
        }
        
        print("Spawning new block. Current count: \(blocks.count)")
        
        let moveDuration = 0.5
        let moveDistance = blockSize.height + blockSpacing
        
        // Mover los bloques existentes hacia abajo
        for block in blocks {
            let moveDown = SKAction.moveBy(x: 0, y: -moveDistance, duration: moveDuration)
            moveDown.timingMode = .easeInEaseOut
            block.run(moveDown)
        }
        
        // Crear nuevo bloque
        let newBlock = createBlock()
        
        // Calcular la posición inicial
        let startY = (mainAreaHeight/2) - (blockSize.height/2) - blockSpacing
        newBlock.position = CGPoint(
            x: 0,
            y: startY + 10
        )
        
        print("Adding block at position: \(newBlock.position)")
        
        // Añadir al área principal
        mainAreaNode.addChild(newBlock)
        
        // Animar la entrada del bloque
        let moveToSlot = SKAction.moveTo(y: startY, duration: moveDuration)
        moveToSlot.timingMode = .easeInEaseOut
        newBlock.run(moveToSlot)
        
        blocks.insert(newBlock, at: 0)
        
        print("Block added successfully. New count: \(blocks.count)")
    }
    
    private func createBlock() -> SKNode {
        guard let currentLevel = gameManager.currentLevel else {
            return createDefaultBlock()
        }
        
        let blockNode = SKNode()
        blockNode.zPosition = 2
        
        // Obtener un estilo de bloque basado en los pesos definidos
        let blockStyle = selectBlockStyleBasedOnWeights(from: currentLevel.blocks)
        guard let blockConfig = currentLevel.blocks[blockStyle.name] else {
            return createDefaultBlock()
        }
        
        // Crear contenedor y aplicar estilo visual
        let container = createBlockContainer(with: blockStyle)
        blockNode.addChild(container)
        
        // Generar una nota aleatoria de las disponibles para este tipo de bloque
        let randomNote = selectRandomNote(from: blockConfig.notes)
        if let note = MusicalNote.parse(randomNote) {
            let contentNode = BlockContentGenerator.generateBlockContent(
                with: blockStyle,
                blockSize: blockSize,
                desiredNote: note,
                baseNoteX: 0,
                baseNoteY: 0
            )
            contentNode.zPosition = 3
            blockNode.addChild(contentNode)
            
            // Almacenar la nota y configuración en el nodo
            blockNode.userData = NSMutableDictionary()
            blockNode.userData?.setValue(note.fullName, forKey: "noteName")
            blockNode.userData?.setValue(blockConfig.requiredHits, forKey: "requiredHits")
            blockNode.userData?.setValue(blockConfig.requiredTime, forKey: "requiredTime")
        }
        
        return blockNode
    }
    
    private func selectBlockStyleBasedOnWeights(from blocks: [String: Block]) -> BlockStyle {
        var weightedStyles: [(BlockStyle, Double)] = []
        
        // Crear pares de estilo y peso
        for (styleName, blockConfig) in blocks {
            if let style = getBlockStyle(for: styleName) {
                weightedStyles.append((style, blockConfig.weight))
            }
        }
        
        // Si no hay estilos válidos, retornar el estilo por defecto
        guard !weightedStyles.isEmpty else {
            return .defaultBlock
        }
        
        // Calcular peso total
        let totalWeight = weightedStyles.reduce(0) { $0 + $1.1 }
        let randomValue = Double.random(in: 0..<totalWeight)
        
        // Seleccionar estilo basado en el peso
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
        switch styleName {
        case "defaultBlock": return .defaultBlock
        case "iceBlock": return .iceBlock
        case "hardIceBlock": return .hardiceBlock
        case "ghostBlock": return .ghostBlock
        case "changingBlock": return .changingBlock
        default: return nil
        }
    }
    
    private func selectRandomNote(from notes: [String]) -> String {
        return notes.randomElement() ?? "DO4"
    }
    
    private func createDefaultBlock() -> SKNode {
        let blockNode = SKNode()
        let style = BlockStyle.defaultBlock
        let container = createBlockContainer(with: style)
        blockNode.addChild(container)
        return blockNode
    }
    
    private func createBlockContainer(with style: BlockStyle) -> SKNode {
        let container = SKNode()
        container.zPosition = 0
        
        // Crear sombra si está definida
        if let shadowColor = style.shadowColor,
           let shadowOffset = style.shadowOffset,
           let shadowBlur = style.shadowBlur {
            let shadowNode = createShadowNode(color: shadowColor, offset: shadowOffset, blur: shadowBlur)
            container.addChild(shadowNode)
        }
        
        // Crear fondo del bloque
        let background = createBackground(with: style)
        container.addChild(background)
        
        return container
    }
    
    // MARK: - Public Methods
    
    func getCurrentNote() -> String? {
        return blocks.first?.userData?.value(forKey: "noteName") as? String
    }
    
    func clearBlocks() {
        for block in blocks {
            block.removeFromParent()
        }
        blocks.removeAll()
    }
    
    // MARK: - Public Interface
    var currentBlocks: [SKNode] { blocks }
    var blockCount: Int { blocks.count }
    var hasReachedLimit: Bool { blocks.count >= 6 }
}
