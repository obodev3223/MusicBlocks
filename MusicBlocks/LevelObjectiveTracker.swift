//
//  LevelObjectiveTracker.swift
//  MusicBlocks
//
//  Created by Jose R. García on 8/3/25.
//

import Foundation

class LevelObjectiveTracker {
    private let primaryObjective: Objective
    private var currentProgress: ObjectiveProgress
    
    
    init(level: GameLevel) {
        self.primaryObjective = level.objectives.primary
        self.currentProgress = ObjectiveProgress()
        
        // Inicializar contadores para cada estilo permitido en el nivel
        for style in level.allowedStyles {
            currentProgress.blocksByType[style] = 0
        }
    }

        
    func getPrimaryObjective() -> Objective {
        return primaryObjective
    }
    
    // MARK: - Progress Updates
    
    func updateProgress(score: Int? = nil,
                       noteHit: Bool? = nil,
                       accuracy: Double? = nil,
                       blockDestroyed: String? = nil,
                       deltaTime: TimeInterval? = nil) {
        // Actualizar score - Para objetivos tipo "score"
        if let score = score {
            currentProgress.score = score
        }
        
        // Actualizar notas acertadas - Para objetivos tipo "total_notes"
        if let noteHit = noteHit, noteHit {
            currentProgress.notesHit += 1
        }
        
        // Actualizar precisión - Para objetivos tipo "note_accuracy"
        if let accuracy = accuracy {
            currentProgress.accuracySum += accuracy
            currentProgress.accuracyCount += 1
        }
        
        // Actualizar bloques destruidos - Para objetivos tipo "block_destruction" y "total_blocks"
        if let blockType = blockDestroyed {
            currentProgress.blocksByType[blockType, default: 0] += 1
            currentProgress.totalBlocksDestroyed += 1
        }
        
        // Actualizar tiempo
        if let deltaTime = deltaTime {
            currentProgress.timeElapsed += deltaTime
        }
    }
    
    // MARK: - Objective Checking
    
    func checkObjectives() -> Bool {
            return checkObjective(primaryObjective)
        }
        
        private func checkObjective(_ objective: Objective) -> Bool {
            switch objective.type {
            case "score":
                return currentProgress.score >= (objective.target ?? 0)
                
            case "total_notes":
                return currentProgress.notesHit >= (objective.target ?? 0)
                
            case "note_accuracy":
                return currentProgress.notesHit >= (objective.target ?? 0) &&
                       currentProgress.averageAccuracy >= (objective.minimumAccuracy ?? 0)
                
            case "block_destruction":
                guard let details = objective.details else { return false }
                // All blocks must reach their target
                return details.allSatisfy { blockType, required in
                    currentProgress.blocksByType[blockType, default: 0] >= required
                }
                
            case "total_blocks":
                return currentProgress.totalBlocksDestroyed >= (objective.target ?? 0)
                
            default:
                return false
            }
        }
    
    // MARK: - Progress Information
    
    func getProgress() -> Double {
            return calculateProgress(for: primaryObjective)
        }
        
        func getCurrentProgress() -> ObjectiveProgress {
            return currentProgress
        }
        
        private func calculateProgress(for objective: Objective) -> Double {
            switch objective.type {
            case "score":
                let target = Double(objective.target ?? 1)
                return min(Double(currentProgress.score) / target, 1.0)
                
            case "total_notes":
                let target = Double(objective.target ?? 1)
                return min(Double(currentProgress.notesHit) / target, 1.0)
                
            case "note_accuracy":
                let noteProgress = Double(currentProgress.notesHit) / Double(objective.target ?? 1)
                let accuracyProgress = currentProgress.averageAccuracy / (objective.minimumAccuracy ?? 1.0)
                return min(min(noteProgress, accuracyProgress), 1.0)
                
            case "block_destruction":
                guard let details = objective.details else { return 0 }
                let progressByType = details.map { blockType, required in
                    Double(currentProgress.blocksByType[blockType, default: 0]) / Double(required)
                }
                // Always use min since we now require all blocks to be destroyed
                return min(progressByType.min() ?? 0, 1.0)
                
            case "total_blocks":
                let target = Double(objective.target ?? 1)
                return min(Double(currentProgress.totalBlocksDestroyed) / target, 1.0)
                
            default:
                return 0
            }
        }
    }
