//
//  TopBar.swift
//  MusicBlocks
//
//  Created by Jose R. García on 18/4/25.
//


import SpriteKit

class TopBar: SKNode {
    // Renderer for the bar
    private let renderer: TopBarViewRenderer
    
    // ViewModel to handle the data
    private var viewModel: TopBarViewModel
    
    // Creation method like the previous one, but using the new system
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
    
    // Main initializer
    init(type: TopBarType) {
        // Determine the renderer type based on the bar type
        let barType = type.toBarType
        self.renderer = TopBarRendererFactory.createRenderer(for: barType)
        
        // Create an initial default ViewModel
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
        
        // Render the initial view
        let renderedNode = renderer.render(viewModel: viewModel)
        addChild(renderedNode)
    }
    
    // Required initializer for SKNode
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Configure the bar with a specific level
    func configure(withLevel level: GameLevel, objectiveTracker: LevelObjectiveTracker) {
        // For the main bar
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
        // For the objectives bar
        else {
            // Extract information from the primary objective
            let primaryObjective = level.objectives.primary
            
            // Create objective data based on the type
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
            // Add more cases as needed
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
        
        // Render with the new ViewModel
        removeAllChildren()
        let renderedNode = renderer.render(viewModel: viewModel)
        addChild(renderedNode)
    }
    
    // Update the bar with new data
    func updateScore(_ score: Int) {
        switch viewModel.barType {
        case .main:
            // Update only if it's the main bar
            viewModel.score.current = score
            viewModel.score.progress = Double(score) / Double(viewModel.score.max)
        case .objectives:
            // For the objectives bar, update the current objective if it's of score type
            if viewModel.objective.type == "score" {
                viewModel.objective.current = Double(score)
            }
        }
        
        // Update the view
        renderer.update(viewModel: viewModel)
    }
    
    // Update lives
    func updateLives(_ lives: Int) {
        guard viewModel.barType == .main else { return }
        
        viewModel.lives.current = lives
        renderer.update(viewModel: viewModel)
    }
    
    // Update objective progress
    func updateObjectiveInfo(with progress: ObjectiveProgress) {
        guard viewModel.barType == .objectives else { return }
        
        // Update according to objective type
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
        
        // Update elapsed time if available
        if let timeLimit = progress.timeLimit {
            viewModel.objective.timeRemaining = max(0, timeLimit - progress.timeElapsed)
        }
        
        // Update the view
        renderer.update(viewModel: viewModel)
    }
    
    // Method to update the objective progress
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
        
        // TopBar of type .main (left)
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
        
        // TopBar of type .objectives (right)
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
