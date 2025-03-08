//
//  LevelObjectiveTracker.swift
//  MusicBlocks
//
//  Created by Jose R. García on 8/3/25.
//

import Foundation

class LevelObjectiveTracker {
    private let primaryObjective: Objective
    private let secondaryObjective: Objective?
    private var currentProgress: ObjectiveProgress
    
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
    
    init(level: GameLevel) {
        self.primaryObjective = level.objectives.primary
        self.secondaryObjective = level.objectives.secondary
        self.currentProgress = ObjectiveProgress()
        
        // Inicializar contadores de bloques para objetivos de tipo block_destruction
        if case "block_destruction" = primaryObjective.type,
           let details = primaryObjective.details {
            for (blockType, _) in details {
                currentProgress.blocksByType[blockType] = 0
            }
        }
        if case "block_destruction" = secondaryObjective?.type,
           let details = secondaryObjective?.details {
            for (blockType, _) in details {
                currentProgress.blocksByType[blockType] = 0
            }
        }
    }
    
    // MARK: - Progress Updates
    
    func updateProgress(score: Int? = nil,
                       noteHit: Bool? = nil,
                       accuracy: Double? = nil,
                       blockDestroyed: String? = nil,
                       deltaTime: TimeInterval? = nil) {
        // Actualizar score
        if let score = score {
            currentProgress.score = score
        }
        
        // Actualizar notas acertadas
        if let noteHit = noteHit, noteHit {
            currentProgress.notesHit += 1
        }
        
        // Actualizar precisión
        if let accuracy = accuracy {
            currentProgress.accuracySum += accuracy
            currentProgress.accuracyCount += 1
        }
        
        // Actualizar bloques destruidos
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
    
    func checkObjectives() -> (primary: Bool, secondary: Bool) {
        let primaryComplete = checkObjective(primaryObjective)
        let secondaryComplete = secondaryObjective.map(checkObjective) ?? true
        return (primaryComplete, secondaryComplete)
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
            let requireAll = objective.requireAll ?? false
            
            if requireAll {
                // Todos los tipos de bloques deben alcanzar su objetivo
                return details.allSatisfy { blockType, required in
                    currentProgress.blocksByType[blockType, default: 0] >= required
                }
            } else {
                // Al menos un tipo de bloque debe alcanzar su objetivo
                return details.contains { blockType, required in
                    currentProgress.blocksByType[blockType, default: 0] >= required
                }
            }
            
        case "total_blocks":
            return currentProgress.totalBlocksDestroyed >= (objective.target ?? 0)
            
        default:
            return false
        }
    }
    
    // MARK: - Progress Information
    
    func getProgress() -> (primary: Double, secondary: Double?) {
        let primaryProgress = calculateProgress(for: primaryObjective)
        let secondaryProgress = secondaryObjective.map(calculateProgress)
        return (primaryProgress, secondaryProgress)
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
            if objective.requireAll ?? false {
                return min(progressByType.min() ?? 0, 1.0)
            } else {
                return min(progressByType.max() ?? 0, 1.0)
            }
            
        case "total_blocks":
            let target = Double(objective.target ?? 1)
            return min(Double(currentProgress.totalBlocksDestroyed) / target, 1.0)
            
        default:
            return 0
        }
    }
}
