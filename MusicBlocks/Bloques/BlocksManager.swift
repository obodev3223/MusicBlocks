//
//  BlocksManager.swift
//  MusicBlocks
//
//  Creado por Jose R. García el 17/4/25.
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
    
    private func updateBlockAppearanceForHit(node: SKNode, style: String, currentHits: Int, requiredHits: Int) {
            // Solo procesamos tipos de bloques que sabemos que requieren múltiples hits
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
                break // No hacemos nada para otros tipos de bloques
            }
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
        
}
