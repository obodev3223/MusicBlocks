//
//  TopBarComponents.swift
//  MusicBlocks
//
//  Created by Jose R. García on 9/3/25.
//

import SpriteKit
import UIKit

// MARK: - Constantes y Configuración
private enum TopBarLayout {
    static let cornerRadius: CGFloat = 15
    static let padding: CGFloat = 10
    static let fontSize: CGFloat = 16
    static let titleFontSize: CGFloat = 20
    static let smallFontSize: CGFloat = 14
    static let verticalSpacing: CGFloat = 8
    static let horizontalSpacing: CGFloat = 15
    static let panelHeight: CGFloat = 60
}

// MARK: - Estructuras de Datos
struct ObjectiveProgress {
    var score: Int = 0
    var notesHit: Int = 0
    var accuracySum: Double = 0
    var accuracyCount: Int = 0
    var blocksByType: [String: Int] = [:]
    var totalBlocksDestroyed: Int = 0
    var timeElapsed: TimeInterval = 0
    
    var averageAccuracy: Double {
        return accuracyCount > 0 ? accuracySum / Double(accuracyCount) : 0
    }
}

// MARK: - Nodos Base
class TopBarBaseNode: SKNode {
    var size: CGSize
    
    init(size: CGSize) {
        self.size = size
        super.init()
        setupBackground()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBackground() {
        let background = SKShapeNode(rectOf: size, cornerRadius: TopBarLayout.cornerRadius)
        background.fillColor = .white
        background.strokeColor = .clear
        background.alpha = 0.95
        addChild(background)
    }
    
    func createLabel(_ text: String, fontSize: CGFloat = TopBarLayout.fontSize) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Helvetica")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = .darkGray
        return label
    }
}

// MARK: - Componente de Tiempo
class TimeDisplayNode: SKNode {
    private let timeLabel: SKLabelNode
    private let timeLimit: TimeInterval
    private let startTime: Date
    
    init(timeLimit: TimeInterval) {
        self.timeLabel = SKLabelNode(fontNamed: "Helvetica")
        self.timeLimit = timeLimit
        self.startTime = Date()
        super.init()
        setupTimeLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTimeLabel() {
        timeLabel.fontSize = TopBarLayout.fontSize
        timeLabel.fontColor = .darkGray
        addChild(timeLabel)
    }
    
    func update() {
        if timeLimit == 0 {
            timeLabel.text = "∞"
            return
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let remainingTime = max(timeLimit - elapsedTime, 0)
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
        timeLabel.fontColor = remainingTime < 30 ? .red : .darkGray
    }
}

// MARK: - Panel Base de Objetivos
class ObjectiveInfoPanel: TopBarBaseNode {
    weak var objectiveTracker: LevelObjectiveTracker?
    
    init(size: CGSize, objectiveTracker: LevelObjectiveTracker) {
        self.objectiveTracker = objectiveTracker
        super.init(size: size)
        setupPanel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupPanel() {
        // Las subclases deben implementar esto
    }
    
    func updateInfo(with progress: ObjectiveProgress) {
        // Las subclases deben implementar esto
    }
}

// MARK: - Panel de Puntuación
class ScoreObjectivePanel: ObjectiveInfoPanel {
    private var scoreLabel: SKLabelNode!
    private var targetLabel: SKLabelNode!
    private var timeDisplay: TimeDisplayNode!
    
    override func setupPanel() {
        guard let objective = objectiveTracker?.getPrimaryObjective() else { return }
        
        scoreLabel = createLabel("Puntuación: 0")
        scoreLabel.position = CGPoint(x: 0, y: 10)
        
        targetLabel = createLabel("Objetivo: \(objective.target ?? 0)")
        targetLabel.position = CGPoint(x: 0, y: -10)
        
        timeDisplay = TimeDisplayNode(timeLimit: TimeInterval(objective.timeLimit ?? 0))
        timeDisplay.position = CGPoint(x: size.width - 60, y: 0)
        
        addChild(scoreLabel)
        addChild(targetLabel)
        addChild(timeDisplay)
    }
    
    override func updateInfo(with progress: ObjectiveProgress) {
        scoreLabel.text = "Puntuación: \(progress.score)"
        timeDisplay.update()
    }
}

// MARK: - Panel de Notas Totales
class TotalNotesPanel: ObjectiveInfoPanel {
    private var notesLabel: SKLabelNode!
    private var timeDisplay: TimeDisplayNode!
    
    override func setupPanel() {
        guard let objective = objectiveTracker?.getPrimaryObjective() else { return }
        
        notesLabel = createLabel("Notas: 0/\(objective.target ?? 0)")
        notesLabel.position = CGPoint(x: 0, y: 0)
        
        timeDisplay = TimeDisplayNode(timeLimit: TimeInterval(objective.timeLimit ?? 0))
        timeDisplay.position = CGPoint(x: size.width - 60, y: 0)
        
        addChild(notesLabel)
        addChild(timeDisplay)
    }
    
    override func updateInfo(with progress: ObjectiveProgress) {
        if let target = objectiveTracker?.getPrimaryObjective().target {
            notesLabel.text = "Notas: \(progress.notesHit)/\(target)"
        }
        timeDisplay.update()
    }
}

// MARK: - Panel de Precisión de Notas
class NoteAccuracyPanel: ObjectiveInfoPanel {
    private var notesLabel: SKLabelNode!
    private var accuracyLabel: SKLabelNode!
    private var timeDisplay: TimeDisplayNode!
    
    override func setupPanel() {
        guard let objective = objectiveTracker?.getPrimaryObjective() else { return }
        
        notesLabel = createLabel("Notas: 0/\(objective.target ?? 0)")
        notesLabel.position = CGPoint(x: 0, y: 10)
        
        let minAccuracy = Int((objective.minimumAccuracy ?? 0) * 100)
        accuracyLabel = createLabel("Precisión mínima: \(minAccuracy)%")
        accuracyLabel.position = CGPoint(x: 0, y: -10)
        
        timeDisplay = TimeDisplayNode(timeLimit: TimeInterval(objective.timeLimit ?? 0))
        timeDisplay.position = CGPoint(x: size.width - 60, y: 0)
        
        addChild(notesLabel)
        addChild(accuracyLabel)
        addChild(timeDisplay)
    }
    
    override func updateInfo(with progress: ObjectiveProgress) {
        if let target = objectiveTracker?.getPrimaryObjective().target {
            notesLabel.text = "Notas: \(progress.notesHit)/\(target)"
            accuracyLabel.text = String(format: "Precisión actual: %.1f%%", progress.averageAccuracy * 100)
        }
        timeDisplay.update()
    }
}

// MARK: - Panel de Destrucción de Bloques
class BlockDestructionPanel: ObjectiveInfoPanel {
    private var blockLabels: [String: SKLabelNode] = [:]
    private var timeDisplay: TimeDisplayNode!
    
    override func setupPanel() {
        guard let objective = objectiveTracker?.getPrimaryObjective() else { return }
        
        var yPos: CGFloat = CGFloat(objective.details?.count ?? 0) * 10
        objective.details?.forEach { (blockType, target) in
            let label = createLabel("\(blockType): 0/\(target)")
            label.position = CGPoint(x: 0, y: yPos)
            blockLabels[blockType] = label
            addChild(label)
            yPos -= 20
        }
        
        timeDisplay = TimeDisplayNode(timeLimit: TimeInterval(objective.timeLimit ?? 0))
        timeDisplay.position = CGPoint(x: size.width - 60, y: 0)
        addChild(timeDisplay)
    }
    
    override func updateInfo(with progress: ObjectiveProgress) {
        progress.blocksByType.forEach { (blockType, count) in
            if let target = objectiveTracker?.getPrimaryObjective().details?[blockType] {
                blockLabels[blockType]?.text = "\(blockType): \(count)/\(target)"
            }
        }
        timeDisplay.update()
    }
}

// MARK: - Panel de Bloques Totales
class TotalBlocksPanel: ObjectiveInfoPanel {
    private var blocksLabel: SKLabelNode!
    private var timeDisplay: TimeDisplayNode!
    
    override func setupPanel() {
        guard let objective = objectiveTracker?.getPrimaryObjective() else { return }
        
        blocksLabel = createLabel("Bloques: 0/\(objective.target ?? 0)")
        blocksLabel.position = CGPoint(x: 0, y: 0)
        
        timeDisplay = TimeDisplayNode(timeLimit: TimeInterval(objective.timeLimit ?? 0))
        timeDisplay.position = CGPoint(x: size.width - 60, y: 0)
        
        addChild(blocksLabel)
        addChild(timeDisplay)
    }
    
    override func updateInfo(with progress: ObjectiveProgress) {
        if let target = objectiveTracker?.getPrimaryObjective().target {
            blocksLabel.text = "Bloques: \(progress.totalBlocksDestroyed)/\(target)"
        }
        timeDisplay.update()
    }
}

// MARK: - Fábrica de Paneles
class ObjectivePanelFactory {
    static func createPanel(for objective: Objective, size: CGSize, tracker: LevelObjectiveTracker) -> ObjectiveInfoPanel {
        switch objective.type {
        case "score":
            return ScoreObjectivePanel(size: size, objectiveTracker: tracker)
        case "total_notes":
            return TotalNotesPanel(size: size, objectiveTracker: tracker)
        case "note_accuracy":
            return NoteAccuracyPanel(size: size, objectiveTracker: tracker)
        case "block_destruction":
            return BlockDestructionPanel(size: size, objectiveTracker: tracker)
        case "total_blocks":
            return TotalBlocksPanel(size: size, objectiveTracker: tracker)
        default:
            fatalError("Tipo de objetivo no soportado: \(objective.type)")
        }
    }
}
