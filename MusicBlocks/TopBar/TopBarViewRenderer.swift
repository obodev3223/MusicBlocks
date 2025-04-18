//
//  TopBarViewRenderer.swift
//  MusicBlocks
//
//  Created by Jose R. García on 18/4/25.
//

import SpriteKit
import Foundation

/// Protocolo para renderizado de TopBar
protocol TopBarViewRenderer {
    /// Renderiza la vista inicial basada en el ViewModel
    /// - Parameter viewModel: Modelo de datos para la TopBar
    /// - Returns: Nodo de SpriteKit que representa la TopBar
    func render(viewModel: TopBarViewModel) -> SKNode
    
    /// Actualiza la vista con nuevos datos
    /// - Parameter viewModel: Modelo de datos actualizado
    func update(viewModel: TopBarViewModel)
}

/// Estrategia de renderizado para la TopBar principal
class MainTopBarRenderer: TopBarViewRenderer {
    // Nodos que necesitamos mantener para actualizaciones
    private var levelLabel: SKLabelNode?
    private var livesContainer: SKNode?
    private var scoreProgressNode: SKShapeNode?
    private var scoreLabel: SKLabelNode?
    
    func render(viewModel: TopBarViewModel) -> SKNode {
        let container = SKNode()
        
        // Renderizar nivel
        let levelLabel = SKLabelNode(text: "Nivel \(viewModel.levelId)")
        levelLabel.fontName = "Helvetica-Bold"
        levelLabel.fontSize = 18
        levelLabel.fontColor = .white
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.position = CGPoint(x: -150, y: 0)
        container.addChild(levelLabel)
        self.levelLabel = levelLabel
        
        // Renderizar vidas (similar a la implementación original)
        let livesContainer = renderLivesNodes(
            current: viewModel.lives.current, 
            total: viewModel.lives.total
        )
        livesContainer.position = CGPoint(x: 0, y: 0)
        container.addChild(livesContainer)
        self.livesContainer = livesContainer
        
        // Renderizar progreso de puntuación
        let scoreProgressNode = createScoreProgressNode(
            score: viewModel.score.current, 
            maxScore: viewModel.score.max
        )
        scoreProgressNode.position = CGPoint(x: 0, y: -15)
        container.addChild(scoreProgressNode)
        self.scoreProgressNode = scoreProgressNode
        
        // Renderizar etiqueta de puntuación
        let scoreLabel = SKLabelNode(text: "\(viewModel.score.current)")
        scoreLabel.fontName = "Helvetica"
        scoreLabel.fontSize = 14
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: -35)
        container.addChild(scoreLabel)
        self.scoreLabel = scoreLabel
        
        return container
    }
    
    func update(viewModel: TopBarViewModel) {
        // Actualizar nivel
        levelLabel?.text = "Nivel \(viewModel.levelId)"
        
        // Actualizar vidas
        updateLivesNodes(
            current: viewModel.lives.current, 
            total: viewModel.lives.total
        )
        
        // Actualizar progreso de puntuación
        updateScoreProgressNode(
            score: viewModel.score.current, 
            maxScore: viewModel.score.max
        )
        
        // Actualizar etiqueta de puntuación
        scoreLabel?.text = "\(viewModel.score.current)"
    }
    
    // Métodos privados para renderizado y actualización de vidas
    private func renderLivesNodes(current: Int, total: Int) -> SKNode {
        let container = SKNode()
        
        // Lógica de renderizado de corazones similar a la implementación original
        for i in 0..<total {
            let heart = SKSpriteNode(imageNamed: i < current ? "heart_full" : "heart_empty")
            heart.size = CGSize(width: 20, height: 20)
            heart.position = CGPoint(x: CGFloat(i - total/2) * 25, y: 0)
            container.addChild(heart)
        }
        
        return container
    }
    
    private func updateLivesNodes(current: Int, total: Int) {
        guard let livesContainer = livesContainer else { return }
        
        // Actualizar cada nodo de corazón
        livesContainer.children.enumerated().forEach { (index, node) in
            guard let heart = node as? SKSpriteNode else { return }
            heart.texture = SKTexture(imageNamed: index < current ? "heart_full" : "heart_empty")
        }
    }
    
    // Métodos privados para renderizado y actualización de progreso de puntuación
    private func createScoreProgressNode(score: Int, maxScore: Int) -> SKShapeNode {
        let progressWidth: CGFloat = 200
        let progressHeight: CGFloat = 10
        
        let backgroundPath = CGPath(
            roundedRect: CGRect(x: -progressWidth/2, y: -progressHeight/2, 
                                width: progressWidth, height: progressHeight),
            cornerWidth: 5, 
            cornerHeight: 5, 
            transform: nil
        )
        
        let backgroundNode = SKShapeNode(path: backgroundPath)
        backgroundNode.fillColor = .darkGray
        backgroundNode.strokeColor = .clear
        
        let progress = min(CGFloat(score) / CGFloat(maxScore), 1.0)
        let progressPath = CGPath(
            roundedRect: CGRect(x: -progressWidth/2, y: -progressHeight/2, 
                                width: progressWidth * progress, height: progressHeight),
            cornerWidth: 5, 
            cornerHeight: 5, 
            transform: nil
        )
        
        let progressNode = SKShapeNode(path: progressPath)
        progressNode.fillColor = .purple
        progressNode.strokeColor = .clear
        
        backgroundNode.addChild(progressNode)
        
        return backgroundNode
    }
    
    private func updateScoreProgressNode(score: Int, maxScore: Int) {
        guard let progressNode = scoreProgressNode else { return }
        
        // Remover el nodo de progreso anterior si existe
        progressNode.children.forEach { $0.removeFromParent() }
        
        let progressWidth: CGFloat = 200
        let progressHeight: CGFloat = 10
        
        let progress = min(CGFloat(score) / CGFloat(maxScore), 1.0)
        let progressPath = CGPath(
            roundedRect: CGRect(x: -progressWidth/2, y: -progressHeight/2, 
                                width: progressWidth * progress, height: progressHeight),
            cornerWidth: 5, 
            cornerHeight: 5, 
            transform: nil
        )
        
        let newProgressNode = SKShapeNode(path: progressPath)
        newProgressNode.fillColor = .purple
        newProgressNode.strokeColor = .clear
        
        progressNode.addChild(newProgressNode)
    }
}

/// Estrategia de renderizado para la TopBar de objetivos
class ObjectivesTopBarRenderer: TopBarViewRenderer {
    // Nodos para mantener referencias y actualizar
    private var objectiveTitleLabel: SKLabelNode?
    private var objectiveProgressNode: SKShapeNode?
    private var objectiveDetailsLabel: SKLabelNode?
    private var timeRemainingLabel: SKLabelNode?
    
    func render(viewModel: TopBarViewModel) -> SKNode {
        let container = SKNode()
        
        // Título del objetivo
        let titleLabel = SKLabelNode(text: determineObjectiveTitle(for: viewModel.objective))
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.fontSize = 18
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 10)
        container.addChild(titleLabel)
        self.objectiveTitleLabel = titleLabel
        
        // Nodo de progreso
        let progressNode = createObjectiveProgressNode(
            progress: viewModel.objective.progress
        )
        progressNode.position = CGPoint(x: 0, y: -10)
        container.addChild(progressNode)
        self.objectiveProgressNode = progressNode
        
        // Detalles del objetivo
        let detailsLabel = SKLabelNode(text: formatObjectiveDetails(for: viewModel.objective))
        detailsLabel.fontName = "Helvetica"
        detailsLabel.fontSize = 14
        detailsLabel.fontColor = .white
        detailsLabel.horizontalAlignmentMode = .center
        detailsLabel.position = CGPoint(x: 0, y: -30)
        container.addChild(detailsLabel)
        self.objectiveDetailsLabel = detailsLabel
        
        // Tiempo restante (si aplica)
        if let timeRemaining = viewModel.objective.timeRemaining, timeRemaining > 0 {
            let timeLabel = SKLabelNode(text: formatTimeRemaining(timeRemaining))
            timeLabel.fontName = "Helvetica"
            timeLabel.fontSize = 12
            timeLabel.fontColor = .lightGray
            timeLabel.horizontalAlignmentMode = .center
            timeLabel.position = CGPoint(x: 0, y: -50)
            container.addChild(timeLabel)
            self.timeRemainingLabel = timeLabel
        }
        
        return container
    }
    
    func update(viewModel: TopBarViewModel) {
        // Actualizar título del objetivo
        objectiveTitleLabel?.text = determineObjectiveTitle(for: viewModel.objective)
        
        // Actualizar progreso
        updateObjectiveProgressNode(progress: viewModel.objective.progress)
        
        // Actualizar detalles del objetivo
        objectiveDetailsLabel?.text = formatObjectiveDetails(for: viewModel.objective)
        
        // Actualizar tiempo restante
        if let timeRemaining = viewModel.objective.timeRemaining {
            timeRemainingLabel?.text = formatTimeRemaining(timeRemaining)
        }
    }
    
    // Métodos de ayuda para formateo
    private func determineObjectiveTitle(for objective: TopBarViewModel.ObjectiveData) -> String {
        switch objective.type {
        case "score": return "Objetivo: Puntuación"
        case "total_notes": return "Objetivo: Notas"
        case "note_accuracy": return "Objetivo: Precisión"
        case "block_destruction": return "Objetivo: Destrucción"
        case "total_blocks": return "Objetivo: Bloques"
        default: return "Objetivo Desconocido"
        }
    }
    
    private func formatObjectiveDetails(for objective: TopBarViewModel.ObjectiveData) -> String {
        return "\(Int(objective.current)) / \(Int(objective.target))"
    }
    
    private func formatTimeRemaining(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func createObjectiveProgressNode(progress: Double) -> SKShapeNode {
        let progressWidth: CGFloat = 200
        let progressHeight: CGFloat = 10
        
        let backgroundPath = CGPath(
            roundedRect: CGRect(x: -progressWidth/2, y: -progressHeight/2, 
                                width: progressWidth, height: progressHeight),
            cornerWidth: 5, 
            cornerHeight: 5, 
            transform: nil
        )
        
        let backgroundNode = SKShapeNode(path: backgroundPath)
        backgroundNode.fillColor = .darkGray
        backgroundNode.strokeColor = .clear
        
        let progressPath = CGPath(
            roundedRect: CGRect(x: -progressWidth/2, y: -progressHeight/2, 
                                width: progressWidth * CGFloat(progress), height: progressHeight),
            cornerWidth: 5, 
            cornerHeight: 5, 
            transform: nil
        )
        
        let progressNode = SKShapeNode(path: progressPath)
        progressNode.fillColor = .systemBlue
        progressNode.strokeColor = .clear
        
        backgroundNode.addChild(progressNode)
        
        return backgroundNode
    }
    
    private func updateObjectiveProgressNode(progress: Double) {
            guard let progressNode = objectiveProgressNode else { return }
            
            // Remover el nodo de progreso anterior si existe
            progressNode.children.forEach { $0.removeFromParent() }
            
            let progressWidth: CGFloat = 200
            let progressHeight: CGFloat = 10
            
            let progressPath = CGPath(
                roundedRect: CGRect(x: -progressWidth/2, y: -progressHeight/2,
                                    width: progressWidth * CGFloat(progress), height: progressHeight),
                cornerWidth: 5,
                cornerHeight: 5,
                transform: nil
            )
            
            let newProgressNode = SKShapeNode(path: progressPath)
            newProgressNode.fillColor = .systemBlue
            newProgressNode.strokeColor = .clear
            
            progressNode.addChild(newProgressNode)
        }
    }
