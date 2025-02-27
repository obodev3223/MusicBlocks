//
//  DetectedNoteCounterNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

//
//  DetectedNoteCounterNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit

class DetectedNoteCounterNode: SKNode {
    // MARK: - Layout Configuration
    struct Layout {
        static let defaultSize = CGSize(width: 100, height: 40)
        static let cornerRadius: CGFloat = 8
        static let backgroundAlpha: CGFloat = 0.15
        static let inactiveAlpha: CGFloat = 0.2
        static let animationDuration: TimeInterval = 0.2
        static let fontSize: CGFloat = 24
        static let padding: CGFloat = 10
    }
    
    // MARK: - Properties
    private let container: SKShapeNode
    private let noteLabel: SKLabelNode
    
    var currentNote: String = "-" {
        didSet {
            updateDisplay()
        }
    }
    
    var isActive: Bool = false {
        didSet {
            updateDisplay()
        }
    }
    
    // MARK: - Initialization
    init(size: CGSize = Layout.defaultSize) {
        // Inicializar contenedor sin glow
        container = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        
        // Inicializar etiqueta
        noteLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        noteLabel.fontSize = Layout.fontSize
        noteLabel.verticalAlignmentMode = .center
        
        super.init()
        
        setupNodes()
        updateDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        // Configurar contenedor
        container.fillColor = .white
        container.strokeColor = .clear
        container.alpha = Layout.backgroundAlpha
        addChild(container)
        
        // Configurar etiqueta
        noteLabel.position = CGPoint(x: 0, y: 0)
        container.addChild(noteLabel)
    }
    
    // MARK: - Updates
    private func updateDisplay() {
        // Actualizar texto
        noteLabel.text = currentNote
        
        // Actualizar colores según estado
        if isActive {
            noteLabel.fontColor = .black
            container.alpha = Layout.backgroundAlpha
        } else {
            noteLabel.fontColor = .gray
            container.alpha = Layout.backgroundAlpha * 0.5
        }
        
        // Animar cambio
        animateUpdate()
    }
    
    private func animateUpdate() {
        let scaleUp = SKAction.scale(to: 1.1, duration: Layout.animationDuration / 2)
        let scaleDown = SKAction.scale(to: 1.0, duration: Layout.animationDuration / 2)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        noteLabel.run(sequence)
    }
    
    // MARK: - Factory Methods
    static func createForRightSideBar(at position: CGPoint, zPosition: CGFloat = 10) -> DetectedNoteCounterNode {
        let node = DetectedNoteCounterNode()
        node.position = position
        node.zPosition = zPosition
        return node
    }
}



#if DEBUG
import SwiftUI

// MARK: - Previews
extension DetectedNoteCounterNode {
    static func createPreviewScene() -> SKScene {
        // Crear una nueva escena con tamaño fijo
        let scene = SKScene(size: CGSize(width: 300, height: 150))
        scene.backgroundColor = .clear
        
        // Crear y configurar el nodo activo
        let activeNode = DetectedNoteCounterNode()
        activeNode.currentNote = "A4"
        activeNode.isActive = true
        activeNode.position = CGPoint(x: 150, y: 100)
        scene.addChild(activeNode)
        
        // Crear y configurar el nodo inactivo
        let inactiveNode = DetectedNoteCounterNode()
        inactiveNode.currentNote = "-"
        inactiveNode.isActive = false
        inactiveNode.position = CGPoint(x: 150, y: 50)
        scene.addChild(inactiveNode)
        
        return scene
    }
}

struct DetectedNoteCounterPreview: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3)
            SpriteView(scene: DetectedNoteCounterNode.createPreviewScene())
        }
        .frame(width: 300, height: 150)
    }
}

#endif
