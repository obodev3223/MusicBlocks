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
    static let iconTextSpacing: CGFloat = 24      // Aumentado el espacio entre icono y texto
    static let fontSize: CGFloat = 14
    static let titleFontSize: CGFloat = 16
    static let smallFontSize: CGFloat = 12
    static let verticalSpacing: CGFloat = 4
    static let horizontalSpacing: CGFloat = 8
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
        // Cambiamos la alineación horizontal a .center
        icon.horizontalAlignmentMode = .center
        icon.position = CGPoint(x: -TopBarLayout.iconTextSpacing/2, y: 0)
        
        value.fontSize = TopBarLayout.smallFontSize
        value.fontColor = .darkGray
        value.verticalAlignmentMode = .center
        // Cambiamos la alineación horizontal a .left
        value.horizontalAlignmentMode = .left
        // Posicionamos el valor a la derecha del icono
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
        // Eliminamos la creación del fondo blanco
        guard let objective = objectiveTracker?.getPrimaryObjective() else { return }
        
        let iconType: ObjectiveIcon = getObjectiveIconType(for: objective.type)
        objectiveIconNode = ObjectiveIconNode(type: iconType)
        if let objIcon = objectiveIconNode {
            // Centrar el icono horizontalmente en el contenedor
            objIcon.position = CGPoint(x: 0, y: TopBarLayout.padding/2)
            addChild(objIcon)
        }
        
        timeIconNode = ObjectiveIconNode(type: .time)
        if let timeIcon = timeIconNode {
            // Centrar el icono horizontalmente en el contenedor
            timeIcon.position = CGPoint(x: 0, y: -TopBarLayout.padding/2)
            addChild(timeIcon)
        }
    }
    
    override func setupBackground() {
        // No crear fondo blanco para el panel de objetivos
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
        
        // Actualizar el tiempo - mostrando siempre el tiempo restante
        if let timeLimit = objective.timeLimit {
            let timeLimitInterval = TimeInterval(timeLimit)
            let remainingTime = max(timeLimitInterval - progress.timeElapsed, 0)
            let minutes = Int(remainingTime) / 60
            let seconds = Int(remainingTime) % 60
            timeIconNode?.updateValue(String(format: "%02d:%02d", minutes, seconds))
            
            // Ya que no podemos acceder directamente a fontColor, vamos a crear un método en ObjectiveIconNode
            if remainingTime < 30 {
                // En lugar de esto que no funciona:
                // timeIconNode?.value.fontColor = .red
                timeIconNode?.updateValueColor(SKColor.red)
            } else {
                timeIconNode?.updateValueColor(SKColor.darkGray)
            }
        } else {
            timeIconNode?.updateValue("∞")
            timeIconNode?.updateValueColor(SKColor.darkGray)
        }
    }
}
// MARK: - Fábrica de Paneles
class ObjectivePanelFactory {
    static func createPanel(for objective: Objective, size: CGSize, tracker: LevelObjectiveTracker) -> ObjectiveInfoPanel {
        return ObjectiveInfoPanel(size: size, objectiveTracker: tracker)
    }
}


#if DEBUG
import SwiftUI

// MARK: - Previews
struct TopBarComponentsPreview: PreviewProvider {
    static var previews: some View {
        TopBarComponentsPreviewScene()
    }
}

struct TopBarComponentsPreviewScene: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)
                
                SpriteView(scene: createPreviewScene(size: geometry.size))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .previewDisplayName("TopBars Layout")
    }
    
    private func createPreviewScene(size: CGSize) -> SKScene {
        let scene = SKScene(size: size)
        scene.backgroundColor = .clear
        
        // Crear nivel de ejemplo
        let level = GameLevel(
            levelId: 1,
            name: "Nivel de prueba",
            allowedStyles: ["default"],
            fallingSpeed: FallingSpeed(initial: 8.0, increment: 0.0),
            lives: Lives(
                initial: 3,
                extraLives: ExtraLives(
                    scoreThresholds: [500, 1000],
                    maxExtra: 2
                )
            ),
            objectives: Objectives(
                primary: Objective(
                    type: "score",
                    target: 1000,
                    timeLimit: 180,
                    minimumAccuracy: nil,
                    details: nil
                )
            ),
            blocks: [:]
        )
        
        let mockObjectiveTracker = LevelObjectiveTracker(level: level)
        
        // Configurar las dimensiones según el nuevo layout
        let safeWidth = size.width - 16 // 8 pts de margen en cada lado
        let topBarWidth = safeWidth * 0.47 // 47% del ancho disponible
        let topBarHeight: CGFloat = 60
        let yPosition = size.height - topBarHeight/2 - 6 // 6 pts desde arriba
        
        // Crear TopBar izquierda (principal)
        let leftBar = TopBar.create(
            width: topBarWidth,
            height: topBarHeight,
            position: CGPoint(x: 8 + topBarWidth/2, y: yPosition),
            type: .main
        )
        
        // Crear TopBar derecha (objetivos)
        let rightBar = TopBar.create(
            width: topBarWidth,
            height: topBarHeight,
            position: CGPoint(x: size.width - 8 - topBarWidth/2, y: yPosition),
            type: .objectives
        )
        
        // Configurar ambas barras
        leftBar.configure(withLevel: level, objectiveTracker: mockObjectiveTracker)
        rightBar.configure(withLevel: level, objectiveTracker: mockObjectiveTracker)
        
        // Simular algunos datos
        leftBar.updateScore(500)
        leftBar.updateLives(2)
        
        // Actualizar el panel de objetivos
        let progress = ObjectiveProgress(
            score: 500,
            notesHit: 25,
            accuracySum: 85.0,
            accuracyCount: 1,
            totalBlocksDestroyed: 25,
            timeElapsed: 60
        )
        
        // Usar el método público
        rightBar.updateObjectiveInfo(with: progress)
        
        // Añadir barras a la escena
        scene.addChild(leftBar)
        scene.addChild(rightBar)
        
        // Añadir líneas guía para visualizar los márgenes (solo en preview)
        addGuideLines(to: scene, size: size)
        
        return scene
    }
    
    private func addGuideLines(to scene: SKScene, size: CGSize) {
        // Líneas verticales para mostrar los márgenes
        let leftMargin = SKShapeNode(rectOf: CGSize(width: 1, height: size.height))
        leftMargin.position = CGPoint(x: 8, y: size.height/2)
        leftMargin.fillColor = .red
        leftMargin.alpha = 0.3
        scene.addChild(leftMargin)
        
        let rightMargin = SKShapeNode(rectOf: CGSize(width: 1, height: size.height))
        rightMargin.position = CGPoint(x: size.width - 8, y: size.height/2)
        rightMargin.fillColor = .red
        rightMargin.alpha = 0.3
        scene.addChild(rightMargin)
        
        // Línea central para mostrar la separación
        let centerLine = SKShapeNode(rectOf: CGSize(width: 1, height: size.height))
        centerLine.position = CGPoint(x: size.width/2, y: size.height/2)
        centerLine.fillColor = .red
        centerLine.alpha = 0.3
        scene.addChild(centerLine)
    }
}

// Vista previa adicional con diferentes tamaños de pantalla
struct TopBarComponentsPreview_MultipleDevices: PreviewProvider {
    static var previews: some View {
        Group {
            TopBarComponentsPreviewScene()
                .previewDevice("iPhone 14")
                .previewDisplayName("iPhone 14")
            
            TopBarComponentsPreviewScene()
                .previewDevice("iPhone 14 Pro Max")
                .previewDisplayName("iPhone 14 Pro Max")
            
            TopBarComponentsPreviewScene()
                .previewDevice("iPad Pro (11-inch)")
                .previewDisplayName("iPad Pro 11\"")
        }
    }
}
#endif
