//
//  TopBar.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit

class TopBar: SKNode {
    // MARK: - Layout Configuration
    private struct Layout {
        static let cornerRadius: CGFloat = 15
        static let glowRadius: Float = 8.0
        static let backgroundAlpha: CGFloat = 0.95
        static let shadowOffset = CGPoint(x: 0, y: -2)
        static let shadowOpacity: Float = 0.2
        static let padding: CGFloat = 20
        static let scoreFontSize: CGFloat = 24
        static let scoreLabelOffset: CGPoint = CGPoint(x: 0, y: -2)
    }
    
    // MARK: - Properties
    private let size: CGSize
    private let scoreLabel: SKLabelNode
    private var score: Int = 0
    
    // MARK: - Initialization
    private init(width: CGFloat, height: CGFloat, position: CGPoint) {
        self.size = CGSize(width: width, height: height)
        
        // Inicializar etiqueta de puntuación
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.fontSize = Layout.scoreFontSize
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .center
        
        super.init()
        
        self.position = position
        setupNodes()
        updateScore(0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupNodes() {
        // Crear nodo de sombra
        let shadowNode = SKEffectNode()
        let shadowShape = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        shadowShape.fillColor = .black
        shadowShape.strokeColor = .clear
        shadowShape.alpha = Layout.backgroundAlpha
        shadowNode.addChild(shadowShape)
        shadowNode.shouldRasterize = true
        shadowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": Layout.glowRadius])
        shadowNode.position = Layout.shadowOffset
        shadowNode.alpha = CGFloat(Layout.shadowOpacity)
        
        // Crear fondo principal
        let backgroundNode = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        backgroundNode.fillColor = .white
        backgroundNode.strokeColor = .clear
        backgroundNode.alpha = Layout.backgroundAlpha
        
        // Añadir nodos en orden
        addChild(shadowNode)
        addChild(backgroundNode)
        
        // Configurar y añadir etiqueta de puntuación
        scoreLabel.position = Layout.scoreLabelOffset
        scoreLabel.fontColor = .black
        addChild(scoreLabel)
    }
    
    // MARK: - Public Methods
    static func create(width: CGFloat, height: CGFloat, position: CGPoint) -> TopBar {
        return TopBar(width: width, height: height, position: position)
    }
    
    func updateScore(_ newScore: Int) {
        score = newScore
        scoreLabel.text = "Puntuación: \(score)"
        
        // Animar actualización
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        scoreLabel.run(SKAction.sequence([scaleUp, scaleDown]))
    }
}


// MARK: - Previews
#if DEBUG
import SwiftUI

extension TopBar {
    static func createPreviewScene() -> SKScene {
        // Crear una escena de ejemplo con diferentes estados de TopBar
        let scene = SKScene(size: CGSize(width: 400, height: 300))
        scene.backgroundColor = .lightGray
        
        // Crear un TopBar con puntuación 0
        let defaultTopBar = TopBar.create(
            width: 350,
            height: 60,
            position: CGPoint(x: 200, y: 250)
        )
        scene.addChild(defaultTopBar)
        
        // Crear un TopBar con puntuación alta
        let highScoreTopBar = TopBar.create(
            width: 350,
            height: 60,
            position: CGPoint(x: 200, y: 150)
        )
        highScoreTopBar.updateScore(1250)
        scene.addChild(highScoreTopBar)
        
        // Crear un TopBar con puntuación muy alta
        let veryHighScoreTopBar = TopBar.create(
            width: 350,
            height: 60,
            position: CGPoint(x: 200, y: 50)
        )
        veryHighScoreTopBar.updateScore(9999)
        scene.addChild(veryHighScoreTopBar)
        
        return scene
    }
}

struct TopBarPreview: PreviewProvider {
    static var previews: some View {
        SpriteView(scene: TopBar.createPreviewScene())
            .frame(width: 400, height: 300)
            .previewLayout(.fixed(width: 400, height: 300))
    }
}
#endif

