//
//  TopBarComponents.swift
//  MusicBlocks
//
//  Created by Jose R. García on 14/3/25.
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
    
    // Valores para layout de columnas en block_destruction
    static let columnWidth: CGFloat = 80          // Ancho de cada columna
    static let rowSpacing: CGFloat = 20           // Espacio vertical entre filas
    static let maxItemsPerColumn: Int = 2         // Máximo de items por columna
    static let maxColumns: Int = 4                // Aumentado a 4 columnas máximo
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
    
    // Icono único para "score", "time", etc.
    private var objectiveIconNode: ObjectiveIconNode?
    private var timeIconNode: ObjectiveIconNode?
    
    // Lista de iconos por estilo de bloque
    private var blockIcons: [String: ObjectiveIconNode] = [:]
    
    // Contenedor para el objetivo "block_destruction"
    private var blockDestructionContainer: SKNode?
    
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
        case "note_accuracy":
            // Para note_accuracy creamos un contenedor especial para los tres parámetros
            let noteAccuracyContainer = SKNode()
            contentContainer.addChild(noteAccuracyContainer)
            blockDestructionContainer = noteAccuracyContainer
            
            // No creamos los iconos tradicionales, todo se manejará en updateInfo
            
        case "block_destruction":
            // Para block_destruction, creamos un contenedor especial que organizará los bloques en columnas
            let container = SKNode()
            contentContainer.addChild(container)
            blockDestructionContainer = container
            
        case "total_blocks":
            // Para total_blocks, solo mostramos el total y opcionalmente el tiempo
            objectiveIconNode = ObjectiveIconNode(type: .blocks)
            if let objIcon = objectiveIconNode {
                objIcon.position = CGPoint(x: 0, y: TopBarLayout.verticalSpacing * 2)
                contentContainer.addChild(objIcon)
            }
            
            // Si hay límite de tiempo
            if objective.timeLimit != nil {
                timeIconNode = ObjectiveIconNode(type: .time)
                if let timeIcon = timeIconNode {
                    timeIcon.position = CGPoint(x: 0, y: -TopBarLayout.verticalSpacing * 2)
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
        
        // Reemplazamos textura y tamaño del SKSpriteNode "existingIcon"
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
        
        // Solo actualizamos el timeIcon en tipos que no sean note_accuracy o block_destruction
        // ya que estos manejan su propio tiempo como parte de sus parámetros
        if objective.type != "note_accuracy" && objective.type != "block_destruction" {
            if let timeLimit = objective.timeLimit {
                updateTimeIcon(progress: progress, timeLimit: timeLimit)
            } else {
                timeIconNode?.updateValue("∞")
            }
        }
        
        // Actualizar según el tipo de objetivo
        switch objective.type {
        case "block_destruction":
            if let details = objective.details {
                updateBlockDestructionLayout(with: progress, details: details)
            }
            
        case "note_accuracy":
            updateNoteAccuracyLayout(with: progress, objective: objective)
            
        case "score":
            objectiveIconNode?.updateValue("\(progress.score)/\(objective.target ?? 0)")
            
        case "total_notes":
            objectiveIconNode?.updateValue("\(progress.notesHit)/\(objective.target ?? 0)")
            
        case "total_blocks":
            objectiveIconNode?.updateValue("\(progress.totalBlocksDestroyed)/\(objective.target ?? 0)")
            
        default:
            break
        }
    }

    private func updateNoteAccuracyLayout(with progress: ObjectiveProgress, objective: Objective) {
        // Limpiar contenedor
        blockDestructionContainer?.removeAllChildren()
        guard let container = blockDestructionContainer else { return }
        
        // Usamos las constantes globales para mantener consistencia con todos los demás objetivos
        let iconSize: CGFloat = TopBarLayout.iconSize
        let rowHeight: CGFloat = TopBarLayout.rowSpacing
        let fontSize: CGFloat = TopBarLayout.fontSize
        let iconOffset: CGFloat = TopBarLayout.horizontalSpacing
        let columnSeparation: CGFloat = 60  // Separación entre columnas
        
        // COLUMNA 1: Notas y Precisión
        
        // 1. Notas acertadas/objetivo (fila superior)
        let notesIcon = SKSpriteNode(imageNamed: "note_icon")
        notesIcon.size = CGSize(width: iconSize, height: iconSize)
        notesIcon.position = CGPoint(x: -columnSeparation/2 - iconOffset, y: rowHeight/2)
        container.addChild(notesIcon)
        
        let notesLabel = SKLabelNode(fontNamed: "Helvetica")
        notesLabel.fontSize = fontSize
        notesLabel.fontColor = .darkGray
        notesLabel.text = "\(progress.notesHit)/\(objective.target ?? 0)"
        notesLabel.horizontalAlignmentMode = .left
        notesLabel.verticalAlignmentMode = .center
        notesLabel.position = CGPoint(x: -columnSeparation/2 + iconSize/2, y: rowHeight/2)
        container.addChild(notesLabel)
        
        // 2. Precisión (fila inferior)
        let accuracyIcon = SKSpriteNode(imageNamed: "target_icon")
        accuracyIcon.size = CGSize(width: iconSize, height: iconSize)
        accuracyIcon.position = CGPoint(x: -columnSeparation/2 - iconOffset, y: -rowHeight/2)
        container.addChild(accuracyIcon)
        
        let accuracyPercentage = Int(progress.averageAccuracy * 100)
        let minAccuracyPercentage = Int((objective.minimumAccuracy ?? 0) * 100)
        
        let accuracyLabel = SKLabelNode(fontNamed: "Helvetica")
        accuracyLabel.fontSize = fontSize
        // Quitar los signos % para ahorrar espacio
        accuracyLabel.text = "\(accuracyPercentage)/\(minAccuracyPercentage)"
        accuracyLabel.horizontalAlignmentMode = .left
        accuracyLabel.verticalAlignmentMode = .center
        accuracyLabel.position = CGPoint(x: -columnSeparation/2 + iconSize/2, y: -rowHeight/2)
        
        // Color según precisión
        if progress.averageAccuracy < (objective.minimumAccuracy ?? 0) {
            accuracyLabel.fontColor = .red
        } else {
            accuracyLabel.fontColor = .darkGray
        }
        container.addChild(accuracyLabel)
        
        // COLUMNA 2: Tiempo - alineado con la fila superior
        
        // Mostrar el tiempo en la columna derecha, alineado con la fila superior
        if let timeLimit = objective.timeLimit {
            let timeIcon = SKSpriteNode(imageNamed: "timer_icon")
            timeIcon.size = CGSize(width: iconSize, height: iconSize)
            // Alineado con la fila superior
            timeIcon.position = CGPoint(x: columnSeparation/2 - iconOffset, y: rowHeight/2)
            container.addChild(timeIcon)
            
            let timeLimitInterval = TimeInterval(timeLimit)
            let remainingTime = max(timeLimitInterval - progress.timeElapsed, 0)
            let minutes = Int(remainingTime) / 60
            let seconds = Int(remainingTime) % 60
            
            let timeLabel = SKLabelNode(fontNamed: "Helvetica")
            timeLabel.fontSize = fontSize
            timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
            timeLabel.horizontalAlignmentMode = .left
            timeLabel.verticalAlignmentMode = .center
            // Alineado con la fila superior
            timeLabel.position = CGPoint(x: columnSeparation/2 + iconSize/2, y: rowHeight/2)
            
            // Color según tiempo restante
            if remainingTime < 30 {
                timeLabel.fontColor = .red
            } else {
                timeLabel.fontColor = .darkGray
            }
            container.addChild(timeLabel)
        } else {
            let timeIcon = SKSpriteNode(imageNamed: "timer_icon")
            timeIcon.size = CGSize(width: iconSize, height: iconSize)
            // Alineado con la fila superior
            timeIcon.position = CGPoint(x: columnSeparation/2 - iconOffset, y: rowHeight/2)
            container.addChild(timeIcon)
            
            let timeLabel = SKLabelNode(fontNamed: "Helvetica")
            timeLabel.fontSize = fontSize
            timeLabel.text = "∞"
            timeLabel.horizontalAlignmentMode = .left
            timeLabel.verticalAlignmentMode = .center
            // Alineado con la fila superior
            timeLabel.position = CGPoint(x: columnSeparation/2 + iconSize/2, y: rowHeight/2)
            timeLabel.fontColor = .darkGray
            container.addChild(timeLabel)
        }
        
        // Ajustar posición general del contenedor para centrarlo mejor
        container.position = CGPoint(x: size.width/4, y: 0)
    }
    
    // Método para actualizar el layout de block_destruction en formato de columnas
    private func updateBlockDestructionLayout(with progress: ObjectiveProgress, details: [String: Int]) {
        // Limpiar el contenedor existente si hay uno
        blockDestructionContainer?.removeAllChildren()
        guard let container = blockDestructionContainer else { return }
        
        guard let objective = objectiveTracker?.getPrimaryObjective() else { return }
        
        // Crear una lista de todos los elementos a mostrar (bloques + tiempo si hay límite)
        var displayItems: [(type: String, label: String, isTimeIcon: Bool)] = []
        
        // Añadir bloques
        for (blockType, required) in details {
            let destroyed = progress.blocksByType[blockType, default: 0]
            let text = "\(destroyed)/\(required)"
            displayItems.append((type: blockType, label: text, isTimeIcon: false))
        }
        
        // Añadir tiempo si hay límite
        if let timeLimit = objective.timeLimit {
            let timeLimitInterval = TimeInterval(timeLimit)
            let remainingTime = max(timeLimitInterval - progress.timeElapsed, 0)
            let minutes = Int(remainingTime) / 60
            let seconds = Int(remainingTime) % 60
            let timeText = String(format: "%02d:%02d", minutes, seconds)
            displayItems.append((type: "time", label: timeText, isTimeIcon: true))
        }
        
        // Calcular cuántas columnas necesitamos
        let totalItems = displayItems.count
        let columnsNeeded = min((totalItems + 1) / 2, TopBarLayout.maxColumns) // Máximo 4 columnas
        
        // Calcular posición inicial
        var startX: CGFloat = 0
        
        // Si tenemos más de una columna, alineamos desde la izquierda
        if columnsNeeded > 1 {
            startX = -((CGFloat(columnsNeeded - 1) * TopBarLayout.columnWidth) / 2)
        }
        
        var currentX = startX
        var currentY: CGFloat = TopBarLayout.rowSpacing // Primera fila
        var itemsInCurrentColumn = 0
        
        // Organizar bloques en columnas
        for (_, item) in displayItems.enumerated() {
            // Si completamos 2 items en la columna actual, pasamos a la siguiente columna
            if itemsInCurrentColumn >= TopBarLayout.maxItemsPerColumn {
                currentX += TopBarLayout.columnWidth
                currentY = TopBarLayout.rowSpacing // Volvemos a la primera fila
                itemsInCurrentColumn = 0
            }
            
            // Crear nodo para este elemento
            let iconNode: ObjectiveIconNode
            
            if item.isTimeIcon {
                iconNode = ObjectiveIconNode(type: .time)
            } else {
                iconNode = createBlockIconNode(for: item.type)
            }
            
            // Posicionar según la columna y fila actual
            let yPos = currentY - (CGFloat(itemsInCurrentColumn) * TopBarLayout.rowSpacing)
            iconNode.position = CGPoint(x: currentX, y: yPos)
            
            // Actualizar valor
            iconNode.updateValue(item.label)
            
            // Si es el icono de tiempo y queda poco tiempo, colorear en rojo
            if item.isTimeIcon {
                if let timeLimit = objective.timeLimit {
                    let timeLimitInterval = TimeInterval(timeLimit)
                    let remainingTime = max(timeLimitInterval - progress.timeElapsed, 0)
                    if remainingTime < 30 {
                        iconNode.updateValueColor(.red)
                    }
                }
            }
            
            // Añadir al contenedor
            container.addChild(iconNode)
            
            // Actualizar contadores
            itemsInCurrentColumn += 1
        }
        
        // Posicionar el contenedor en la parte superior del panel
        container.position = CGPoint(x: 0, y: TopBarLayout.verticalSpacing * 2)
    }
    
    private func updateTimeIcon(progress: ObjectiveProgress, timeLimit: Int) {
        let timeLimitInterval = TimeInterval(timeLimit)
        let remainingTime = max(timeLimitInterval - progress.timeElapsed, 0)
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        let timeText = String(format: "%02d:%02d", minutes, seconds)
        
        // Imprimir para debug
 //       print("⏱️ Actualizando tiempo: \(timeText) (restante: \(Int(remainingTime))s)")
        
        timeIconNode?.updateValue(timeText)
        
        // Actualizar color según tiempo restante
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

/// Vista previa que muestra cada ObjectiveInfoPanel en una escena separada
struct ObjectivePanelsPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            ScoreObjectivePreviewContainer()
                .frame(height: 150)
                .padding(.bottom, 10)
                .previewDisplayName("Score Objective")
            
            TotalNotesObjectivePreviewContainer()
                .frame(height: 150)
                .padding(.bottom, 10)
                .previewDisplayName("Total Notes Objective")
            
            NoteAccuracyObjectivePreviewContainer()
                .frame(height: 150)
                .padding(.bottom, 10)
                .previewDisplayName("Note Accuracy Objective")
            
            BlockDestructionObjectivePreviewContainer()
                .frame(height: 150)
                .padding(.bottom, 10)
                .previewDisplayName("Block Destruction Objective (Columnas)")
            
            TotalBlocksObjectivePreviewContainer()
                .frame(height: 150)
                .previewDisplayName("Total Blocks Objective")
        }
    }
}

// Contenedor base para reutilizar código
protocol ObjectivePreviewContainer: View {
    var objectiveType: String { get }
    func createObjectiveDetails() -> [String: Int]?
    func createBlocksDestroyed() -> [String: Int]
    func createAllowedStyles() -> [String]
}

extension ObjectivePreviewContainer {
    func createPreviewScene(size: CGSize) -> SKScene {
        let scene = SKScene(size: size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .lightGray
        
        let objectiveDetails = createObjectiveDetails()
        let allowedStyles = createAllowedStyles()
        let blocksDestroyed = createBlocksDestroyed()
        
        let objective = Objective(
            type: objectiveType,
            target: 1000,
            timeLimit: 180,
            minimumAccuracy: objectiveType == "note_accuracy" ? 0.85 : nil,
            details: objectiveDetails
        )
        
        let level = GameLevel(
            levelId: 1,
            name: "Nivel de prueba",
            maxScore: 500,
            allowedStyles: allowedStyles,
            complexNotes: nil,
            fallingSpeed: FallingSpeed(initial: 8.0, increment: 0.0),
            lives: Lives(
                initial: 3,
                extraLives: ExtraLives(scoreThresholds: [], maxExtra: 0)
            ),
            objectives: Objectives(primary: objective),
            blocks: [:]
        )
        
        let tracker = LevelObjectiveTracker(level: level)
        let progress = ObjectiveProgress(
            score: 350,
            notesHit: 40,
            accuracySum: 85.0,
            accuracyCount: 100,
            blocksByType: blocksDestroyed,
            totalBlocksDestroyed: blocksDestroyed.values.reduce(0, +),
            timeElapsed: 60
        )
        
        let panelSize = CGSize(width: size.width * 0.8, height: size.height * 0.7)
        let panel = ObjectivePanelFactory.createPanel(for: objective, size: panelSize, tracker: tracker)
        panel.updateInfo(with: progress)
        
        panel.position = CGPoint(x: size.width/2, y: size.height/2)
        scene.addChild(panel)
        
        return scene
    }
}

// Implementaciones específicas para cada tipo de objetivo
struct ScoreObjectivePreviewContainer: View, ObjectivePreviewContainer {
    var objectiveType: String { "score" }
    
    func createObjectiveDetails() -> [String: Int]? { nil }
    func createBlocksDestroyed() -> [String: Int] { [:] }
    func createAllowedStyles() -> [String] { [] }
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createPreviewScene(size: geometry.size))
                .background(Color.gray.opacity(0.2))
        }
    }
}

struct TotalNotesObjectivePreviewContainer: View, ObjectivePreviewContainer {
    var objectiveType: String { "total_notes" }
    
    func createObjectiveDetails() -> [String: Int]? { nil }
    func createBlocksDestroyed() -> [String: Int] { [:] }
    func createAllowedStyles() -> [String] { [] }
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createPreviewScene(size: geometry.size))
                .background(Color.gray.opacity(0.2))
        }
    }
}

struct NoteAccuracyObjectivePreviewContainer: View, ObjectivePreviewContainer {
    var objectiveType: String { "note_accuracy" }
    
    func createObjectiveDetails() -> [String: Int]? { nil }
    func createBlocksDestroyed() -> [String: Int] { [:] }
    func createAllowedStyles() -> [String] { [] }
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createPreviewScene(size: geometry.size))
                .background(Color.gray.opacity(0.2))
        }
    }
}

struct BlockDestructionObjectivePreviewContainer: View, ObjectivePreviewContainer {
    var objectiveType: String { "block_destruction" }
    
    func createObjectiveDetails() -> [String: Int]? {
        return [
            "defaultBlock": 5,
            "iceBlock": 3,
            "hardiceBlock": 7,
            "ghostBlock": 4,
            "changingBlock": 6,
            "explosiveBlock": 2
        ]
    }
    
    func createBlocksDestroyed() -> [String: Int] {
        return [
            "defaultBlock": 2,
            "iceBlock": 3,
            "hardiceBlock": 5,
            "ghostBlock": 1,
            "changingBlock": 4,
            "explosiveBlock": 0
        ]
    }
    
    func createAllowedStyles() -> [String] {
        return ["defaultBlock", "iceBlock", "hardiceBlock", "ghostBlock", "changingBlock", "explosiveBlock"]
    }
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createPreviewScene(size: geometry.size))
                .background(Color.gray.opacity(0.2))
        }
    }
    
    // Sobrescribir la función createPreviewScene para asegurar que incluya tiempo
    func createPreviewScene(size: CGSize) -> SKScene {
        let scene = SKScene(size: size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .lightGray
        
        let objectiveDetails = createObjectiveDetails()
        let allowedStyles = createAllowedStyles()
        let blocksDestroyed = createBlocksDestroyed()
        
        let objective = Objective(
            type: objectiveType,
            target: 1000,
            timeLimit: 180, // Asegurar que tenga límite de tiempo
            minimumAccuracy: nil,
            details: objectiveDetails
        )
        
        let level = GameLevel(
            levelId: 1,
            name: "Nivel de prueba",
            maxScore: 500,
            allowedStyles: allowedStyles,
            complexNotes: nil,
            fallingSpeed: FallingSpeed(initial: 8.0, increment: 0.0),
            lives: Lives(
                initial: 3,
                extraLives: ExtraLives(scoreThresholds: [], maxExtra: 0)
            ),
            objectives: Objectives(primary: objective),
            blocks: [:]
        )
        
        let tracker = LevelObjectiveTracker(level: level)
        let progress = ObjectiveProgress(
            score: 350,
            notesHit: 40,
            accuracySum: 85.0,
            accuracyCount: 100,
            blocksByType: blocksDestroyed,
            totalBlocksDestroyed: blocksDestroyed.values.reduce(0, +),
            timeElapsed: 60
        )
        
        let panelSize = CGSize(width: size.width * 0.8, height: size.height * 0.7)
        let panel = ObjectivePanelFactory.createPanel(for: objective, size: panelSize, tracker: tracker)
        panel.updateInfo(with: progress)
        
        panel.position = CGPoint(x: size.width/2, y: size.height/2)
        scene.addChild(panel)
        
        return scene
    }
}

struct TotalBlocksObjectivePreviewContainer: View, ObjectivePreviewContainer {
    var objectiveType: String { "total_blocks" }
    
    func createObjectiveDetails() -> [String: Int]? { nil }
    
    func createBlocksDestroyed() -> [String: Int] {
        // Para total_blocks solo importa el total, no los detalles por tipo
        return [
            "defaultBlock": 3,
            "iceBlock": 5,
            "hardiceBlock": 2,
        ]
    }
    
    func createAllowedStyles() -> [String] {
        return ["defaultBlock", "iceBlock", "hardiceBlock"]
    }
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createPreviewScene(size: geometry.size))
                .background(Color.gray.opacity(0.2))
        }
    }
}
#endif
