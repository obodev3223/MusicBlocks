//
//  TopBar.swift
//  MusicBlocks
//
//  Created by Jose R. García on 18/4/25.
//


import SpriteKit

class TopBar: SKNode {
    // Renderer para la barra
    private let renderer: TopBarViewRenderer
    
    // ViewModel para manejar los datos
    private var viewModel: TopBarViewModel
    
    // Método de creación similar al anterior, pero usando el nuevo sistema
    class func create(
        width: CGFloat,
        height: CGFloat,
        position: CGPoint,
        type: TopBarType
    ) -> TopBar {
        let topBar = TopBar(type: type)
        topBar.position = position
        return topBar
    }
    
    // Inicializador principal
    init(type: TopBarType) {
        // Determinar el tipo de renderizador basado en el tipo de barra
        let barType: TopBarViewModel.BarType = type == .main ? .main : .objectives
        self.renderer = TopBarRendererFactory.createRenderer(for: barType)
        
        // Crear un ViewModel inicial por defecto
        self.viewModel = barType == .main
            ? TopBarViewModel(
                levelId: 1,
                lives: .init(current: 3, total: 3, extraLivesAvailable: 0),
                score: .init(current: 0, max: 1000, progress: 0)
            )
            : TopBarViewModel(
                levelId: 1,
                objective: .init(
                    type: "score",
                    current: 0,
                    target: 1000,
                    timeRemaining: 180
                )
            )
        
        super.init()
        
        // Renderizar la vista inicial
        let renderedNode = renderer.render(viewModel: viewModel)
        addChild(renderedNode)
    }
    
    // Inicializador requerido para SKNode
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Configurar la barra con un nivel específico
    func configure(withLevel level: GameLevel, objectiveTracker: LevelObjectiveTracker) {
        // Para la barra principal
        if viewModel.barType == .main {
            viewModel = TopBarViewModel(
                levelId: level.levelId,
                lives: .init(
                    current: level.lives.initial,
                    total: level.lives.initial,
                    extraLivesAvailable: level.lives.extraLives.maxExtra
                ),
                score: .init(current: 0, max: level.maxScore, progress: 0)
            )
        }
        // Para la barra de objetivos
        else {
            // Extraer información del objetivo primario
            let primaryObjective = level.objectives.primary
            
            // Crear datos del objetivo basados en el tipo
            let objectiveData: TopBarViewModel.ObjectiveData
            switch primaryObjective.type {
            case "score":
                objectiveData = .init(
                    type: "score",
                    current: 0,
                    target: Double(primaryObjective.target ?? 0),
                    timeRemaining: TimeInterval(primaryObjective.timeLimit ?? 0)
                )
            case "total_notes":
                objectiveData = .init(
                    type: "total_notes",
                    current: 0,
                    target: Double(primaryObjective.target ?? 0),
                    timeRemaining: TimeInterval(primaryObjective.timeLimit ?? 0)
                )
            // Añadir más casos según sea necesario
            default:
                objectiveData = .init(
                    type: primaryObjective.type,
                    current: 0,
                    target: 1,
                    timeRemaining: nil
                )
            }
            
            viewModel = TopBarViewModel(
                levelId: level.levelId,
                objective: objectiveData
            )
        }
        
        // Renderizar con el nuevo ViewModel
        removeAllChildren()
        let renderedNode = renderer.render(viewModel: viewModel)
        addChild(renderedNode)
    }
    
    // Actualizar la barra con nuevos datos
    func updateScore(_ score: Int) {
        switch viewModel.barType {
        case .main:
            // Actualizar solo si es la barra principal
            viewModel.score.current = score
            viewModel.score.progress = Double(score) / Double(viewModel.score.max)
        case .objectives:
            // Para la barra de objetivos, actualizar el objetivo actual si es de tipo puntuación
            if viewModel.objective.type == "score" {
                viewModel.objective.current = Double(score)
            }
        }
        
        // Actualizar la vista
        renderer.update(viewModel: viewModel)
    }
    
    // Actualizar vidas
    func updateLives(_ lives: Int) {
        guard viewModel.barType == .main else { return }
        
        viewModel.lives.current = lives
        renderer.update(viewModel: viewModel)
    }
    
    // Actualizar progreso del objetivo
    func updateObjectiveInfo(with progress: ObjectiveProgress) {
        guard viewModel.barType == .objectives else { return }
        
        // Actualizar según el tipo de objetivo
        switch viewModel.objective.type {
        case "score":
            viewModel.objective.current = Double(progress.score)
        case "total_notes":
            viewModel.objective.current = Double(progress.notesHit)
        case "note_accuracy":
            viewModel.objective.current = progress.accuracySum / Double(max(progress.accuracyCount, 1))
        case "block_destruction", "total_blocks":
            viewModel.objective.current = Double(progress.totalBlocksDestroyed)
        default:
            break
        }
        
        // Actualizar tiempo transcurrido si está disponible
        viewModel.objective.timeRemaining = progress.timeLimit > 0
            ? max(0, progress.timeLimit - progress.timeElapsed)
            : nil
        
        // Actualizar la vista
        renderer.update(viewModel: viewModel)
    }
    
    // Método para actualizar el progreso del objetivo
    func updateProgress(progress: Double) {
        guard viewModel.barType == .main else { return }
        
        viewModel.score.progress = progress
        renderer.update(viewModel: viewModel)
    }
}


// MARK: - SwiftUI Previews
#if DEBUG
import SwiftUI

struct TopBarPreview: PreviewProvider {
    static var previews: some View {
        TopBarPreviewContainer()
            .previewDisplayName("TopBar")
    }
}

struct TopBarPreviewContainer: View {
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createScene(size: geometry.size))
                .background(Color.gray.opacity(0.2))
        }
    }
    
    private func createScene(size: CGSize) -> SKScene {
        let scene = SKScene(size: size)
        scene.backgroundColor = .darkGray
        
        let level = GameLevel(
            levelId: 1,
            name: "Nivel de prueba",
            maxScore: 600,
            allowedStyles: [],
            complexNotes: nil,
            fallingSpeed: FallingSpeed(initial: 8.0, increment: 0.0),
            lives: Lives(
                initial: 3,
                extraLives: ExtraLives(scoreThresholds: [500, 1000], maxExtra: 2)
            ),
            objectives: Objectives(primary: Objective(
                type: "score",
                target: 1000,
                timeLimit: 180,
                minimumAccuracy: nil,
                details: nil
            )),
            blocks: [:]
        )
        
        // TopBar de tipo .main (izquierda)
        let topBarWidth = min(size.width * 0.45, 300)
        let topBarHeight: CGFloat = 60
        
        let leftBar = TopBar.create(
            width: topBarWidth,
            height: topBarHeight,
            position: CGPoint(x: size.width/2, y: size.height/2 + 50),
            type: .main
        )
        leftBar.configure(withLevel: level, objectiveTracker: LevelObjectiveTracker(level: level))
        leftBar.updateScore(300)
        leftBar.updateLives(2)
        
        scene.addChild(leftBar)
        
        // TopBar de tipo .objectives (derecha)
        let rightBar = TopBar.create(
            width: topBarWidth,
            height: topBarHeight,
            position: CGPoint(x: size.width/2, y: size.height/2 - 50),
            type: .objectives
        )
        rightBar.configure(withLevel: level, objectiveTracker: LevelObjectiveTracker(level: level))
        let progress = ObjectiveProgress(
            score: 300,
            notesHit: 15,
            accuracySum: 85.0,
            accuracyCount: 1,
            totalBlocksDestroyed: 15,
            timeElapsed: 45
        )
        rightBar.updateObjectiveInfo(with: progress)
        
        scene.addChild(rightBar)
        
        return scene
    }
}
#endif
