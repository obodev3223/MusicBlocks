//
//  BlocksManager.swift
//  MusicBlocks
//
//  Creado por Jose R. García el 14/3/25.
//  Versión modificada: Se han añadido mensajes de debug para seguir el flujo de todas las funciones.
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
    
    // Para controlar la generación de bloques
        private var spawnAction: SKAction?
        private var isGeneratingBlocks: Bool = false
        
        // Ahora interpretamos estos como tiempos en SEGUNDOS:
        // spawnInterval = “tiempo entre bloques”
        // spawnIntervalDecrement = “segundos que restamos tras cada bloque”
        private var spawnInterval: TimeInterval
        private var spawnIntervalDecrement: TimeInterval
    
    // MARK: - Constants
        private struct Constants {
            static let initialDelay: TimeInterval = 1.0
            static let minSpawnInterval: TimeInterval = 1.5
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
            
            // Leemos la “velocidad” del nivel, pero la usamos como spawnInterval (segundos).
            if let fallingSpeed = GameManager.shared.currentLevel?.fallingSpeed {
                // Por ejemplo: initial=8.0 => 8s entre bloques, increment=2.0 => restar 2s cada bloque
                self.spawnInterval = fallingSpeed.initial
                self.spawnIntervalDecrement = fallingSpeed.increment
            } else {
                // Valores por defecto
                self.spawnInterval = 4.0
                self.spawnIntervalDecrement = 0.0
            }
            
            print("🔧 BlocksManager inicializado. blockSize: \(blockSize), " +
                  "mainAreaHeight: \(mainAreaHeight), " +
                  "spawnInterval inicial: \(spawnInterval) s, " +
                  "decremento: \(spawnIntervalDecrement) s")
        }
    
    // MARK: - Iniciando generación de bloques
    func startBlockGeneration() {
        print("▶️ startBlockGeneration llamado.")
        guard !isGeneratingBlocks else {
            print("ℹ️ La generación de bloques ya está en curso.")
            return
        }
        isGeneratingBlocks = true
        
        // Esperamos un delay inicial (opcional)
        let initialDelay = SKAction.wait(forDuration: 1.0) // Por ejemplo 1s
        
        // Cuando acabe el delay, llamamos a spawnLoop()
        let beginAction = SKAction.run { [weak self] in
            self?.spawnLoop()
        }
        
        let sequence = SKAction.sequence([initialDelay, beginAction])
        mainAreaNode?.run(sequence)
        
        print("✅ Generación de bloques iniciada - spawnInterval: \(spawnInterval) s")
    }

    /// Bucle “recursivo” que genera 1 bloque, actualiza el spawnInterval
    /// y programa la siguiente aparición.
    private func spawnLoop() {
        // 1) Verificar si seguimos generando
        guard isGeneratingBlocks else {
            print("🛑 Generación detenida, no se continúa el loop.")
            return
        }
        
        // 2) Generar el bloque
        spawnBlock()
        
        // 3) Ajustar spawnInterval (acelerar)
        let newInterval = max(spawnInterval - spawnIntervalDecrement, Constants.minSpawnInterval)
        spawnInterval = newInterval
        print("🚀 Nuevo spawnInterval = \(spawnInterval) s (restado \(spawnIntervalDecrement))")
        
        // 4) Programar la siguiente aparición usando el spawnInterval actual
        let wait = SKAction.wait(forDuration: spawnInterval)
        let nextCall = SKAction.run { [weak self] in
            self?.spawnLoop()
        }
        let sequence = SKAction.sequence([wait, nextCall])
        
        mainAreaNode?.run(sequence)
    }

    /// Detener la generación
    func stopBlockGeneration() {
        print("⏹️ stopBlockGeneration llamado.")
        guard isGeneratingBlocks else {
            print("ℹ️ La generación de bloques ya está detenida.")
            return
        }
        isGeneratingBlocks = false
        // También puedes remover todas las acciones del mainAreaNode si quieres
        mainAreaNode?.removeAllActions()
        print("✅ Generación de bloques detenida.")
    }
    
    // MARK: - Block Generation
    private func generateNote(for blockConfig: Block) -> MusicalNote? {
        guard let randomNoteString = blockConfig.notes.randomElement() else {
            print("❌ Error: No hay notas disponibles en la configuración del bloque")
            return nil
        }
        
        print("📢 Intentando parsear nota: \(randomNoteString)")
        if let note = MusicalNote.parseSpanishFormat(randomNoteString) {
            print("✅ Nota generada correctamente: \(note.fullName)")
            return note
        } else {
            print("❌ Error al parsear la nota: \(randomNoteString)")
            return nil
        }
    }
    
    private func createBlock() -> SKNode {
        print("➡️ Creando nuevo bloque...")
        guard let currentLevel = gameManager.currentLevel else {
            print("❌ Error: No hay nivel actual")
            return createDefaultBlock()
        }
        
        let blockNode = SKNode()
        blockNode.zPosition = 2
        
        let allowedStyles = currentLevel.allowedStyles
        print("📝 Estilos permitidos: \(allowedStyles)")
        
        guard let randomStyle = allowedStyles.randomElement() else {
            print("❌ Error: No hay estilos permitidos")
            return createDefaultBlock()
        }
        
        guard let config = currentLevel.blocks[randomStyle] else {
            print("❌ Error: No se encontró configuración para el bloque \(randomStyle)")
            return createDefaultBlock()
        }
        
        guard let randomNoteString = config.notes.randomElement(),
              let note = MusicalNote.parseSpanishFormat(randomNoteString),
              let blockStyle = getBlockStyle(for: randomStyle) else {
            print("❌ Error: Falló la generación del bloque, usando bloque por defecto.")
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
        
        print("✅ Bloque creado con nota: \(note.fullName) y estilo: \(randomStyle)")
        return blockNode
    }
    
    // MARK: - Block Creation Methods
    func spawnBlock() {
            print("➡️ spawnBlock llamado.")
            guard let mainAreaNode = mainAreaNode,
                  isGeneratingBlocks else {
                print("❌ No se pueden generar bloques: generación detenida o mainAreaNode es nil")
                return
            }
            
            // Verificar espacio
            if let firstBlock = blocks.first {
                let topLimit = mainAreaHeight/2 - blockSize.height/2
                let firstBlockTopEdge = firstBlock.position.y + blockSize.height/2
                
                if abs(firstBlockTopEdge - topLimit) < blockSpacing {
                    print("⏸️ Esperando espacio para nuevo bloque.")
                    return
                }
            }
            
            let newBlock = createBlock()
            
            if let blockInfo = createBlockInfo(for: newBlock) {
                let startY = mainAreaHeight/2 - blockSize.height/2
                newBlock.position = CGPoint(x: 0, y: startY)
                mainAreaNode.addChild(newBlock)
                blocks.insert(newBlock, at: 0)
                blockInfos.insert(blockInfo, at: 0)
                
                print("✅ Bloque añadido en posición Y: \(startY)")
                updateBlockPositions()
            } else {
                print("❌ Error al crear la metadata del bloque.")
            }
        }
    
    private func createBlockInfo(for block: SKNode) -> BlockInfo? {
//        print("📋 Creando BlockInfo para bloque.")
        guard let userData = block.userData,
              let noteData = userData.value(forKey: "noteName") as? String,
              let styleData = userData.value(forKey: "blockStyle") as? String,
              let config = gameManager.getBlockConfig(for: styleData),
              let requiredHits = userData.value(forKey: "requiredHits") as? Int,
              let requiredTime = userData.value(forKey: "requiredTime") as? TimeInterval else {
            print("❌ Error: Bloque creado sin datos válidos")
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
        print("✅ BlockInfo creado: nota \(noteData), estilo \(styleData), requiredHits: \(requiredHits), requiredTime: \(requiredTime)")
        return info
    }
    
    // MARK: - Block Visual Components
    private func createBlockContainer(with style: BlockStyle) -> SKNode {
//        print("🖼️ Creando contenedor para bloque con estilo: \(style)")
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
//            print("🖼️ Sombra añadida al contenedor.")
        }
        
        let background = createBackground(with: style)
        container.addChild(background)
//        print("🖼️ Fondo añadido al contenedor.")
        
        return container
    }
    
    private func createShadowNode(color: SKColor, offset: CGSize, blur: CGFloat, cornerRadius: CGFloat) -> SKNode {
//        print("🖌️ Creando shadowNode con color: \(color), offset: \(offset), blur: \(blur)")
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
//        print("🖌️ Creando background para bloque con estilo: \(style)")
        let background = SKShapeNode(rectOf: blockSize, cornerRadius: style.cornerRadius)
        background.fillColor = style.backgroundColor
        background.strokeColor = style.borderColor
        background.lineWidth = style.borderWidth
        background.zPosition = 2
        
        if let texture = style.fillTexture {
            background.fillTexture = texture
            background.alpha = style.textureOpacity
//            print("🖼️ Texture aplicada al background.")
        }
        
        return background
    }
    
    
    // MARK: - Block Position Management
    private func updateBlockPositions() {
        print("↕️ Actualizando posiciones de \(blocks.count) bloques.")
        let moveDistance = blockSize.height + blockSpacing
        let moveDuration = 0.5
        
        for (index, block) in blocks.enumerated() {
            // Calcular la posición final para cada bloque
            let targetY = (mainAreaHeight/2) - (blockSize.height/2) - (moveDistance * CGFloat(index))
            print("   Bloque \(index): moviéndose a Y = \(targetY)")
            // Mover el bloque a su posición con una animación suave
            let moveToPosition = SKAction.moveTo(y: targetY, duration: moveDuration)
            moveToPosition.timingMode = .easeInEaseOut
            
            // Detener cualquier acción previa
            block.removeAllActions()
            
            // Aplicar solo el movimiento de posicionamiento
            block.run(moveToPosition)
        }
    }
    
    // MARK: - Game State Checks
    func hasBlocksBelowLimit() -> Bool {
        let bottomLimit = -mainAreaHeight/2
        let result = blocks.contains { block in
            let blockBottom = block.position.y - blockSize.height/2
            let hasReachedLimit = blockBottom <= bottomLimit
            if hasReachedLimit {
                print("⚠️ Bloque ha alcanzado la zona de peligro. blockBottom: \(blockBottom), bottomLimit: \(bottomLimit)")
            }
            return hasReachedLimit
        }
        return result
    }
    
    // MARK: - Public Interface
    var currentBlocks: [SKNode] { blocks }
    
    var blockCount: Int { blocks.count }
    
    func clearBlocks() {
        print("🧹 Limpiando bloques...")
        stopBlockGeneration()
        for block in blocks {
            block.removeFromParent()
        }
        blocks.removeAll()
        blockInfos.removeAll()
        print("🧹 Bloques eliminados.")
    }
    
    func getCurrentBlock() -> BlockInfo? {
        GameLogger.shared.blockMovement("Consultando bloque actual...")
        
        if let current = blockInfos.last {
            GameLogger.shared.blockMovement("Bloque actual: nota \(current.note), estilo \(current.style)")
        } else {
            GameLogger.shared.blockMovement("No hay bloque actual.")
        }
        
        return blockInfos.last
    }
    
    // MARK: - Block Style Management
    private func selectBlockStyleBasedOnWeights(from blocks: [String: Block]) -> BlockStyle {
        print("🔀 Seleccionando estilo basado en pesos...")
        var weightedStyles: [(BlockStyle, Double)] = []
        
        for (styleName, blockConfig) in blocks {
            if let style = getBlockStyle(for: styleName) {
                weightedStyles.append((style, blockConfig.weight))
                print("   Estilo \(styleName) con peso \(blockConfig.weight) añadido.")
            }
        }
        
        guard !weightedStyles.isEmpty else {
            print("⚠️ No se encontraron estilos con peso. Se retorna defaultBlock.")
            return .defaultBlock
        }
        
        let totalWeight = weightedStyles.reduce(0) { $0 + $1.1 }
        let randomValue = Double.random(in: 0..<totalWeight)
        print("   Total de peso: \(totalWeight), valor aleatorio: \(randomValue)")
        
        var accumulatedWeight = 0.0
        for (style, weight) in weightedStyles {
            accumulatedWeight += weight
            if randomValue < accumulatedWeight {
                print("   Estilo seleccionado: \(style)")
                return style
            }
        }
        
        print("   Estilo seleccionado por defecto: \(weightedStyles[0].0)")
        return weightedStyles[0].0
    }
    
    private func getBlockStyle(for styleName: String) -> BlockStyle? {
        print("🔍 Buscando estilo: \(styleName)")
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
        print("❓ Creando bloque por defecto.")
        let blockNode = SKNode()
        let style = BlockStyle.defaultBlock
        let container = createBlockContainer(with: style)
        blockNode.addChild(container)
        return blockNode
    }
    
    // MARK: - Block State Management
    func getCurrentNote() -> String? {
        let note = blocks.first?.userData?.value(forKey: "noteName") as? String
        print("🔍 Nota actual: \(note ?? "ninguna")")
        return note
    }
    
    func removeLastBlock() {
        print("🗑️ Eliminando último bloque...")
        guard let lastBlock = blocks.last,
              !blockInfos.isEmpty else {
            print("⚠️ No hay bloque para eliminar.")
            return
        }
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.3)
        let group = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([group, remove])
        
        lastBlock.run(sequence) { [weak self] in
            guard let self = self else { return }
            print("🗑️ Bloque eliminado. Actualizando lista de bloques...")
            self.blocks.removeLast()
            self.blockInfos.removeLast()
            self.updateBlockPositions()
        }
    }
    
    // MARK: - Block Progress Management
    func updateCurrentBlockProgress(hitTime: Date) -> Bool {
        print("⏱️ updateCurrentBlockProgress llamado a las \(hitTime)")
        guard let index = blockInfos.indices.last else {
            print("⚠️ No hay bloque actual para actualizar.")
            return false
        }
        
        var currentInfo = blockInfos[index]
        print("   Bloque actual: nota \(currentInfo.note), currentHits: \(currentInfo.currentHits)")
        
        if currentInfo.holdStartTime == nil {
            currentInfo.holdStartTime = hitTime
            blockInfos[index] = currentInfo
            print("   Se inicia el hold del bloque a \(hitTime)")
        }
        
        let holdDuration = Date().timeIntervalSince(currentInfo.holdStartTime ?? Date())
        print("   Duración del hold: \(holdDuration) (requerida: \(currentInfo.requiredTime))")
        
        if holdDuration >= currentInfo.requiredTime {
            currentInfo.currentHits += 1
            print("   Hit registrado. currentHits ahora: \(currentInfo.currentHits)")
            currentInfo.holdStartTime = nil
            blockInfos[index] = currentInfo
            
            if currentInfo.currentHits >= currentInfo.requiredHits {
                print("   Requisitos completos (hits: \(currentInfo.currentHits), requeridos: \(currentInfo.requiredHits)). Se eliminará el bloque.")
                removeLastBlock()
                return true
            }
        }
        
        return false
    }
    
    func resetCurrentBlockProgress() {
        print("🔄 Reset current block progress")
        guard let index = blockInfos.indices.last else {
            print("⚠️ No hay bloque actual para resetear.")
            return
        }
        var currentInfo = blockInfos[index]
        currentInfo.currentHits = 0
        currentInfo.holdStartTime = nil
        blockInfos[index] = currentInfo
        print("   Progreso del bloque reseteado.")
    }
    
}
