//
//  BlocksManager.swift
//  MusicBlocks
//
//  Created by Jose R. García on 3/3/25.
//

import SpriteKit

class BlocksManager {
    // MARK: - Types
    enum NoteDifficulty {
        case beginner    // Solo notas naturales en una octava
        case intermediate // Notas naturales y alteraciones simples
        case advanced    // Todas las notas y alteraciones
    }
    
    // MARK: - Properties
    private let blockSize: CGSize
    private let blockSpacing: CGFloat
    private var blocks: [SKNode] = []
    private var totalBlocksAppeared = 0
    private weak var mainAreaNode: SKNode?
    private var mainAreaHeight: CGFloat = 0
    private let tunerEngine: TunerEngine
    private var difficulty: NoteDifficulty = .intermediate
    private var usedNotes: Set<String> = []
    
    // MARK: - Initialization
    init(blockSize: CGSize = CGSize(width: 270, height: 110),
         blockSpacing: CGFloat = 2.0,
         mainAreaNode: SKNode?,
         mainAreaHeight: CGFloat) {
        self.blockSize = blockSize
        self.blockSpacing = blockSpacing
        self.mainAreaNode = mainAreaNode
        self.mainAreaHeight = mainAreaHeight
        self.tunerEngine = .shared
    }
    
    // MARK: - Note Generation
    private func generateNote() -> TunerEngine.Note? {
        // Obtener una nota que no se haya usado recientemente
        var attempts = 0
        let maxAttempts = 10
        
        while attempts < maxAttempts {
            if let note = tunerEngine.generateRandomNote() {
                // Si la nota no se ha usado recientemente
                if !usedNotes.contains(note.fullName) {
                    // Agregar la nota al conjunto de notas usadas
                    usedNotes.insert(note.fullName)
                    
                    // Mantener el tamaño del conjunto limitado
                    if usedNotes.count > 4 {
                        usedNotes.remove(usedNotes.first!)
                    }
                    
                    return note
                }
            }
            attempts += 1
        }
        
        // Si no podemos encontrar una nota nueva, usar cualquier nota aleatoria
        return tunerEngine.generateRandomNote()
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
        totalBlocksAppeared += 1
        
        print("Block added successfully. New count: \(blocks.count)")
    }
    
    private func createBlock() -> SKNode {
        let blockNode = SKNode()
        blockNode.zPosition = 2
        
        // Elegir un estilo aleatorio para variedad visual
        let blockStyles: [BlockStyle] = [
            .defaultBlock,
            .iceBlock,
            .hardiceBlock,
            .ghostBlock,
            .changingBlock
        ]
        let blockStyle = blockStyles.randomElement() ?? .defaultBlock
        
        // Crear el contenedor principal
        let container = SKNode()
        container.zPosition = 0
        
        // Crear el fondo del bloque con sombra
        if let shadowColor = blockStyle.shadowColor,
           let shadowOffset = blockStyle.shadowOffset,
           let shadowBlur = blockStyle.shadowBlur {
            let shadowNode = SKEffectNode()
            shadowNode.shouldRasterize = true
            shadowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": shadowBlur])
            shadowNode.zPosition = 1
            
            let shadowShape = SKShapeNode(rectOf: blockSize, cornerRadius: blockStyle.cornerRadius)
            shadowShape.fillColor = shadowColor
            shadowShape.strokeColor = .clear
            shadowShape.alpha = 0.5
            
            shadowNode.addChild(shadowShape)
            shadowNode.position = CGPoint(x: shadowOffset.width, y: shadowOffset.height)
            container.addChild(shadowNode)
        }
        
        // Crear el fondo del bloque
        let background = SKShapeNode(rectOf: blockSize, cornerRadius: blockStyle.cornerRadius)
        background.fillColor = blockStyle.backgroundColor
        background.strokeColor = blockStyle.borderColor
        background.lineWidth = blockStyle.borderWidth
        background.zPosition = 2
        
        // Añadir textura si está disponible
        if let texture = blockStyle.fillTexture {
            background.fillTexture = texture
            background.alpha = blockStyle.textureOpacity
        }
        
        container.addChild(background)
        blockNode.addChild(container)
        
        // Generar una nota usando nuestro propio generador
        if let randomNote = generateNote() {
            // Generar el contenido visual del bloque con la nota
            let contentNode = BlockContentGenerator.generateBlockContent(
                with: blockStyle,
                blockSize: blockSize,
                desiredNote: randomNote,
                baseNoteX: 0,
                baseNoteY: 0
            )
            contentNode.zPosition = 3
            blockNode.addChild(contentNode)
            
            // Almacenar la nota en los datos de usuario del nodo
            blockNode.userData = NSMutableDictionary()
            blockNode.userData?.setValue(randomNote.fullName, forKey: "noteName")
        }
        
        return blockNode
    }
    
    // MARK: - Public Methods
    func setDifficulty(_ difficulty: NoteDifficulty) {
        self.difficulty = difficulty
        usedNotes.removeAll()
    }
    
    func getCurrentNote() -> String? {
        return blocks.first?.userData?.value(forKey: "noteName") as? String
    }
    
    func clearBlocks() {
        for block in blocks {
            block.removeFromParent()
        }
        blocks.removeAll()
        totalBlocksAppeared = 0
    }
    
    // MARK: - Public Interface
    var currentBlocks: [SKNode] { blocks }
    var blockCount: Int { blocks.count }
    var hasReachedLimit: Bool { blocks.count >= 6 }
}
