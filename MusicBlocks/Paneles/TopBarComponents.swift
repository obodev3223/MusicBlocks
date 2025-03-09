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

// MARK: - Iconos
enum ObjectiveIcon {
    case score
    case totalNotes
    case accuracy
    case blocks
    case time
    
    var symbol: String {
        switch self {
        case .score: return "🏆"
        case .totalNotes: return "🎵"
        case .accuracy: return "🎯"
        case .blocks: return "🟦"
        case .time: return "⏱"
        }
    }
}

class ObjectiveIconNode: SKNode {
    private let icon: SKLabelNode
    private let value: SKLabelNode
    
    init(type: ObjectiveIcon) {
        icon = SKLabelNode(text: type.symbol)
        value = SKLabelNode(fontNamed: "Helvetica")
        
        super.init()
        
        icon.fontSize = TopBarLayout.fontSize
        icon.verticalAlignmentMode = .center
        
        value.fontSize = TopBarLayout.smallFontSize
        value.fontColor = .darkGray
        value.verticalAlignmentMode = .center
        value.position = CGPoint(x: icon.frame.maxX + TopBarLayout.padding, y: 0)
        
        addChild(icon)
        addChild(value)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateValue(_ newValue: String) {
        value.text = newValue
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
    private var objectiveIconNode: ObjectiveIconNode?
    private var timeIconNode: ObjectiveIconNode?
    
    init(size: CGSize, objectiveTracker: LevelObjectiveTracker) {
        self.objectiveTracker = objectiveTracker
        super.init(size: size)
        setupPanel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupPanel() {
        guard let objective = objectiveTracker?.getPrimaryObjective() else { return }
        
        // Crear y configurar el icono del objetivo según el tipo
        let iconType: ObjectiveIcon = getObjectiveIconType(for: objective.type)
        objectiveIconNode = ObjectiveIconNode(type: iconType)
        if let objIcon = objectiveIconNode {
            objIcon.position = CGPoint(x: TopBarLayout.padding, y: 10)
            addChild(objIcon)
        }
        
        // Crear y configurar el icono de tiempo
        timeIconNode = ObjectiveIconNode(type: .time)
        if let timeIcon = timeIconNode {
            timeIcon.position = CGPoint(x: TopBarLayout.padding, y: -10)
            addChild(timeIcon)
        }
    }
    
    private func getObjectiveIconType(for objectiveType: String) -> ObjectiveIcon {
        switch objectiveType {
        case "score": return .score
        case "total_notes": return .totalNotes
        case "note_accuracy": return .accuracy
        case "block_destruction", "total_blocks": return .blocks
        default: return .score
        }
    }
    
    func updateInfo(with progress: ObjectiveProgress) {
        guard let objective = objectiveTracker?.getPrimaryObjective() else { return }
        
        // Actualizar el valor del objetivo
        switch objective.type {
        case "score":
            objectiveIconNode?.updateValue("\(progress.score)/\(objective.target ?? 0)")
        case "total_notes":
            objectiveIconNode?.updateValue("\(progress.notesHit)/\(objective.target ?? 0)")
        case "note_accuracy":
            let accuracy = Int(progress.averageAccuracy * 100)
            objectiveIconNode?.updateValue("\(accuracy)%")
        case "block_destruction", "total_blocks":
            objectiveIconNode?.updateValue("\(progress.totalBlocksDestroyed)/\(objective.target ?? 0)")
        default:
            break
        }
        
        // Actualizar el tiempo
        if let timeLimit = objective.timeLimit {
            let timeLimitInterval = TimeInterval(timeLimit)
            let remainingTime = max(timeLimitInterval - progress.timeElapsed, 0)
            let minutes = Int(remainingTime) / 60
            let seconds = Int(remainingTime) % 60
            timeIconNode?.updateValue(String(format: "%02d:%02d", minutes, seconds))
        } else {
            timeIconNode?.updateValue("∞")
        }
    }
}
    // MARK: - Fábrica de Paneles
    class ObjectivePanelFactory {
        static func createPanel(for objective: Objective, size: CGSize, tracker: LevelObjectiveTracker) -> ObjectiveInfoPanel {
            return ObjectiveInfoPanel(size: size, objectiveTracker: tracker)
        }
    }
