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
    private var blocks: [BlockInfo] = []
    private weak var mainAreaNode: SKNode?
    private var mainAreaHeight: CGFloat = 0
    private let gameManager = GameManager.shared
    
    struct CurrentBlock {
        let note: String
        let config: Block
    }
    
    // Estructura para mantener la información del bloque
    struct BlockInfo {
        let node: SKNode
        let note: String
        let style: String
        let config: Block
        let requiredHits: Int
        let requiredTime: TimeInterval
        var currentHits: Int = 0
        var holdStartTime: Date?
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
        if let noteData = newBlock.userData?.value(forKey: "noteName") as? String,
                   let styleData = newBlock.userData?.value(forKey: "blockStyle") as? String,
                   let config = GameManager.shared.getBlockConfig(for: styleData),
                   let requiredHits = newBlock.userData?.value(forKey: "requiredHits") as? Int,
                   let requiredTime = newBlock.userData?.value(forKey: "requiredTime") as? TimeInterval {
                    
                    let blockInfo = BlockInfo(
                        node: newBlock,
                        note: noteData,
                        style: styleData,
                        config: config,
                        requiredHits: requiredHits,
                        requiredTime: requiredTime
                    )
                    
                    blocks.insert(blockInfo, at: 0)
                    print("Bloque añadido: \(noteData) - Total bloques: \(blocks.count)")
                }
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
        
        guard let randomStyle = allowedStyles.randomElement() else {
            print("Error: No hay estilos permitidos")
            return createDefaultBlock()
        }
        
        // Obtener la configuración del bloque
        let blockConfig = currentLevel.blocks[randomStyle]
        guard let config = blockConfig else {
            print("Error: No se encontró configuración para el bloque \(randomStyle)")
            print("Bloques disponibles en el nivel: \(currentLevel.blocks.keys)")
            return createDefaultBlock()
        }
        
        print("Creando bloque con estilo: \(randomStyle)")
        print("Notas disponibles para el bloque: \(config.notes)")
        
        // Generar una nota aleatoria
        guard let randomNoteString = config.notes.randomElement() else {
            print("Error: No hay notas disponibles en la configuración")
            return createDefaultBlock()
        }
        
        print("Nota seleccionada del bloque: \(randomNoteString)")
        
        // Intentar parsear la nota
        guard let note = MusicalNote.parseSpanishFormat(randomNoteString) else {
            print("Error: No se pudo parsear la nota: \(randomNoteString)")
            return createDefaultBlock()
        }
        
        print("Nota parseada correctamente: \(note.fullName)")
        
        // Obtener el BlockStyle correspondiente
        guard let blockStyle = getBlockStyle(for: randomStyle) else {
            print("Error: Estilo de bloque no válido")
            return createDefaultBlock()
        }
        
        // Crear el contenedor del bloque
        let container = createBlockContainer(with: blockStyle)
        blockNode.addChild(container)
        
        // Crear el contenido visual
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
        
        // Guardar información del bloque
        let userData = NSMutableDictionary()
        userData.setValue(note.fullName, forKey: "noteName")
        userData.setValue(randomStyle, forKey: "blockStyle")
        userData.setValue(config.requiredHits, forKey: "requiredHits")
        userData.setValue(config.requiredTime, forKey: "requiredTime")
        blockNode.userData = userData
        
        print("✅ Bloque creado exitosamente - Nota: \(note.fullName), Estilo: \(randomStyle)")
        
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
    
    /// Elimina el bloque más bajo (el último) cuando se acierta
        func removeLastBlock() {
            guard let lastBlock = blocks.last else {
                print("No hay bloques para eliminar")
                return
            }
            
            // Crear la animación de desaparición
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let scaleDown = SKAction.scale(to: 0.1, duration: 0.3)
            let group = SKAction.group([fadeOut, scaleDown])
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([group, remove])
            
            lastBlock.run(sequence) { [weak self] in
                guard let self = self else { return }
                self.blocks.removeLast()
                
                // Actualizar posiciones de los bloques restantes
                self.updateBlockPositions()
            }
        }
    
    // Obtener el bloque actual y su estado
    func getCurrentBlock() -> BlockInfo? {
        return blocks.last
    }
    
    // Actualizar el progreso de un hit en el bloque actual
        func updateCurrentBlockProgress(hitTime: Date) -> Bool {
            guard var currentBlock = blocks.last else { return false }
            
            if currentBlock.holdStartTime == nil {
                currentBlock.holdStartTime = hitTime
            }
            
            let holdDuration = Date().timeIntervalSince(currentBlock.holdStartTime ?? Date())
            
            if holdDuration >= currentBlock.requiredTime {
                currentBlock.currentHits += 1
                currentBlock.holdStartTime = nil
                
                if currentBlock.currentHits >= currentBlock.requiredHits {
                    // Bloque completado
                    removeLastBlock()
                    return true
                }
            }
            
            return false
        }
    // Resetear el progreso del bloque actual
        func resetCurrentBlockProgress() {
            guard var currentBlock = blocks.last else { return }
            currentBlock.currentHits = 0
            currentBlock.holdStartTime = nil
        }
    
    // MARK: - Public Interface
    var currentBlocks: [SKNode] { blocks }
    var blockCount: Int { blocks.count }
    var hasReachedLimit: Bool { blocks.count >= 6 }
}
