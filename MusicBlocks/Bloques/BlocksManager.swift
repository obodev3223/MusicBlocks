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
    
    struct CurrentBlock {
        let note: String
        let config: Block
    }
    
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
        
        print("Generando nuevo bloque. Bloques actuales: \(blocks.count)")
        
        let moveDuration = 0.5
        let moveDistance = blockSize.height + blockSpacing
        
        // Mover los bloques existentes hacia abajo
        for block in blocks {
            let moveDown = SKAction.moveBy(x: 0, y: -moveDistance, duration: moveDuration)
            moveDown.timingMode = .easeInEaseOut
            block.run(moveDown)
        }
        
        // Crear y configurar el nuevo bloque
        let newBlock = createBlock()
        
        // Verificar que el bloque se creó correctamente
        if let noteData = newBlock.userData?.value(forKey: "noteName") as? String {
            print("Bloque creado correctamente con nota: \(noteData)")
        } else {
            print("¡Advertencia! Bloque creado sin nota")
        }
        
        // Posicionar el bloque
        let startY = (mainAreaHeight/2) - (blockSize.height/2) - blockSpacing
        newBlock.position = CGPoint(x: 0, y: startY + 10)
        
        // Añadir al área principal
        mainAreaNode.addChild(newBlock)
        
        // Animar entrada
        let moveToSlot = SKAction.moveTo(y: startY, duration: moveDuration)
        moveToSlot.timingMode = .easeInEaseOut
        newBlock.run(moveToSlot)
        
        blocks.insert(newBlock, at: 0)
        
        print("Bloque añadido. Total de bloques: \(blocks.count)")
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
            // Crear el contenido visual del bloque
            let contentNode = BlockContentGenerator.generateBlockContent(
                with: blockStyle,
                blockSize: blockSize,
                desiredNote: note,
                baseNoteX: 0,
                baseNoteY: 0
            )
            contentNode.zPosition = 3
            blockNode.addChild(contentNode)
            
            // Almacenar TODOS los datos necesarios en el userData
            blockNode.userData = NSMutableDictionary()
            blockNode.userData?.setValue(note.fullName, forKey: "noteName")
            blockNode.userData?.setValue(blockStyle.name, forKey: "blockStyle") // Añadir el estilo
            blockNode.userData?.setValue(blockConfig.requiredHits, forKey: "requiredHits")
            blockNode.userData?.setValue(blockConfig.requiredTime, forKey: "requiredTime")
            blockNode.userData?.setValue(blockConfig.basePoints, forKey: "basePoints")
            
            print("Bloque creado - Nota: \(note.fullName), Estilo: \(blockStyle.name)")
        }
        
        return blockNode
    }
    
    // Añadir este método auxiliar para ayudar en el debugging
    private func selectRandomNote(from notes: [String]) -> String {
        let selectedNote = notes.randomElement() ?? "DO4"
        print("Nota seleccionada: \(selectedNote) de opciones: \(notes)")
        return selectedNote
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
            let shadowNode = createShadowNode(
                color: shadowColor,
                offset: shadowOffset,
                blur: shadowBlur,
                cornerRadius: style.cornerRadius
            )
            container.addChild(shadowNode)
        }
        
        // Crear fondo del bloque
        let background = createBackground(with: style)
        container.addChild(background)
        
        return container
    }
    
    private func createShadowNode(color: SKColor, offset: CGSize, blur: CGFloat, cornerRadius: CGFloat) -> SKNode {
        let shadowNode = SKEffectNode()
        shadowNode.shouldRasterize = true
        shadowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": blur])
        shadowNode.zPosition = 1
        
        let shadowShape = SKShapeNode(rectOf: blockSize, cornerRadius: cornerRadius) // Usar el parámetro cornerRadius
        shadowShape.fillColor = color
        shadowShape.strokeColor = SKColor.clear // Especificar SKColor explícitamente
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
        
        // Añadir textura si está disponible
        if let texture = style.fillTexture {
            background.fillTexture = texture
            background.alpha = style.textureOpacity
        }
        
        return background
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
    
    func getCurrentBlock() -> CurrentBlock? {
        guard let bottomBlock = blocks.last,
              let noteData = bottomBlock.userData?.value(forKey: "noteName") as? String,
              let blockStyle = bottomBlock.userData?.value(forKey: "blockStyle") as? String,
              let blockConfig = GameManager.shared.getBlockConfig(for: blockStyle) else {
            print("Error obteniendo datos del bloque actual:")
            if let bottomBlock = blocks.last {
                print("- Nota: \(bottomBlock.userData?.value(forKey: "noteName") as? String ?? "nil")")
                print("- Estilo: \(bottomBlock.userData?.value(forKey: "blockStyle") as? String ?? "nil")")
            } else {
                print("No hay bloque actual")
            }
            return nil
        }
        
        return CurrentBlock(note: noteData, config: blockConfig)
    }
    
    // MARK: - Public Interface
    var currentBlocks: [SKNode] { blocks }
    var blockCount: Int { blocks.count }
    var hasReachedLimit: Bool { blocks.count >= 6 }
}
