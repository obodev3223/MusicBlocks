//
//  GameTypes.swift
//  MusicBlocks
//
//  Created by Jose R. García on 7/3/25.
//

import Foundation
import SpriteKit

// MARK: - Block Types
struct BlockInfo {
    let node: SKNode
    let note: String
    let style: String
    let config: Block
    let requiredHits: Int
    let requiredTime: TimeInterval
    var currentHits: Int = 0
    var holdStartTime: Date?
}

// MARK: - Game States
enum GameState {
    case countdown
    case playing
    case paused
    case gameOver(reason: GameOverReason)
}

enum GameOverReason: String {
    case noLives = "noLives"
    case blocksOverflow = "blocksOverflow"
    case victory = "victory"
    
    var message: String {
        switch self {
        case .noLives:
            return "¡Te has quedado sin vidas!"
        case .blocksOverflow:
            return "¡Los bloques han llegado demasiado abajo!"
        case .victory:
            return "¡Nivel completado!"
        }
    }
    
    var isVictory: Bool {
        if case .victory = self {
            return true
        }
        return false
    }
}

// En GameTypes.swift
enum NoteStateType: String {
    case waiting = "waiting"
    case correct = "correct"
    case wrong = "wrong"
    case success = "success"
}


enum NoteState: Equatable {
    case waiting
    case correct(deviation: Double)
    case wrong
    case success(multiplier: Int, message: String)
}
