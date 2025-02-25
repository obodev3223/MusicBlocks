//
//  TopBar.swift
//  MusicBlocks
//
//  Created by Jose R. García on 25/2/25.
//

import SpriteKit
import UIKit

class TopBar: SKNode {
    // MARK: - Properties
    private var backgroundNode: SKShapeNode
    private var scoreLabel: SKLabelNode
    private var score: Int = 0
    
    // MARK: - Layout Configuration
    private struct Layout {
        static let cornerRadius: CGFloat = 15
        static let fontName = "Helvetica-Bold"
        static let scoreFontRatio: CGFloat = 0.4
    }
    
    // MARK: - Initialization
    init(size: CGSize) {
        // Inicializar nodos
        backgroundNode = SKShapeNode(rectOf: size, cornerRadius: Layout.cornerRadius)
        scoreLabel = SKLabelNode(fontNamed: Layout.fontName)
        
        // Llamar al inicializador de la superclase
        super.init()
        
        // Establecer el nombre del nodo para poder identificarlo
        self.name = "topBar"
        
        // Configurar el fondo
        setupBackground(size: size)
        
        // Configurar la etiqueta de puntuación
        setupScoreLabel(containerHeight: size.height)
        
        // Actualizar la puntuación inicial
        updateScore(0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupBackground(size: CGSize) {
        backgroundNode.fillColor = .white
        backgroundNode.strokeColor = .blue
        backgroundNode.lineWidth = 1.0
        addChild(backgroundNode)
    }
    
    private func setupScoreLabel(containerHeight: CGFloat) {
        scoreLabel.fontSize = containerHeight * Layout.scoreFontRatio
        scoreLabel.fontColor = .black
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: 0)
        addChild(scoreLabel)
    }
    
    // MARK: - Public Methods
    func updateScore(_ newScore: Int) {
        score = newScore
        scoreLabel.text = "Puntuación: \(score)"
    }
    
    func getScore() -> Int {
        return score
    }
}

// MARK: - Factory Extension
extension TopBar {
    static func create(width: CGFloat, height: CGFloat, position: CGPoint) -> TopBar {
        let topBar = TopBar(size: CGSize(width: width, height: height))
        topBar.position = position
        return topBar
    }
}
