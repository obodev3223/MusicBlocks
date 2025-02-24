//
//  PracticeTunerScene.swift
//  MusicBlocks
//
//  Created by Jose R. García on 24/2/25.
//

import SpriteKit

protocol GameSceneDelegate: AnyObject {
    func gameScene(_ scene: PracticeTunerScene, didUpdateTunerData data: TunerEngine.TunerData)
    func gameScene(_ scene: PracticeTunerScene, didUpdateStabilityDuration duration: TimeInterval)
}

class PracticeTunerScene: SKScene {
    weak var gameDelegate: GameSceneDelegate?
    
    private var tuningPanel: TuningPanelNode!
    private var stabilityPanel: StabilityPanelNode!
    private var targetNoteNode: TargetNoteNode!
    private var successNode: SuccessNode!
    private var failureNode: FailureNode!
    
    override func didMove(to view: SKView) {
            // Agregar print de debugging
            print("Scene did move to view")
            
            // Asegurar que la escena sea visible
            backgroundColor = .white
            
            // Agregar un nodo de prueba para verificar que la escena está funcionando
            let testNode = SKShapeNode(circleOfRadius: 50)
            testNode.fillColor = .red
            testNode.position = CGPoint(x: size.width/2, y: size.height/2)
            addChild(testNode)
            
            print("Scene size: \(size)")
            
            setupNodes()
        }
        
    private func setupNodes() {
        // Debugging
        print("Setting up nodes")
        
        // Setup tuning panel con posición absoluta
        tuningPanel = TuningPanelNode()
        tuningPanel.position = CGPoint(x: size.width - 60, y: size.height * 0.5)
        addChild(tuningPanel)
        print("Added tuning panel at position: \(tuningPanel.position)")
        
        // Setup stability panel con posición absoluta
        stabilityPanel = StabilityPanelNode()
        stabilityPanel.position = CGPoint(x: 60, y: size.height * 0.5)
        addChild(stabilityPanel)
        print("Added stability panel at position: \(stabilityPanel.position)")
        
        // Setup target note con posición absoluta
        targetNoteNode = TargetNoteNode()
        targetNoteNode.position = CGPoint(x: size.width * 0.5, y: size.height * 0.7)
        addChild(targetNoteNode)
        print("Added target note at position: \(targetNoteNode.position)")
        
        // Setup overlays con posiciones absolutas
        successNode = SuccessNode()
        successNode.position = CGPoint(x: size.width * 0.5, y: size.height * 0.3)
        successNode.alpha = 0
        addChild(successNode)
        
        failureNode = FailureNode()
        failureNode.position = CGPoint(x: size.width * 0.5, y: size.height * 0.3)
        failureNode.alpha = 0
        addChild(failureNode)
    }
    
    func resetScene() {
        targetNoteNode.reset()
        successNode.alpha = 0
        failureNode.alpha = 0
    }
    
    func updateTuningData(_ data: TunerEngine.TunerData) {
        tuningPanel.update(with: data)
        gameDelegate?.gameScene(self, didUpdateTunerData: data)  // Usamos gameDelegate
    }

    func updateStabilityDuration(_ duration: TimeInterval) {
        stabilityPanel.update(duration: duration)
        gameDelegate?.gameScene(self, didUpdateStabilityDuration: duration)  // Usamos gameDelegate
    }
    
    func showSuccess(multiplier: Int, message: String) {
        successNode.show(multiplier: multiplier, message: message)
        targetNoteNode.fadeOut()
    }
    
    func showFailure() {
        failureNode.show()
    }
}
