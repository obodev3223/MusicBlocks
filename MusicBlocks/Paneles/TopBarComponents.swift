//
//  TopBarComponents.swift
//  MusicBlocks
//
//  Created by Jose R. García on 9/3/25.
//

import SpriteKit
import UIKit
import Foundation

// MARK: - Constantes y Configuración
private enum TopBarLayout {
    static let cornerRadius: CGFloat = 15
    static let padding: CGFloat = 18
    static let iconTextSpacing: CGFloat = 16      // Reducido para mejor ajuste
    static let fontSize: CGFloat = 14
    static let titleFontSize: CGFloat = 16
    static let smallFontSize: CGFloat = 12
    static let verticalSpacing: CGFloat = 8       // Aumentado para mejor separación
    static let horizontalSpacing: CGFloat = 8
    static let panelHeight: CGFloat = 60
    /// Tamaño máximo para la dimensión más larga del icono.
    static let iconSize: CGFloat = 18
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
    
    var imageName: String {
        switch self {
        case .score: return "coin_icon"
        case .totalNotes: return "note_icon"
        case .accuracy: return "target_icon"
        case .blocks: return "defaultBlock_icon"
        case .time: return "timer_icon"
        }
    }
}

// MARK: - Bloque extra: mapeo de estilo -> icono
private let blockStyleIcons: [String: String] = [
    "defaultBlock": "defaultBlock_icon",
    "iceBlock": "iceBlock_icon",
    "hardiceBlock": "hardiceBlock_icon",
    "ghostBlock": "ghostBlock_icon",
    "changingBlock": "changingBlock_icon",
    "explosiveBlock": "explosiveBlock_icon",
]

// MARK: - ObjectiveIconNode
class ObjectiveIconNode: SKNode {
    private let icon: SKSpriteNode
    private let value: SKLabelNode
    
    init(type: ObjectiveIcon) {
        // Cargamos la textura
        let iconTexture = SKTexture(imageNamed: type.imageName)
        
        // Mantener relación de aspecto
        let originalSize = iconTexture.size()
        let w = originalSize.width
        let h = originalSize.height
        
        // Ratio para ajustar la dimensión más larga a 'iconSize'
        let maxDim: CGFloat = TopBarLayout.iconSize
        let scale = max(w, h) > 0 ? (maxDim / max(w, h)) : 1.0
        
        let finalWidth = w * scale
        let finalHeight = h * scale
        
        icon = SKSpriteNode(texture: iconTexture)
        icon.size = CGSize(width: finalWidth, height: finalHeight)
        
        value = SKLabelNode(fontNamed: "Helvetica")
        
        super.init()
        
        // Posicionamos el icono y la etiqueta
        icon.position = CGPoint(x: -TopBarLayout.iconTextSpacing/2, y: 0)
        
        value.fontSize = TopBarLayout.smallFontSize
        value.fontColor = .darkGray
        value.verticalAlignmentMode = .center
        value.horizontalAlignmentMode = .left
        value.position = CGPoint(x: icon.position.x + TopBarLayout.iconTextSpacing, y: 0)
        
        addChild(icon)
        addChild(value)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateValueColor(_ color: SKColor) {
        value.fontColor = color
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
    
    func setupBackground() {
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
    private let timeIcon: SKSpriteNode
    private let timeLabel: SKLabelNode
    private let timeLimit: TimeInterval
    private let startTime: Date
    
    init(timeLimit: TimeInterval) {
        // Crear icono de tiempo
        let iconTexture = SKTexture(imageNamed: "timer_icon")
        timeIcon = SKSpriteNode(texture: iconTexture)
        
        // Mantener la relación de aspecto para el icono del tiempo, si lo deseas
        let originalSize = iconTexture.size()
        let w = originalSize.width
        let h = originalSize.height
        let maxDim: CGFloat = TopBarLayout.iconSize
        let scale = max(w, h) > 0 ? (maxDim / max(w, h)) : 1.0
        
        timeIcon.size = CGSize(width: w * scale, height: h * scale)
        
        self.timeLabel = SKLabelNode(fontNamed: "Helvetica")
        self.timeLimit = timeLimit
        self.startTime = Date()
        
        super.init()
        
        setupTimeComponents()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTimeComponents() {
        // Posición del icono
        timeIcon.position = CGPoint(x: -TopBarLayout.iconTextSpacing/2, y: 0)
        addChild(timeIcon)
        
        // Configuración de la etiqueta
        timeLabel.fontSize = TopBarLayout.fontSize
        timeLabel.fontColor = .darkGray
        timeLabel.verticalAlignmentMode = .center
        timeLabel.horizontalAlignmentMode = .left
        timeLabel.position = CGPoint(x: timeIcon.position.x + TopBarLayout.iconTextSpacing, y: 0)
        addChild(timeLabel)
        
        // Actualizar el tiempo inicial
        update()
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
    
    // Icono único para “score”, “time”, etc.
    private var objectiveIconNode: ObjectiveIconNode?
    private var timeIconNode: ObjectiveIconNode?
    
    // Lista de iconos por estilo de bloque
    private var blockIcons: [String: ObjectiveIconNode] = [:]
    
    init(size: CGSize, objectiveTracker: LevelObjectiveTracker) {
        self.objectiveTracker = objectiveTracker
        super.init(size: size)
        setupPanel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupBackground() {
        // No crear fondo blanco para el panel de objetivos
    }
    
    func setupPanel() {
        guard let objective = objectiveTracker?.getPrimaryObjective() else { return }
        
        let contentContainer = SKNode()
        contentContainer.position = CGPoint(x: TopBarLayout.padding, y: 0)
        addChild(contentContainer)
        
        switch objective.type {
        case "block_destruction":
            // Si el objetivo tiene detalles con estilos y cantidades
            if let details = objective.details {
                var offsetY: CGFloat = 0
                
                for (blockType, _) in details {
                    let iconNode = createBlockIconNode(for: blockType)
                    iconNode.position = CGPoint(x: 0, y: offsetY)
                    offsetY -= (TopBarLayout.iconSize + 10)
                    contentContainer.addChild(iconNode)
                    
                    blockIcons[blockType] = iconNode
                }
            }
            // Si además hay límite de tiempo
            if objective.timeLimit != nil {
                timeIconNode = ObjectiveIconNode(type: .time)
                if let timeIcon = timeIconNode {
                    timeIcon.position = CGPoint(x: 0, y: -120)
                    contentContainer.addChild(timeIcon)
                }
            }
            
        default:
            let iconType: ObjectiveIcon = getObjectiveIconType(for: objective.type)
            objectiveIconNode = ObjectiveIconNode(type: iconType)
            if let objIcon = objectiveIconNode {
                objIcon.position = CGPoint(x: 0, y: TopBarLayout.verticalSpacing * 2)
                contentContainer.addChild(objIcon)
            }
            
            timeIconNode = ObjectiveIconNode(type: .time)
            if let timeIcon = timeIconNode {
                timeIcon.position = CGPoint(x: 0, y: -TopBarLayout.verticalSpacing * 2)
                contentContainer.addChild(timeIcon)
            }
        }
    }
    
    private func createBlockIconNode(for blockType: String) -> ObjectiveIconNode {
        let imageName = blockStyleIcons[blockType] ?? "default_block_icon"
        let iconTexture = SKTexture(imageNamed: imageName)
        
        // Mantener la relación de aspecto
        let originalSize = iconTexture.size()
        let w = originalSize.width
        let h = originalSize.height
        let maxDim: CGFloat = TopBarLayout.iconSize
        let scale = max(w, h) > 0 ? (maxDim / max(w, h)) : 1.0
        
        let finalWidth = w * scale
        let finalHeight = h * scale
        
        // Creamos un icono .blocks
        let node = ObjectiveIconNode(type: .blocks)
        
        // Reemplazamos textura y tamaño del SKSpriteNode “existingIcon”
        if let existingIcon = node.children.first as? SKSpriteNode {
            existingIcon.texture = iconTexture
            existingIcon.size = CGSize(width: finalWidth, height: finalHeight)
        }
        
        return node
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
        
        switch objective.type {
        case "block_destruction":
            if let details = objective.details {
                for (blockType, required) in details {
                    let destroyed = progress.blocksByType[blockType, default: 0]
                    if let iconNode = blockIcons[blockType] {
                        let text = "\(destroyed)/\(required)"
                        iconNode.updateValue(text)
                    }
                }
            }
            if let timeLimit = objective.timeLimit {
                updateTimeIcon(progress: progress, timeLimit: timeLimit)
            } else {
                timeIconNode?.updateValue("∞")
            }
            
        default:
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
            
            if let timeLimit = objective.timeLimit {
                updateTimeIcon(progress: progress, timeLimit: timeLimit)
            } else {
                timeIconNode?.updateValue("∞")
            }
        }
    }
    
    private func updateTimeIcon(progress: ObjectiveProgress, timeLimit: Int) {
        let timeLimitInterval = TimeInterval(timeLimit)
        let remainingTime = max(timeLimitInterval - progress.timeElapsed, 0)
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        let timeText = String(format: "%02d:%02d", minutes, seconds)
        
        timeIconNode?.updateValue(timeText)
        
        if remainingTime < 30 {
            timeIconNode?.updateValueColor(.red)
        } else {
            timeIconNode?.updateValueColor(.darkGray)
        }
    }
}

// MARK: - Fábrica de Paneles
class ObjectivePanelFactory {
    static func createPanel(for objective: Objective, size: CGSize, tracker: LevelObjectiveTracker) -> ObjectiveInfoPanel {
        return ObjectiveInfoPanel(size: size, objectiveTracker: tracker)
    }
}

// MARK: - Preview
#if DEBUG
import SwiftUI

/// Vista previa que muestra varios ObjectiveInfoPanel en una misma escena
struct ObjectivePanelsPreview: PreviewProvider {
    static var previews: some View {
        ObjectivePanelsPreviewContainer()
            .frame(width: 600, height: 300)
            .previewDisplayName("Todos los tipos de Objetivos")
    }
}

struct ObjectivePanelsPreviewContainer: View {
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createPreviewScene(size: geometry.size))
                .background(Color.gray.opacity(0.2))
        }
    }
    
    private func createPreviewScene(size: CGSize) -> SKScene {
        let scene = SKScene(size: size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .lightGray
        
        let panelSpacing: CGFloat = 10
        let objectiveTypes: [String] = [
            "score",
            "total_notes",
            "note_accuracy",
            "block_destruction",
            "total_blocks"
        ]
        
        let totalPanels = CGFloat(objectiveTypes.count)
        let panelWidth = (size.width - (panelSpacing * (totalPanels + 1))) / totalPanels
        let panelHeight: CGFloat = min(size.height * 0.8, 100)
        
        var currentX = panelSpacing
        
        for (index, type) in objectiveTypes.enumerated() {
            var objectiveDetails: [String: Int]? = nil
            var allowedStyles: [String] = []
            var blocksDestroyed: [String: Int] = [:]
            
            if type == "block_destruction" {
                objectiveDetails = ["defaultBlock": 5, "iceBlock": 3, "hardiceBlock": 7]
                allowedStyles = ["defaultBlock", "iceBlock", "hardiceBlock"]
                blocksDestroyed = ["defaultBlock": 2, "iceBlock": 3, "hardiceBlock": 5]
            }
            
            let objective = Objective(
                type: type,
                target: 1000,
                timeLimit: 180,
                minimumAccuracy: nil,
                details: objectiveDetails
            )
            
            let level = GameLevel(
                levelId: index + 1,
                name: "Nivel de prueba",
                maxScore: 500,
                allowedStyles: allowedStyles,
                fallingSpeed: FallingSpeed(initial: 8.0, increment: 0.0),
                lives: Lives(
                    initial: 3,
                    extraLives: ExtraLives(scoreThresholds: [], maxExtra: 0)
                ),
                objectives: Objectives(primary: objective),
                blocks: [:]
            )
            
            let tracker = LevelObjectiveTracker(level: level)
            var progress = ObjectiveProgress(
                score: 350,
                notesHit: 40,
                accuracySum: 0.9,
                accuracyCount: 1,
                blocksByType: blocksDestroyed,
                totalBlocksDestroyed: blocksDestroyed.values.reduce(0, +),
                timeElapsed: 60
            )
            
            let panelSize = CGSize(width: panelWidth, height: panelHeight)
            let panel = ObjectivePanelFactory.createPanel(for: objective, size: panelSize, tracker: tracker)
            panel.updateInfo(with: progress)
            
            panel.position = CGPoint(x: currentX + panelWidth/2, y: size.height/2)
            scene.addChild(panel)
            
            currentX += (panelWidth + panelSpacing)
        }
        
        return scene
    }
}
#endif
