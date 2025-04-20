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
    static let fontSize: CGFloat = 12
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

// MARK: - Componente de Tiempo - Mejora
class TimeDisplayNode: SKNode {
    private let timeIcon: SKSpriteNode
    private let timeLabel: SKLabelNode
    private let timeLimit: TimeInterval
    
    // Remover todas las propiedades y métodos relacionados con timers internos
    
    init(timeLimit: TimeInterval) {
        // Configuración del icono
        let iconTexture = SKTexture(imageNamed: "timer_icon")
        timeIcon = SKSpriteNode(texture: iconTexture)
        
        let originalSize = iconTexture.size()
        let w = originalSize.width
        let h = originalSize.height
        let maxDim: CGFloat = TopBarLayout.iconSize
        let scale = max(w, h) > 0 ? (maxDim / max(w, h)) : 1.0
        
        timeIcon.size = CGSize(width: w * scale, height: h * scale)
        
        // Configuración de la etiqueta
        self.timeLabel = SKLabelNode(fontNamed: "Helvetica")
        self.timeLimit = timeLimit
        
        super.init()
        
        setupTimeComponents()
        
        // Registrar la etiqueta con el actualizador directo
        TimeDirectUpdater.shared.registerTimeLabel(timeLabel)
        TimeDirectUpdater.shared.setTimeLimit(timeLimit)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTimeComponents() {
        // Posicionar el icono
        timeIcon.position = CGPoint(x: -TopBarLayout.iconTextSpacing/2, y: 0)
        addChild(timeIcon)
        
        // Configurar la etiqueta
        timeLabel.fontSize = TopBarLayout.fontSize
        timeLabel.fontColor = .darkGray
        timeLabel.verticalAlignmentMode = .center
        timeLabel.horizontalAlignmentMode = .left
        timeLabel.position = CGPoint(x: timeIcon.position.x + TopBarLayout.iconTextSpacing, y: 0)
        
        // Mostrar tiempo inicial
        let minutes = Int(timeLimit) / 60
        let seconds = Int(timeLimit) % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        addChild(timeLabel)
    }
    
    // Simplificar método update y activateTimer para que solo actualice la UI
    // sin mantener estado interno
    
    func activateTimer() {
        // Ahora solo llama al updater centralizado
        TimeDirectUpdater.shared.start()
    }
    
    func update() {
        // No hacer nada aquí - la actualización la maneja TimeDirectUpdater
    }
    
    func stopTimer() {
        // Opcional - solo si necesitas detener explícitamente
    }
    
    override func removeFromParent() {
        // No detener el timer central, solo eliminar el nodo
        super.removeFromParent()
    }
}

// MARK: - Panel Base de Objetivos
class ObjectiveInfoPanel: TopBarBaseNode {
    weak var objectiveTracker: LevelObjectiveTracker?
    
    // Icono único para "score", "notes", etc.
    private var objectiveIconNode: ObjectiveIconNode?
    // Reemplazar timeIconNode por timeDisplayNode
    private var timeDisplayNode: TimeDisplayNode?
    
    // Lista de iconos por estilo de bloque
    private var blockIcons: [String: ObjectiveIconNode] = [:]
    
    // Contenedor para el objetivo "block_destruction" y "note_accuracy"
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
        
        // Tratamiento especial para note_accuracy
        if objective.type == "note_accuracy" {
            // No creamos objectiveIconNode para note_accuracy, lo haremos manualmente
            // en updateNoteAccuracyLayout
            
            // Crear contenedor específico para note_accuracy
            let container = SKNode()
            contentContainer.addChild(container)
            blockDestructionContainer = container
            
            // El tiempo se añadirá también en updateNoteAccuracyLayout
            return
        }
        
        // Para todos los tipos de objetivo usamos el mismo enfoque básico
        // Esto asegura consistencia visual entre diferentes tipos
        
        // 1. Definir qué tipo de icono principal usaremos
        let iconType: ObjectiveIcon = getObjectiveIconType(for: objective.type)
        
        // 2. Crear el icono principal para todos los tipos
        objectiveIconNode = ObjectiveIconNode(type: iconType)
        if let objIcon = objectiveIconNode {
            objIcon.position = CGPoint(x: 0, y: TopBarLayout.verticalSpacing * 2)
            contentContainer.addChild(objIcon)
        }
        
        // 3. Crear el TimeDisplayNode para todos los tipos si tienen límite de tiempo
        if let timeLimit = objective.timeLimit {
            // Usar TimeDisplayNode en lugar de ObjectiveIconNode
            timeDisplayNode = TimeDisplayNode(timeLimit: TimeInterval(timeLimit))
            if let timeDisplay = timeDisplayNode {
                timeDisplay.position = CGPoint(x: 0, y: -TopBarLayout.verticalSpacing * 2)
                contentContainer.addChild(timeDisplay)
            }
        } else {
            // Para objetivos sin límite de tiempo, mostrar un símbolo de infinito
            let infiniteTimeNode = SKNode()
            let infiniteIcon = SKSpriteNode(imageNamed: "timer_icon")
            infiniteIcon.size = CGSize(width: TopBarLayout.iconSize, height: TopBarLayout.iconSize)
            infiniteIcon.position = CGPoint(x: -TopBarLayout.iconTextSpacing/2, y: 0)
            
            let infiniteLabel = SKLabelNode(fontNamed: "Helvetica")
            infiniteLabel.text = "∞"
            infiniteLabel.fontSize = TopBarLayout.titleFontSize * 1.5
            infiniteLabel.fontColor = .darkGray
            infiniteLabel.verticalAlignmentMode = .center
            infiniteLabel.horizontalAlignmentMode = .left
            infiniteLabel.position = CGPoint(x: infiniteIcon.position.x + TopBarLayout.iconTextSpacing, y: 0)
            
            infiniteTimeNode.addChild(infiniteIcon)
            infiniteTimeNode.addChild(infiniteLabel)
            infiniteTimeNode.position = CGPoint(x: 0, y: -TopBarLayout.verticalSpacing * 2)
            contentContainer.addChild(infiniteTimeNode)
        }
        
        // 4. Para casos especiales, preparamos contenedores adicionales
        if objective.type == "block_destruction" || objective.type == "note_accuracy" {
            let container = SKNode()
            contentContainer.addChild(container)
            blockDestructionContainer = container
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
        
        // Para objetivos especiales con sus propios contenedores
        if objective.type == "block_destruction" {
            if let details = objective.details {
                updateBlockDestructionLayout(with: progress, details: details)
            }
            return
        }
        
        if objective.type == "note_accuracy" {
            updateNoteAccuracyLayout(with: progress, objective: objective)
            return
        }
        
        // Para el resto de objetivos, actualizamos de manera estándar
        
        // 1. Actualizar el valor principal según el tipo de objetivo
        switch objective.type {
        case "score":
            objectiveIconNode?.updateValue("\(progress.score)/\(objective.target ?? 0)")
        case "total_notes":
            objectiveIconNode?.updateValue("\(progress.notesHit)/\(objective.target ?? 0)")
        case "total_blocks":
            objectiveIconNode?.updateValue("\(progress.totalBlocksDestroyed)/\(objective.target ?? 0)")
        default:
            objectiveIconNode?.updateValue("-")
        }
        
        // 2. Actualizar todos los TimeDisplayNode que pudieran existir
        updateTimeDisplay(with: progress, timeLimit: objective.timeLimit)
    }

    // Nuevo método para actualizar todos los TimeDisplayNode
    private func updateTimeDisplay(with progress: ObjectiveProgress, timeLimit: Int?) {
        // Si hay un límite de tiempo y tenemos un TimeDisplayNode
        if let timeDisplay = findTimeDisplayNode() {
            // Actualizar el startTime para reflejar el tiempo transcurrido
            let newStartTime = Date(timeIntervalSinceReferenceDate:
                Date().timeIntervalSinceReferenceDate - progress.timeElapsed)
            timeDisplay.startTime = newStartTime
            timeDisplay.update()
        }
    }

    // Método auxiliar para encontrar el primer TimeDisplayNode
    private func findTimeDisplayNode() -> TimeDisplayNode? {
        // Primero buscar en los hijos directos
        for child in children {
            if let timeNode = child as? TimeDisplayNode {
                return timeNode
            }
        }
        
        // Luego buscar recursivamente en todos los hijos
        return findTimeDisplayNodeRecursively(in: self)
    }

    // Búsqueda recursiva en la jerarquía de nodos
    private func findTimeDisplayNodeRecursively(in node: SKNode) -> TimeDisplayNode? {
        for child in node.children {
            if let timeNode = child as? TimeDisplayNode {
                return timeNode
            }
            
            if let found = findTimeDisplayNodeRecursively(in: child) {
                return found
            }
        }
        
        return nil
    }

    private func updateNoteAccuracyLayout(with progress: ObjectiveProgress, objective: Objective) {
        // Limpiar el contenedor auxiliar
        blockDestructionContainer?.removeAllChildren()
        guard let container = blockDestructionContainer else { return }
        
        // Constantes para uniformidad
      
        let columnWidth: CGFloat = 90  // Ancho de cada columna
        
        // FILA 1, COLUMNA 1: Icono de nota y contador
        let noteIconNode = createIconWithLabel(
            iconName: "note_icon",
            text: "\(progress.notesHit)/\(objective.target ?? 0)",
            position: CGPoint(x: 0, y: TopBarLayout.verticalSpacing * 2)
        )
        container.addChild(noteIconNode)
        
        // FILA 1, COLUMNA 2: Tiempo (si existe)
        if let timeLimit = objective.timeLimit {
            let timeNode = TimeDisplayNode(timeLimit: TimeInterval(timeLimit))
            timeNode.position = CGPoint(x: columnWidth, y: TopBarLayout.verticalSpacing * 2)
            timeNode.startTime = Date(timeIntervalSinceReferenceDate:
                Date().timeIntervalSinceReferenceDate - progress.timeElapsed)
            container.addChild(timeNode)
        }
        
        // FILA 2, COLUMNA 1: Icono de precisión y valor
        let accuracyPercentage = Int(progress.averageAccuracy * 100)
        let minAccuracyPercentage = Int((objective.minimumAccuracy ?? 0) * 100)
        let accuracyText = "\(accuracyPercentage)/\(minAccuracyPercentage)"
        
        let accuracyIconNode = createIconWithLabel(
            iconName: "target_icon",
            text: accuracyText,
            position: CGPoint(x: 0, y: -TopBarLayout.verticalSpacing * 2)
        )
        
        // Color según precisión
        if let label = accuracyIconNode.childNode(withName: "label") as? SKLabelNode {
            if progress.averageAccuracy < (objective.minimumAccuracy ?? 0) {
                label.fontColor = .red
            } else {
                label.fontColor = .darkGray
            }
        }
        
        container.addChild(accuracyIconNode)
    }

    // Método auxiliar para crear un icono con etiqueta
    private func createIconWithLabel(iconName: String, text: String, position: CGPoint) -> SKNode {
        let node = SKNode()
        node.position = position
        
        // Crear icono
        let iconTexture = SKTexture(imageNamed: iconName)
        let originalSize = iconTexture.size()
        let maxDim: CGFloat = TopBarLayout.iconSize
        let scale = max(originalSize.width, originalSize.height) > 0 ?
                    (maxDim / max(originalSize.width, originalSize.height)) : 1.0
        
        let icon = SKSpriteNode(texture: iconTexture)
        icon.size = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        icon.position = CGPoint(x: -TopBarLayout.iconTextSpacing/2, y: 0)
        node.addChild(icon)
        
        // Crear etiqueta
        let label = SKLabelNode(fontNamed: "Helvetica")
        label.name = "label"  // Para poder acceder a ella después
        label.fontSize = TopBarLayout.fontSize
        label.text = text
        label.fontColor = .darkGray
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: icon.position.x + TopBarLayout.iconSize/2 + TopBarLayout.horizontalSpacing, y: 0)
        node.addChild(label)
        
        return node
    }
    
    // Método para actualizar el layout de block_destruction
    private func updateBlockDestructionLayout(with progress: ObjectiveProgress, details: [String: Int]) {
        // Limpiar el contenedor existente si hay uno
        blockDestructionContainer?.removeAllChildren()
        guard let container = blockDestructionContainer else { return }
        
        guard objectiveTracker?.getPrimaryObjective() != nil else { return }
        
        // Definir el orden de los tipos de bloques
        let blockOrder = [
            "defaultBlock",
            "iceBlock",
            "hardiceBlock",
            "ghostBlock",
            "changingBlock",
            "explosiveBlock"
        ]
        
        // Filtrar solo los bloques que están presentes en los detalles del objetivo
        let blocksToShow = blockOrder.filter { details.keys.contains($0) }
        
        // Crear una lista organizada de bloques a mostrar
        var displayItems: [(type: String, label: String)] = []
        
        // Añadir bloques en el orden especificado
        for blockType in blocksToShow {
            if let required = details[blockType] {
                let destroyed = progress.blocksByType[blockType, default: 0]
                let text = "\(destroyed)/\(required)"
                displayItems.append((type: blockType, label: text))
            }
        }
        
        // Configuración de layout
        let maxItemsPerColumn = 2
        let columnWidth: CGFloat = 70
        let rowHeight: CGFloat = 24
        let iconSize: CGFloat = TopBarLayout.iconSize
        let horizontalSpacing: CGFloat = TopBarLayout.horizontalSpacing
        
        // Calcular número de columnas necesarias
        let columnsNeeded = (displayItems.count + maxItemsPerColumn - 1) / maxItemsPerColumn
        
        // Calcular posición inicial X
        let startX: CGFloat = -(columnWidth * CGFloat(columnsNeeded - 1) / 2)
        
        // Organizar bloques en columnas
        for (index, item) in displayItems.enumerated() {
            let column = index / maxItemsPerColumn
            let row = index % maxItemsPerColumn
            
            // Calcular posición
            let xPos = startX + CGFloat(column) * columnWidth
            let yPos = rowHeight/2 - CGFloat(row) * rowHeight
            
            // Crear icono para este bloque
            let iconNode = createBlockIcon(for: item.type)
            iconNode.position = CGPoint(x: xPos, y: yPos)
            
            // Crear etiqueta para este bloque
            let label = SKLabelNode(fontNamed: "Helvetica")
            label.fontSize = TopBarLayout.fontSize
            label.text = item.label
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: xPos + iconSize/2 + horizontalSpacing, y: yPos)
            label.fontColor = .darkGray
            
            // Añadir a la vista
            container.addChild(iconNode)
            container.addChild(label)
        }
        
        // CORRECCIÓN: Posicionamiento del tiempo en la primera fila de la última columna
        if let objective = objectiveTracker?.getPrimaryObjective(), let timeLimit = objective.timeLimit {
            // Calcular la posición del tiempo en la última columna
            let lastColumnX = startX + CGFloat(columnsNeeded) * columnWidth
            
            // Crear un nuevo TimeDisplayNode si no existe uno
            var timeNode: TimeDisplayNode?
            
            // Primero buscar si ya existe un TimeDisplayNode en el container
            for child in container.children {
                if let existingTimeNode = child as? TimeDisplayNode {
                    timeNode = existingTimeNode
                    break
                }
            }
            
            // Si no existe, crear uno nuevo
            if timeNode == nil {
                timeNode = TimeDisplayNode(timeLimit: TimeInterval(timeLimit))
            }
            
            if let timeNode = timeNode {
                // Posicionar en la primera fila (usando un valor positivo para Y)
                // IMPORTANTE: Usar rowHeight/2 para alinearlo con la primera fila de bloques
                timeNode.position = CGPoint(x: lastColumnX, y: rowHeight/2)
                timeNode.startTime = Date(timeIntervalSinceReferenceDate:
                    Date().timeIntervalSinceReferenceDate - progress.timeElapsed)
                
                // Añadir al container solo si no estaba ya añadido
                if timeNode.parent == nil {
                    container.addChild(timeNode)
                }
                
                // Ahora que tenemos un nodo específico podemos ocultar el estándar
                if let standardTimeNode = timeDisplayNode {
                    standardTimeNode.alpha = 0
                }
            }
        } else {
            // Si no hay timeLimit, mostrar el timeDisplayNode estándar
            if let standardTimeNode = timeDisplayNode {
                standardTimeNode.alpha = 1
            }
        }
        
        // CORRECCIÓN: Asegurarnos de ocultar cualquier icono de fondo adicional
        // Esto podría estar ocurriendo si objectiveIconNode o algún otro nodo
        // se está mostrando cuando no debería
        if let objIcon = objectiveIconNode {
            objIcon.alpha = 0
        }
    }
    
    // Método auxiliar para crear iconos de bloque como SKSpriteNode (no ObjectiveIconNode)
    private func createBlockIcon(for blockType: String) -> SKSpriteNode {
        // Mapeo de tipo de bloque a nombre de imagen
        let iconMapping: [String: String] = [
            "defaultBlock": "defaultBlock_icon",
            "iceBlock": "iceBlock_icon",
            "hardiceBlock": "hardiceBlock_icon",
            "ghostBlock": "ghostBlock_icon",
            "changingBlock": "changingBlock_icon",
            "explosiveBlock": "explosiveBlock_icon"
        ]
        
        // Obtener nombre de imagen para este tipo de bloque
        let imageName = iconMapping[blockType] ?? "defaultBlock_icon"
        let iconTexture = SKTexture(imageNamed: imageName)
        
        // Usar el mismo método de escalado que se usa en ObjectiveIconNode
        // para mantener las mismas proporciones que en total_blocks
        let originalSize = iconTexture.size()
        let w = originalSize.width
        let h = originalSize.height
        
        // Ratio para ajustar la dimensión más larga a 'iconSize'
        let maxDim: CGFloat = TopBarLayout.iconSize
        let scale = max(w, h) > 0 ? (maxDim / max(w, h)) : 1.0
        
        let finalWidth = w * scale
        let finalHeight = h * scale
        
        // Crear el sprite con el tamaño correcto
        let spriteNode = SKSpriteNode(texture: iconTexture)
        spriteNode.size = CGSize(width: finalWidth, height: finalHeight)
        
        return spriteNode
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
            timeElapsed: 90
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
