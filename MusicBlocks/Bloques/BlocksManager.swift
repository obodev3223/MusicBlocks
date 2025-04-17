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
    
    // Propiedad para tracking del tiempo de inicio de procesamiento
    private var processingStartTime: Date?
    
    // MARK: - Constants
    private struct Constants {
        static let initialDelay: TimeInterval = 1.0
        static let minSpawnInterval: TimeInterval = 1.5
    }
    
    // MARK: - Estados para controlar el flujo de procesamiento de bloques
    private var isProcessingBlock: Bool = false
    private var lastHitTime: Date? = nil
    
    var isBlockProcessing: Bool {
        return isProcessingBlock
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
    
    // MARK: - Process State
    // Método para forzar el reset del estado de procesamiento
    func forceResetProcessingState() {
        GameLogger.shared.blockMovement("🔄 Forzando reset del estado de procesamiento de bloques")
        isProcessingBlock = false
        processingStartTime = nil
    }

    // Método para implementar el timeout de seguridad
    private func setupProcessingTimeout() {
        processingStartTime = Date()
        
        // Si después de 2 segundos seguimos en estado de procesamiento, resetearlo
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.isProcessingBlock == true else { return }
            
            // Verificar cuánto tiempo ha pasado desde que comenzó el procesamiento
            if let startTime = self.processingStartTime,
               Date().timeIntervalSince(startTime) >= 2.0 {
                GameLogger.shared.blockMovement("⚠️ Timeout detectado - Reseteando estado de procesamiento")
                self.forceResetProcessingState()
            }
        }
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
    
    // Método modificado para crear el bloque completo
    private func createBlock() -> SKNode {
        print("➡️ Creando nuevo bloque...")
        guard let currentLevel = gameManager.currentLevel else {
            print("❌ Error: No hay nivel actual")
            return createDefaultBlock()
        }
        
        let blockNode = SKNode()
        blockNode.zPosition = 2
        
        let allowedStyles = currentLevel.allowedStyles
        
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
        contentNode.name = "content"
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
        
        // Si el bloque requiere múltiples hits, añadir el contador inicial
        if config.requiredHits > 1 {
            // Esperamos un poco para agregar el contador para que la animación sea más fluida
            let waitAction = SKAction.wait(forDuration: 0.2)
            let addCounterAction = SKAction.run { [weak self] in
                self?.updateHitCounter(on: blockNode, currentHits: 0, requiredHits: config.requiredHits)
            }
            blockNode.run(SKAction.sequence([waitAction, addCounterAction]))
        }
        
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
            
            //      print("✅ Bloque añadido en posición Y: \(startY)")
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
    // 10. Modificaciones al método createBlockContainer para que sea más fácil acceder a sus componentes
    private func createBlockContainer(with style: BlockStyle) -> SKNode {
        print("🖼️ Creando contenedor para bloque con estilo: \(style.name)")
        let container = SKNode()
        container.name = "container"
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
            shadowNode.name = "shadow"
            container.addChild(shadowNode)
        }
        
        let background = createBackground(with: style)
        background.name = "background" // Importante para poder referenciarlo después
        container.addChild(background)
        
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
        GameLogger.shared.blockMovement("↕️ updateBlockPositions - Actualizando posiciones de \(blocks.count) bloques")
        let moveDistance = blockSize.height + blockSpacing
        let moveDuration = 0.5
        
        // Para cada bloque actualizado
        for (index, block) in blocks.enumerated() {
            let targetY = (mainAreaHeight/2) - (blockSize.height/2) - (moveDistance * CGFloat(index))
            GameLogger.shared.blockMovement("   Bloque \(index): ID: \(ObjectIdentifier(block).hashValue), moviéndose a Y = \(targetY)")
            
            // Verificar posición final después de la animación
            let moveToPosition = SKAction.moveTo(y: targetY, duration: moveDuration)
            moveToPosition.timingMode = .easeInEaseOut
            
            block.removeAllActions()
            block.run(moveToPosition) {
                    GameLogger.shared.blockMovement("   ✓ Bloque \(index) completó su movimiento a Y = \(block.position.y)")
                }
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
        
    // Versión modificada de removeLastBlock que acepta un closure de completion
    func removeLastBlockWithCompletion(completion: @escaping () -> Void) {
        GameLogger.shared.blockMovement("🗑️ removeLastBlockWithCompletion llamado. Bloques en cola: \(blocks.count)")

        // Definir una variable local para garantizar que el completion se llame una sola vez
        var completionCalled = false
        
        // Wrapper para el completion que evita llamadas múltiples
        let safeCompletion = {
            if !completionCalled {
                completionCalled = true
                completion()
            }
        }

        guard let lastBlock = blocks.last,
              !blockInfos.isEmpty else {
            GameLogger.shared.blockMovement("⚠️ No hay bloque para eliminar, ejecutando completion handler")
            safeCompletion()
            return
        }
        
        let nodeID = ObjectIdentifier(lastBlock).hashValue
        GameLogger.shared.blockMovement("🔍 Eliminando bloque ID: \(nodeID), posición actual: \(lastBlock.position)")
        
        // Timeout de seguridad para la animación
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self, weak lastBlock] in
            // Si el bloque todavía existe pero la animación no terminó, forzamos su eliminación
            if let block = lastBlock, block.parent != nil {
                GameLogger.shared.blockMovement("⚠️ Timeout de animación para bloque ID: \(nodeID)")
                block.removeAllActions()
                block.removeFromParent()
                
                // Asegurarnos de que el bloque se elimine de las colecciones
                if let self = self {
                    if self.blocks.last == block {
                        self.blocks.removeLast()
                    }
                    if !self.blockInfos.isEmpty {
                        self.blockInfos.removeLast()
                    }
                    self.updateBlockPositions()
                }
                
                // Asegurar que el completion se llame
                safeCompletion()
            }
        }
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.3)
        let group = SKAction.group([fadeOut, scaleDown])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([group, remove])
        
        // Después de ejecutar la animación
        lastBlock.run(sequence) { [weak self, weak lastBlock] in
            guard let self = self else {
                GameLogger.shared.blockMovement("⚠️ BlocksManager fue liberado durante la animación del bloque \(nodeID)")
                safeCompletion()
                return
            }
            
            guard let block = lastBlock else {
                GameLogger.shared.blockMovement("⚠️ El bloque fue liberado durante la animación")
                safeCompletion()
                return
            }
            
            GameLogger.shared.blockMovement("✅ Animación completada para bloque ID: \(nodeID)")
            GameLogger.shared.blockMovement("   ¿Bloque sigue siendo hijo de su padre? \(block.parent != nil)")
            
            // Antes de eliminar de las listas
            GameLogger.shared.blockMovement("   Antes de eliminar - blocks.count: \(self.blocks.count), blockInfos.count: \(self.blockInfos.count)")
            
            if self.blocks.last != block {
                GameLogger.shared.blockMovement("⚠️ Error crítico: el último bloque ya no es el que intentamos eliminar")
            }
            
            if !self.blocks.isEmpty {
                self.blocks.removeLast()
            } else {
                GameLogger.shared.blockMovement("⚠️ Error: blocks array vacío antes de eliminar")
            }
            
            if !self.blockInfos.isEmpty {
                self.blockInfos.removeLast()
            } else {
                GameLogger.shared.blockMovement("⚠️ Error: blockInfos array vacío antes de eliminar")
            }
            
            GameLogger.shared.blockMovement("   Después de eliminar - blocks.count: \(self.blocks.count), blockInfos.count: \(self.blockInfos.count)")
            
            self.updateBlockPositions()
            safeCompletion()
        }
    }

    func resetCurrentBlockProgress() {
        GameLogger.shared.blockMovement("🔄 Reset current block progress llamado")
        GameLogger.shared.blockMovement("   isProcessingBlock antes del reset: \(isProcessingBlock)")

        // Después de resetear
        isProcessingBlock = false
        processingStartTime = nil
        GameLogger.shared.blockMovement("   isProcessingBlock después del reset: \(isProcessingBlock)")

        guard let index = blockInfos.indices.last else {
            print("⚠️ No hay bloque actual para resetear.")
            return
        }
        var currentInfo = blockInfos[index]
        currentInfo.currentHits = 0
        blockInfos[index] = currentInfo
        print("   Progreso del bloque reseteado.")
        
        // Al final del método
        if let index = blockInfos.indices.last, blockInfos[index].currentHits > 0 {
            GameLogger.shared.blockMovement("   Hits reseteados a 0 para bloque \(blockInfos[index].note)")
        } else {
            GameLogger.shared.blockMovement("   No se pudo resetear ningún bloque, índice válido: \(blockInfos.indices.last != nil)")
        }
    }
    
    // 1. Modificar el método updateCurrentBlockProgress para incluir feedback visual
    func updateCurrentBlockProgress(hitTime: Date) -> Bool {
        GameLogger.shared.blockMovement("⏱️ updateCurrentBlockProgress llamado a las \(hitTime)")
        GameLogger.shared.blockMovement("   Estado actual: isProcessingBlock=\(isProcessingBlock), lastHitTime=\(String(describing: lastHitTime))")

        // Si ya estamos procesando un bloque o ha pasado muy poco tiempo desde el último hit,
        // ignoramos esta llamada para evitar doble procesamiento
        let minTimeBetweenHits: TimeInterval = 0.5 // 500ms mínimo entre hits
        if isProcessingBlock ||
           (lastHitTime != nil && hitTime.timeIntervalSince(lastHitTime!) < minTimeBetweenHits) {
            GameLogger.shared.blockMovement("⚠️ Ignorando hit - Procesando: \(isProcessingBlock), Tiempo desde último hit: \(lastHitTime != nil ? hitTime.timeIntervalSince(lastHitTime!) : 0)")
            return false
        }
        
        // Marcar como procesando y registrar la hora del hit
        isProcessingBlock = true
        lastHitTime = hitTime
        
        // Iniciar timeout de seguridad
        setupProcessingTimeout()
        
        guard let index = blockInfos.indices.last else {
            print("⚠️ No hay bloque actual para actualizar.")
            isProcessingBlock = false
            return false
        }
        
        var currentInfo = blockInfos[index]
        print("   Bloque actual: nota \(currentInfo.note), currentHits: \(currentInfo.currentHits)")
        
        // Incrementar contador de hits
        currentInfo.currentHits += 1
        GameLogger.shared.blockMovement("   Hit \(currentInfo.currentHits)/\(currentInfo.requiredHits) registrado para bloque \(currentInfo.note)")

        // NUEVO: Actualizamos la apariencia visual del bloque si requiere múltiples hits
        if currentInfo.requiredHits > 1 && currentInfo.currentHits < currentInfo.requiredHits {
            updateBlockAppearanceForHit(
                node: currentInfo.node,
                style: currentInfo.style,
                currentHits: currentInfo.currentHits,
                requiredHits: currentInfo.requiredHits
            )
        }
        
        blockInfos[index] = currentInfo
        
        // Verificar si hemos alcanzado el número requerido de hits
        if currentInfo.currentHits >= currentInfo.requiredHits {
            GameLogger.shared.blockMovement("🗑️ Requerimientos cumplidos, intentando eliminar bloque ID: \(ObjectIdentifier(currentInfo.node).hashValue)")
            
            // Eliminar el bloque con animación, pero solo liberar el estado cuando termine
            removeLastBlockWithCompletion { [weak self] in
                self?.isProcessingBlock = false
                self?.processingStartTime = nil
                print("✅ Procesamiento de bloque completado.")
            }
            return true
        }
        
        // Si no se eliminó el bloque, liberamos el estado de procesamiento inmediatamente
        isProcessingBlock = false
        processingStartTime = nil
        return false
    }
    
    // 2. Nuevo método para gestionar la actualización visual de los bloques multi-hit
    private func updateBlockAppearanceForHit(node: SKNode, style: String, currentHits: Int, requiredHits: Int) {
        // Solo procesamos tipos de bloques que sabemos que requieren múltiples hits
        switch style {
        case "iceBlock":
            updateIceBlockAppearance(block: node, currentHits: currentHits, requiredHits: requiredHits)
        case "hardiceBlock":
            updateHardIceBlockAppearance(block: node, currentHits: currentHits, requiredHits: requiredHits)
        default:
            break // No hacemos nada para otros tipos de bloques
        }
    }

    // 3. Método para actualizar la apariencia de los bloques de hielo
    private func updateIceBlockAppearance(block: SKNode, currentHits: Int, requiredHits: Int) {
        // Calcular progreso (0.0 a 1.0)
        let progress = CGFloat(currentHits) / CGFloat(requiredHits)
        
        // Actualizar contador numérico
        updateHitCounter(on: block, currentHits: currentHits, requiredHits: requiredHits)
        
        // Añadir textura de grietas con intensidad estándar
        addCracksTexture(to: block, progress: progress, intensity: 1.0)
        
        // Aumentar transparencia
        updateTransparency(for: block, progress: progress)
        
        // Efecto de "golpe" temporal
        addImpactEffect(to: block)
        
        // Añadir partículas de hielo
        addIceParticles(to: block, intensity: 0.5)
        
        // Reproducir sonido de hielo agrietándose (si está disponible)
        playCrackSound(intensity: 0.5)
    }

    // 4. Método para actualizar la apariencia de los bloques de hielo duro (con efectos más intensos)
    private func updateHardIceBlockAppearance(block: SKNode, currentHits: Int, requiredHits: Int) {
        // Calcular progreso (0.0 a 1.0)
        let progress = CGFloat(currentHits) / CGFloat(requiredHits)
        
        // Actualizar contador numérico
        updateHitCounter(on: block, currentHits: currentHits, requiredHits: requiredHits)
        
        // Añadir textura de grietas con mayor intensidad para el hielo duro
        addCracksTexture(to: block, progress: progress, intensity: 1.5)
        
        // Cambiar transparencia más lentamente que el bloque normal de hielo
        updateTransparency(for: block, progress: progress * 0.7)
        
        // Efecto de "golpe" más intenso
        addImpactEffect(to: block, intensity: 1.2)
        
        // Añadir partículas de hielo más intensas
        addIceParticles(to: block, intensity: 1.0)
        
        // Reproducir sonido de hielo agrietándose más prominente
        playCrackSound(intensity: 1.0)
        
        // Añadir un efecto de brillo temporal para hielo duro
        addFrostGlowEffect(to: block)
    }

    // Método para crear partículas de hielo al golpear
    private func addIceParticles(to block: SKNode, intensity: CGFloat) {
        // Crear el nodo emisor
        let emitter = SKEmitterNode()
        emitter.name = "iceParticles"
        emitter.targetNode = block.parent // Para que las partículas se queden en la escena incluso si el bloque se mueve
        
        // Configurar las partículas
        emitter.particleBirthRate = 15 * intensity
        emitter.numParticlesToEmit = Int(10 * intensity)
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.3
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2 // Emitir en todas direcciones
        
        // Velocidad y tamaño
        emitter.particleSpeed = 20 * intensity
        emitter.particleSpeedRange = 15
        emitter.particleScale = 0.03 + (0.02 * intensity)
        emitter.particleScaleRange = 0.02
        emitter.xAcceleration = 0
        emitter.yAcceleration = -50 // Gravedad sutil
        
        // Color y apariencia
        emitter.particleColor = SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleAlpha = 0.7
        emitter.particleAlphaRange = 0.3
        emitter.particleTexture = SKTexture(imageNamed: "spark") // Usar una textura simple de chispa/partícula
        
        // Colocar el emisor en el centro del bloque
        emitter.position = .zero
        emitter.zPosition = 20
        
        // Añadir el emisor al bloque
        block.addChild(emitter)
        
        // Eliminar el emisor después de un tiempo
        let waitAction = SKAction.wait(forDuration: 0.3)
        let removeAction = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([waitAction, removeAction]))
    }

    // Método para reproducir sonido de hielo agrietándose
    private func playCrackSound(intensity: CGFloat) {
        // Usar el controlador de sonidos de UI para reproducir un sonido
        UISoundController.shared.playUISound(.impact, pitchMultiplier: 1.0 + Float(intensity * 0.2))
    }

    // Método para añadir un efecto de brillo helado (sólo para bloques duros)
    private func addFrostGlowEffect(to block: SKNode) {
        // Buscar el nodo de fondo
        guard let background = findBackgroundNode(in: block) else { return }
        
        // Crear un nodo de efecto para aplicar un filtro de brillo
        let glowNode = SKEffectNode()
        glowNode.name = "frostGlow"
        glowNode.zPosition = 2
        
        // Aplicar un filter de brillo
        glowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 3.0])
        glowNode.shouldRasterize = true
        
        // Crear una copia del fondo como forma con resplandor
        let glowShape = SKShapeNode(rectOf: background.frame.size, cornerRadius: 15)
        glowShape.fillColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.5)
        glowShape.strokeColor = .clear
        glowShape.alpha = 0
        
        glowNode.addChild(glowShape)
        
        // Añadir el nodo de brillo
        block.addChild(glowNode)
        
        // Animación de brillo
        let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: 0.1)
        let wait = SKAction.wait(forDuration: 0.1)
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let remove = SKAction.removeFromParent()
        
        glowShape.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }

    // 5. Método para el contador numérico en la esquina superior derecha
    private func updateHitCounter(on block: SKNode, currentHits: Int, requiredHits: Int) {
        // Eliminar contador anterior si existe
        block.childNode(withName: "hitCounter")?.removeFromParent()
        
        // Calcular hits restantes
        let remainingHits = requiredHits - currentHits
        
        // Obtener información del estilo para personalizar el contador
        let blockStyle = block.userData?.value(forKey: "blockStyle") as? String ?? "defaultBlock"
        
        // Crear un nuevo nodo contenedor para el contador
        let counterContainer = SKNode()
        counterContainer.name = "hitCounter"
        counterContainer.zPosition = 10
        
        // Posicionarlo en la esquina superior derecha, con un pequeño margen
        counterContainer.position = CGPoint(x: blockSize.width/2 - 15, y: blockSize.height/2 - 15)
        
        // Configurar apariencia según el tipo de bloque
        let counterBg: SKShapeNode
        let radius: CGFloat = 12
        let counterColor: SKColor
        let textColor: SKColor
        
        switch blockStyle {
        case "iceBlock":
            counterBg = SKShapeNode(circleOfRadius: radius)
            counterColor = SKColor(red: 0.8, green: 0.95, blue: 1.0, alpha: 0.9)
            textColor = SKColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 1.0)
        case "hardiceBlock":
            counterBg = SKShapeNode(circleOfRadius: radius)
            counterColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.9)
            textColor = SKColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0)
            
            // Agregar borde más grueso para hardiceBlock
            counterBg.lineWidth = 2.0
            counterBg.strokeColor = SKColor(red: 0.0, green: 0.5, blue: 0.9, alpha: 0.8)
        default:
            counterBg = SKShapeNode(circleOfRadius: radius)
            counterColor = .white
            textColor = .darkGray
        }
        
        counterBg.fillColor = counterColor
        counterBg.strokeColor = textColor.withAlphaComponent(0.3)
        counterBg.lineWidth = 1.5
        counterBg.alpha = 0.85
        counterContainer.addChild(counterBg)
        
        // Crear etiqueta con el número
        let countLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        countLabel.text = "\(remainingHits)"
        countLabel.fontSize = 14
        countLabel.fontColor = textColor
        countLabel.verticalAlignmentMode = .center
        countLabel.horizontalAlignmentMode = .center
        countLabel.position = .zero
        counterContainer.addChild(countLabel)
        
        // Añadir el contador al bloque
        block.addChild(counterContainer)
        
        // Efecto de aparición
        counterContainer.setScale(0)
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.2)
        scaleAction.timingMode = .easeOut
        counterContainer.run(scaleAction)
    }

    // 6. Método para añadir grietas utilizando una textura de imagen
    private func addCracksTexture(to block: SKNode, progress: CGFloat, intensity: CGFloat = 1.0) {
        // Eliminar grietas anteriores si existen
        block.childNode(withName: "cracksTexture")?.removeFromParent()
        
        // Crear nodo de sprite para la textura de grietas
        let cracksTexture = SKSpriteNode(imageNamed: "grietas.png")
        cracksTexture.name = "cracksTexture"
        cracksTexture.zPosition = 5
        
        // Ajustar el tamaño para que cubra todo el bloque
        cracksTexture.size = blockSize
        
        // Obtener el estilo del bloque para personalizar las grietas
        let blockStyle = block.userData?.value(forKey: "blockStyle") as? String ?? "defaultBlock"
        
        // Calcular la intensidad de la textura basada en el progreso y el tipo de bloque
        let baseAlpha: CGFloat = progress * 0.8 * intensity
        var textureTint: SKColor
        
        switch blockStyle {
        case "iceBlock":
            // Para bloques de hielo regular, grietas más claras
            textureTint = SKColor.black.withAlphaComponent(baseAlpha)
        case "hardiceBlock":
            // Para bloques de hielo duro, grietas más azuladas y oscuras
            textureTint = SKColor(red: 0.0, green: 0.1, blue: 0.3, alpha: baseAlpha * 1.2)
        default:
            textureTint = SKColor.black.withAlphaComponent(baseAlpha)
        }
        
        // Configurar el tinte y la mezcla
        cracksTexture.color = textureTint
        cracksTexture.colorBlendFactor = 1.0
        
        // Añadir efecto de mezcla para que la textura se combine con el fondo
        cracksTexture.blendMode = .multiply
        
        // Añadir al bloque
        block.addChild(cracksTexture)
        
        // Añadir efecto de aparición
        cracksTexture.alpha = 0
        cracksTexture.run(SKAction.fadeIn(withDuration: 0.2))
    }

    // 7. Método para actualizar transparencia gradualmente
    private func updateTransparency(for block: SKNode, progress: CGFloat) {
        // Obtener el nodo de fondo del bloque
        guard let background = findBackgroundNode(in: block) else { return }
        
        // Obtener el estilo del bloque
        let blockStyle = block.userData?.value(forKey: "blockStyle") as? String ?? "defaultBlock"
        
        // Ajustar la transparencia basada en el tipo de bloque
        let startAlpha: CGFloat
        let endAlpha: CGFloat
        
        switch blockStyle {
        case "iceBlock":
            // El hielo normal se vuelve bastante transparente
            startAlpha = 0.95
            endAlpha = 0.5
        case "hardiceBlock":
            // El hielo duro mantiene más opacidad
            startAlpha = 0.95
            endAlpha = 0.7
        default:
            startAlpha = 0.95
            endAlpha = 0.6
        }
        
        // Calcular nueva alpha basada en el progreso
        let newAlpha = startAlpha - (progress * (startAlpha - endAlpha))
        
        // Animar el cambio gradualmente
        let fadeAction = SKAction.fadeAlpha(to: newAlpha, duration: 0.3)
        fadeAction.timingMode = .easeOut
        background.run(fadeAction)
        
        // Para el hielo, también podemos cambiar sutilmente el color para simular "derretimiento"
        if blockStyle.contains("ice") {
            // Color base
            var baseColor: SKColor
            var targetColor: SKColor
            
            if blockStyle == "iceBlock" {
                // Azul claro a un tono más acuoso
                baseColor = SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: newAlpha)
                targetColor = SKColor(red: 0.9, green: 0.95, blue: 1.0, alpha: newAlpha)
            } else {
                // Azul más intenso a un tono más claro
                baseColor = SKColor(red: 0.6, green: 0.8, blue: 1.0, alpha: newAlpha)
                targetColor = SKColor(red: 0.7, green: 0.85, blue: 0.95, alpha: newAlpha)
            }
            
            // Mezclar colores según el progreso
            let blendedColor = blendColors(baseColor, targetColor, percentage: progress)
            
            // Animar el cambio de color
            let colorAction = SKAction.colorize(with: blendedColor, colorBlendFactor: 1.0, duration: 0.3)
            colorAction.timingMode = .easeOut
            background.run(colorAction)
        }
    }

    // Función auxiliar para mezclar colores
    private func blendColors(_ color1: SKColor, _ color2: SKColor, percentage: CGFloat) -> SKColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return SKColor(
            red: r1 + (r2 - r1) * percentage,
            green: g1 + (g2 - g1) * percentage,
            blue: b1 + (b2 - b1) * percentage,
            alpha: a1 + (a2 - a1) * percentage
        )
    }

    // 8. Método para añadir efecto visual de impacto
    private func addImpactEffect(to block: SKNode, intensity: CGFloat = 1.0) {
        // Efecto de "golpe" - pulso rápido
        let scaleDown = SKAction.scale(to: 0.97, duration: 0.05 * intensity)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1 * intensity)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        block.run(sequence)
        
        // Pequeño temblor
        let shakeSequence = SKAction.sequence([
            SKAction.moveBy(x: 2 * intensity, y: 0, duration: 0.02),
            SKAction.moveBy(x: -4 * intensity, y: 0, duration: 0.04),
            SKAction.moveBy(x: 2 * intensity, y: 0, duration: 0.02)
        ])
        block.run(shakeSequence)
        
        // Efecto de pulsación en las grietas
        if let cracksTexture = block.childNode(withName: "cracksTexture") as? SKSpriteNode {
            let crackPulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 1.0, duration: 0.05),
                SKAction.fadeAlpha(to: cracksTexture.alpha, duration: 0.1)
            ])
            cracksTexture.run(crackPulse)
        }
    }

    // Método mejorado para manejar múltiples texturas en un bloque
    private func setupBlockMultiTexture(block: SKNode, background: SKShapeNode, baseTexture: SKTexture?, cracksTexture: SKTexture, progress: CGFloat, blockStyle: String) {
        // Eliminar textura compuesta anterior si existe
        block.childNode(withName: "blockMultiTexture")?.removeFromParent()
        
        // Crear un nodo contenedor para las texturas combinadas
        let multiTextureNode = SKNode()
        multiTextureNode.name = "blockMultiTexture"
        multiTextureNode.zPosition = 3 // Por encima del fondo pero debajo del contenido
        
        // 1. Primero añadir la textura base si existe
        if let baseTexture = baseTexture {
            let baseTextureSprite = SKSpriteNode(texture: baseTexture)
            baseTextureSprite.size = blockSize
            baseTextureSprite.alpha = 1.0 // La textura base siempre es completamente visible
            multiTextureNode.addChild(baseTextureSprite)
        }
        
        // 2. Luego añadir la textura de grietas con la opacidad adecuada
        let cracksOpacity = calculateCracksOpacity(progress: progress, blockStyle: blockStyle)
        let cracksSprite = SKSpriteNode(texture: cracksTexture)
        cracksSprite.size = blockSize
        cracksSprite.alpha = cracksOpacity
        
        // Ajustar el modo de mezcla para que las grietas se integren con la textura base
        cracksSprite.blendMode = .multiply
        
        // Ajustar el color tinte según el tipo de bloque
        if blockStyle == "hardiceBlock" {
            cracksSprite.color = SKColor(red: 0.0, green: 0.1, blue: 0.3, alpha: 1.0)
            cracksSprite.colorBlendFactor = 0.3
        } else {
            cracksSprite.color = SKColor.black
            cracksSprite.colorBlendFactor = 0.2
        }
        
        multiTextureNode.addChild(cracksSprite)
        
        // Añadir la composición de texturas al bloque
        block.addChild(multiTextureNode)
    }

    // Función auxiliar para calcular la opacidad de las grietas según el progreso
    private func calculateCracksOpacity(progress: CGFloat, blockStyle: String) -> CGFloat {
        switch blockStyle {
        case "iceBlock":
            // Para hielo normal, las grietas se ven más rápido
            return min(1.0, progress * 1.5)
        case "hardiceBlock":
            // Para hielo duro, las grietas aparecen más gradualmente
            return min(1.0, progress * 1.2)
        default:
            return progress
        }
    }

    // 9. Método para encontrar el nodo de fondo en la jerarquía del bloque
    private func findBackgroundNode(in block: SKNode) -> SKShapeNode? {
        // Buscar primero en los hijos directos
        for child in block.children {
            if let container = child as? SKNode {
                // Buscar en los hijos del contenedor
                for subChild in container.children {
                    if let background = subChild as? SKShapeNode {
                        return background
                    }
                }
            }
        }
        
        // Si no se encuentra, buscamos más profundamente
        return block.childNode(withName: "//background") as? SKShapeNode
    }
    
}
