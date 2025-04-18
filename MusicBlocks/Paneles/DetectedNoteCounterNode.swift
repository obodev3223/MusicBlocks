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
        static let backgroundAlpha: CGFloat = 0.95
        static let inactiveAlpha: CGFloat = 0.6
        static let animationDuration: TimeInterval = 0.2
        static let fontSize: CGFloat = 18  // Fuente más pequeña
        static let padding: CGFloat = 10
        static let shadowRadius: CGFloat = 4.0
        static let shadowOpacity: Float = 0.2
        static let shadowOffset = CGPoint(x: 0, y: -1)
    }
    
    // MARK: - Properties
    private let containerSize: CGSize
    private let container: SKShapeNode
    private let shadowNode: SKEffectNode
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
        self.containerSize = size
        
        // Crear nodo de sombra
        shadowNode = SKEffectNode()
        let shadowShape = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        shadowShape.fillColor = .black
        shadowShape.strokeColor = .clear
        shadowShape.alpha = CGFloat(Layout.shadowOpacity)
        shadowNode.addChild(shadowShape)
        shadowNode.shouldRasterize = true
        shadowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": Layout.shadowRadius])
        shadowNode.position = Layout.shadowOffset
        
        // Inicializar contenedor principal
        container = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        
        // Etiqueta para el valor de la nota (centrada)
        noteLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        noteLabel.fontSize = min(size.height * 0.5, Layout.fontSize)
        noteLabel.verticalAlignmentMode = .center
        noteLabel.horizontalAlignmentMode = .center
        
        super.init()
        
        setupNodes()
        updateDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        // Aplicar estilo común del contenedor
        applyContainerStyle(size: containerSize)
        
        // Posicionar etiqueta en el centro
        noteLabel.position = CGPoint(x: 0, y: 0)
        addChild(noteLabel)
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
            container.alpha = Layout.inactiveAlpha
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
    static func createForRightSideBar(at position: CGPoint, size: CGSize = Layout.defaultSize, zPosition: CGFloat = 10) -> DetectedNoteCounterNode {
        let node = DetectedNoteCounterNode(size: size)
        node.position = position
        node.zPosition = zPosition
        return node
    }
}

// MARK: - Previews
#if DEBUG
import SwiftUI

extension DetectedNoteCounterNode {
    static func createPreviewScene() -> SKScene {
        let scene = SKScene(size: CGSize(width: 300, height: 150))
        scene.backgroundColor = .clear
        
        let activeNode = DetectedNoteCounterNode()
        activeNode.currentNote = "La4"
        activeNode.isActive = true
        activeNode.position = CGPoint(x: 150, y: 100)
        scene.addChild(activeNode)
        
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
