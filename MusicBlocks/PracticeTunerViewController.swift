//
//  PracticeTunerViewController.swift
//  MusicBlocks
//
//  Created by Jose R. García on 24/2/25.
//

import UIKit
import SpriteKit

class PracticeTunerViewController: UIViewController {
    private var audioController = AudioController.sharedInstance
    private var gameEngine = GameEngine()
    private var currentMultiplier: Int = 1
    private var successMessage: String = ""
    
    private var skView: SKView!
    private var gameScene: PracticeTunerScene!
    private var topBarView: TopBarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Test básico de SpriteKit
        let skView = SKView(frame: view.bounds)
        view.addSubview(skView)
        
        let scene = SKScene(size: skView.bounds.size)
        scene.backgroundColor = .green
        
        let testNode = SKShapeNode(circleOfRadius: 50)
        testNode.fillColor = .red
        testNode.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        scene.addChild(testNode)
        
        skView.presentScene(scene)
        
        // Imprimir información de debugging
        print("View bounds: \(view.bounds)")
        print("SKView bounds: \(skView.bounds)")
        print("Scene size: \(scene.size)")
    }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            // Asegurarnos que la vista no sea transparente
            view.backgroundColor = .white
        }
        
        private func setupViews() {
            // Setup SpriteKit view con debugging
            skView = SKView(frame: view.bounds)
            skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Habilitar debugging para ver qué está pasando
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.showsDrawCount = true
            
            view.addSubview(skView)
            
            // Setup top bar
            topBarView = TopBarView(frame: CGRect(x: 0, y: 50,
                                                width: view.bounds.width,
                                                height: 80))
            topBarView.autoresizingMask = [.flexibleWidth]
            view.addSubview(topBarView)
            
            // Setup game scene con tamaño específico
            let sceneSize = CGSize(width: skView.bounds.width,
                                 height: skView.bounds.height)
            gameScene = PracticeTunerScene(size: sceneSize)
            gameScene.scaleMode = .resizeFill
            gameScene.gameDelegate = self
            
            // Presentar la escena con debugging
            print("Presenting scene with size: \(sceneSize)")
            skView.presentScene(gameScene)
        }
    
    private func setupAndStart() {
        audioController.stop()
        gameEngine.startNewGame()
        audioController.start()
        startMatchTracking()
        
        updateTopBar()
        gameScene.resetScene()
    }
    
    private func startMatchTracking() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.gameEngine.checkNote(
                currentNote: self.audioController.tunerData.note,
                deviation: self.audioController.tunerData.deviation,
                isActive: self.audioController.tunerData.isActive
            )
        }
    }
    
    private func updateTopBar() {
        topBarView.update(lives: gameEngine.lives,
                         maxLives: gameEngine.maxLives,
                         score: gameEngine.score)
    }
}

// MARK: - GameSceneDelegate
extension PracticeTunerViewController: GameSceneDelegate {
    func gameScene(_ scene: PracticeTunerScene, didUpdateTunerData data: TunerEngine.TunerData) {
        // Update tuning indicators in the scene
        gameScene.updateTuningData(data)
    }
    
    func gameScene(_ scene: PracticeTunerScene, didUpdateStabilityDuration duration: TimeInterval) {
        // Update stability indicators in the scene
        gameScene.updateStabilityDuration(duration)
    }
}
