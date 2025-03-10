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
    
//    struct ObjectiveProgress {
//        var score: Int = 0
//        var notesHit: Int = 0
//        var accuracySum: Double = 0
//        var accuracyCount: Int = 0
//        var blocksByType: [String: Int] = [:]
//        var totalBlocksDestroyed: Int = 0
//        var timeElapsed: TimeInterval = 0
//        
//        var averageAccuracy: Double {
//            return accuracyCount > 0 ? accuracySum / Double(accuracyCount) : 0
//        }
//    }
    
    init(level: GameLevel) {
            self.primaryObjective = level.objectives.primary
            self.currentProgress = ObjectiveProgress()
            
            // Inicializar contadores de bloques para objetivo de tipo block_destruction
            if case "block_destruction" = primaryObjective.type,
               let details = primaryObjective.details {
                for (blockType, _) in details {
                    currentProgress.blocksByType[blockType] = 0
                }
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
