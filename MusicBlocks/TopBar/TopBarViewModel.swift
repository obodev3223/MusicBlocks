//
//  TopBarViewModel.swift
//  MusicBlocks
//
//  Created by Jose R. García on 18/4/25.
//

import Foundation
import SpriteKit

/// ViewModel para representar los datos de una TopBar
struct TopBarViewModel {
    /// Tipos de barra de top: principal o de objetivos
    enum BarType {
        case main
        case objectives
    }
    
    /// Datos de vidas
    struct LivesData {
        let current: Int
        let total: Int
        let extraLivesAvailable: Int
    }
    
    /// Datos de puntuación
    struct ScoreData {
        let current: Int
        let max: Int
        var progress: Double
    }
    
    /// Datos de objetivo
    struct ObjectiveData {
        let type: String
        var current: Double
        let target: Double
        var timeRemaining: TimeInterval?
        
        /// Calcula el progreso del objetivo
        var progress: Double {
            guard target > 0 else { return 0 }
            return min(current / target, 1.0)
        }
    }
    
    /// Tipo de barra
    let barType: BarType
    
    /// Nivel actual
    let levelId: Int
    
    /// Datos de vidas
    var lives: LivesData
    
    /// Datos de puntuación
    var score: ScoreData
    
    /// Datos de objetivo
    var objective: ObjectiveData
    
    /// Inicializador para barra principal
    init(
        levelId: Int,
        lives: LivesData,
        score: ScoreData
    ) {
        self.barType = .main
        self.levelId = levelId
        self.lives = lives
        self.score = score
        self.objective = ObjectiveData(
            type: "none", 
            current: 0, 
            target: 0
        )
    }
    
    /// Inicializador para barra de objetivos
    init(
        levelId: Int,
        objective: ObjectiveData
    ) {
        self.barType = .objectives
        self.levelId = levelId
        self.lives = LivesData(current: 0, total: 0, extraLivesAvailable: 0)
        self.score = ScoreData(current: 0, max: 0, progress: 0)
        self.objective = objective
    }
}
