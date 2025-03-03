//
//  GameScene.swift
//  MusicBlocksPruebas
//
//  Created by Jose R. García on 6/2/25.
//

import SpriteKit

class GameScene: SKScene {
    
    
    // MARK: - Configuración de Bloques
    let blockSize = CGSize(width: 280, height: 120)
    let blockSpacing: CGFloat = 5.0
    var blocks: [SKNode] = []
    var totalBlocksAppeared = 0
    
    // Variables para el contador de tiempo (opcional)
    var elapsedTime: TimeInterval = 0
    var lastUpdateTime: TimeInterval = 0
    
    /// Posición superior para colocar el bloque nuevo.
    var topSlotY: CGFloat {
        return size.height - blockSize.height / 2 - blockSpacing
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        
        let spawnSequence = SKAction.sequence([
            SKAction.run { [weak self] in self?.spawnBlock() },
            SKAction.wait(forDuration: 4.0)
        ])
        let spawnRepeat = SKAction.repeat(spawnSequence, count: 6)
        run(spawnRepeat)
    }
    
    /// Crea un bloque con la lógica de animación y delega la generación del contenido visual.
    func createBlock() -> SKNode {
        let blockNode = SKNode()
        let blockStyle = BlockStyle.defaultBlock  // Puedes cambiar a otro estilo si lo deseas.
        
        // --- Fondo principal del bloque ---
        let background = SKShapeNode(rectOf: blockSize, cornerRadius: blockStyle.cornerRadius)
        background.fillColor = blockStyle.backgroundColor
        background.strokeColor = blockStyle.borderColor
        background.lineWidth = blockStyle.borderWidth
        if let texture = blockStyle.fillTexture {
            background.fillTexture = texture
            background.alpha = blockStyle.textureOpacity
        }
        background.zPosition = 0
        blockNode.addChild(background)
        
        // --- Generación del contenido visual del bloque ---
        // Aquí definimos la nota a visualizar. Por ejemplo, usamos siempre la misma nota para testear:
        let fixedNote: MusicalNote = .siSostenido4
        
        // Define las posiciones base para la nota en el pentagrama.
        let baseNoteX: CGFloat = 0  // Posición base en X (ajusta según tu diseño)
        let baseNoteY: CGFloat = 0    // Posición base en Y
        
        // Llama a la función del nuevo módulo para generar el contenido visual del bloque.
        let contentNode = BlockContentGenerator.generateBlockContent(with: blockStyle,
                                                                       blockSize: blockSize,
                                                                       desiredNote: fixedNote,
                                                                       baseNoteX: baseNoteX,
                                                                       baseNoteY: baseNoteY)
        blockNode.addChild(contentNode)
                
        return blockNode
    }
    
    /// Inserta un nuevo bloque y desplaza los bloques existentes hacia abajo.
    func spawnBlock() {
        if blocks.count >= 6 { return }
        
        let moveDuration = 0.5
        let moveDistance = blockSize.height + blockSpacing
        
        for block in blocks {
            let moveDown = SKAction.moveBy(x: 0, y: -moveDistance, duration: moveDuration)
            moveDown.timingMode = .easeInEaseOut
            block.run(moveDown)
        }
        
        let newBlock = createBlock()
        newBlock.position = CGPoint(x: size.width / 2, y: topSlotY + moveDistance)
        addChild(newBlock)
        
        let moveToSlot = SKAction.moveTo(y: topSlotY, duration: moveDuration)
        moveToSlot.timingMode = .easeInEaseOut
        newBlock.run(moveToSlot)
        
        blocks.insert(newBlock, at: 0)
        totalBlocksAppeared += 1
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let delta = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        elapsedTime += delta
    }
}
