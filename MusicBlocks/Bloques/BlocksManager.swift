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
        
        // Crear y configurar el nuevo bloque
        let newBlock = createBlock()
        
        // Verificar que el bloque se creó correctamente
        if let noteData = newBlock.userData?.value(forKey: "noteName") as? String {
            print("✅ Bloque creado con nota: \(noteData)")
            print("✅ userData: \(String(describing: newBlock.userData))")
        } else {
            print("❌ Error: Bloque creado sin datos")
        }
        
        // Calcular posición inicial
        let startY = mainAreaHeight/2 - blockSize.height/2
        newBlock.position = CGPoint(x: 0, y: startY)
        
        // Añadir al área principal
        mainAreaNode.addChild(newBlock)
        blocks.insert(newBlock, at: 0)
        
        print("Bloque añadido en posición Y: \(startY)")
        updateBlockPositions()
    }
    
    private func createBlock() -> SKNode {
        guard let currentLevel = gameManager.currentLevel else {
            print("Error: No hay nivel actual")
            return createDefaultBlock()
        }
        
        let blockNode = SKNode()
        blockNode.zPosition = 2
        
        // Obtener un estilo permitido del nivel actual
        let allowedStyles = currentLevel.allowedStyles
        print("Estilos permitidos: \(allowedStyles)")
        
        guard let randomStyle = allowedStyles.randomElement(),
              let blockConfig = currentLevel.blocks[randomStyle] else {
            print("Error: No se encontró configuración para el bloque")
            return createDefaultBlock()
        }
        
        print("Creando bloque con estilo: \(randomStyle)")
        
        // Obtener el BlockStyle correspondiente
        guard let blockStyle = getBlockStyle(for: randomStyle) else {
            print("Error: Estilo de bloque no válido")
            return createDefaultBlock()
        }
        
        // Generar una nota aleatoria y validar
        guard let randomNoteString = blockConfig.notes.randomElement(),
              let note = MusicalNote.parse(randomNoteString) else {
            print("Error: No se pudo generar la nota")
            return createDefaultBlock()
        }
        
        print("Nota seleccionada: \(note.fullName)")
        
        // Crear el contenedor del bloque
        let container = createBlockContainer(with: blockStyle)
        blockNode.addChild(container)
        
        // Crear el contenido visual con posiciones ajustadas
        let contentNode = BlockContentGenerator.generateBlockContent(
            with: blockStyle,
            blockSize: blockSize,
            desiredNote: note,
            baseNoteX: blockSize.width/4,  // Centrar la nota horizontalmente
            baseNoteY: 0,
            leftMargin: 30,
            rightMargin: 30
        )
        contentNode.position = .zero  // El contenido se centra en el bloque
        contentNode.zPosition = 3
        blockNode.addChild(contentNode)
        
        // Guardar información del bloque
        let userData = NSMutableDictionary()
        userData.setValue(note.fullName, forKey: "noteName")
        userData.setValue(randomStyle, forKey: "blockStyle")
        userData.setValue(blockConfig.requiredHits, forKey: "requiredHits")
        userData.setValue(blockConfig.requiredTime, forKey: "requiredTime")
        blockNode.userData = userData
        
        print("Bloque creado exitosamente - Nota: \(note.fullName), Estilo: \(randomStyle)")
        
        return blockNode
    }
    
    private func updateBlockPositions() {
        let moveDistance = blockSize.height + blockSpacing
        let moveDuration = 0.5
        
        // Actualizar posición de todos los bloques
        for (index, block) in blocks.enumerated() {
            let targetY = (mainAreaHeight/2) - (blockSize.height/2) - (moveDistance * CGFloat(index))
            let moveAction = SKAction.moveTo(y: targetY, duration: moveDuration)
            moveAction.timingMode = .easeInEaseOut
            block.run(moveAction)
        }
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
        print("Buscando estilo: \(styleName)")  // Debug
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
        guard let bottomBlock = blocks.last else {
            print("No hay bloques en el área de juego")
            return nil
        }
        
        guard let userData = bottomBlock.userData,
              let noteData = userData.value(forKey: "noteName") as? String,
              let blockStyle = userData.value(forKey: "blockStyle") as? String else {
            print("Error: Datos del bloque incompletos")
            print("userData: \(String(describing: bottomBlock.userData))")
            return nil
        }
        
        guard let blockConfig = GameManager.shared.getBlockConfig(for: blockStyle) else {
            print("Error: No se encontró configuración para el estilo: \(blockStyle)")
            return nil
        }
        
        print("Bloque actual encontrado - Nota: \(noteData), Estilo: \(blockStyle)")
        return CurrentBlock(note: noteData, config: blockConfig)
    }
    
    // MARK: - Public Interface
    var currentBlocks: [SKNode] { blocks }
    var blockCount: Int { blocks.count }
    var hasReachedLimit: Bool { blocks.count >= 6 }
}
