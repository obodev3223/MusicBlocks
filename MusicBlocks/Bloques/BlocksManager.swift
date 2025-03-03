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
    private var totalBlocksAppeared = 0
    private weak var mainAreaNode: SKNode?
    private var mainAreaHeight: CGFloat = 0
    
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
        // Mover todo el código de createBlock() aquí
        let blockNode = SKNode()
        // ... resto del código de createBlock()
        return blockNode
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
