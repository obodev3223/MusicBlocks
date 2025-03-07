//
//  AchievementBadge.swift
//  MusicBlocks
//
//  Created by Jose R. García on 28/2/25.
//

import UIKit

// MARK: - Medal Models
struct MedalCategory {
    let type: MedalType
    let medals: [MedalInfo]
    
    var title: String {
        switch type {
        case .notesHit:
            return "Precisión Musical"
        case .playTime:
            return "Dedicación"
        case .streaks:
            return "Racha"
        case .perfectTuning:
            return "Afinación"
        }
    }
}

enum MedalType: String {
    case notesHit = "notes_hit"
    case playTime = "play_time"
    case streaks = "streaks"
    case perfectTuning = "perfect_tuning"
}

extension MedalType: CaseIterable {
    var icon: String {
        switch self {
        case .notesHit:
            return "🎵"
        case .playTime:
            return "⏱"
        case .streaks:
            return "🔥"
        case .perfectTuning:
            return "⭐️"
        }
    }
    
    var title: String {
        switch self {
        case .notesHit:
            return "Precisión Musical"
        case .playTime:
            return "Dedicación"
        case .streaks:
            return "Racha"
        case .perfectTuning:
            return "Afinación"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .notesHit:
            return "Precisión"
        case .playTime:
            return "Tiempo"
        case .streaks:
            return "Rachas"
        case .perfectTuning:
            return "Afinación"
        }
    }
}

struct MedalInfo {
    let name: String
    let requirement: String
    let image: String
    let objective: MedalObjective?
    var isUnlocked: Bool
    
    init(from medal: Medal, isUnlocked: Bool = false) {
        self.name = medal.name
        self.requirement = medal.requirement
        self.image = medal.image
        self.objective = medal.objective
        self.isUnlocked = isUnlocked
    }
}

// MARK: - Medal Manager
final class MedalManager {
    static let shared = MedalManager()
    
    private(set) var medals: [MedalCategory] = []
    private var gameConfig: GameConfig?
    
    private init() {
        loadMedals()
    }
    
    func loadMedals() {
        gameConfig = GameLevelProcessor.loadGameLevelsFromFile()
        if let config = gameConfig {
            let medalsData = GameLevelProcessor.getMedals(from: config)
            
            medals = [
                MedalCategory(type: .notesHit, medals: medalsData.notesHit.map { MedalInfo(from: $0) }),
                MedalCategory(type: .playTime, medals: medalsData.playTime.map { MedalInfo(from: $0) }),
                MedalCategory(type: .streaks, medals: medalsData.streaks.map { MedalInfo(from: $0) }),
                MedalCategory(type: .perfectTuning, medals: medalsData.perfectTuning.map { MedalInfo(from: $0) })
            ]
            loadMedalsProgress()
        }
    }
    
    func getMedals() -> [MedalCategory] {
        return medals
    }
    
    func updateMedals(notesHit: Int, playTime: TimeInterval, currentStreak: Int, perfectTuningCount: Int) {
        medals = medals.map { category in
            var updatedMedals = category.medals
            
            switch category.type {
            case .notesHit:
                updatedMedals = category.medals.map { medal in
                    var updatedMedal = medal
                    if let requirement = Int(medal.requirement.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                        updatedMedal.isUnlocked = notesHit >= requirement
                    }
                    return updatedMedal
                }
            case .playTime:
                updatedMedals = category.medals.map { medal in
                    var updatedMedal = medal
                    let playTimeHours = playTime / 3600
                    if medal.requirement.contains("minutos") {
                        if let minutes = Int(medal.requirement.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                            updatedMedal.isUnlocked = playTimeHours * 60 >= Double(minutes)
                        }
                    } else if medal.requirement.contains("horas") {
                        if let hours = Int(medal.requirement.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                            updatedMedal.isUnlocked = playTimeHours >= Double(hours)
                        }
                    }
                    return updatedMedal
                }
            case .streaks:
                updatedMedals = category.medals.map { medal in
                    var updatedMedal = medal
                    if let requirement = Int(medal.requirement.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                        updatedMedal.isUnlocked = currentStreak >= requirement
                    }
                    return updatedMedal
                }
            case .perfectTuning:
                updatedMedals = category.medals.map { medal in
                    var updatedMedal = medal
                    if let requirement = Int(medal.requirement.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                        updatedMedal.isUnlocked = perfectTuningCount >= requirement
                    }
                    return updatedMedal
                }
            }
            
            return MedalCategory(type: category.type, medals: updatedMedals)
        }
        
        saveMedalsProgress()
    }
    
    private func saveMedalsProgress() {
        let progress = medals.map { category in
            return (category.type.rawValue, category.medals.map { $0.isUnlocked })
        }
        
        let progressDict = Dictionary(uniqueKeysWithValues: progress)
        UserDefaults.standard.set(progressDict, forKey: "medalsProgress")
    }
    
    private func loadMedalsProgress() {
        if let progressDict = UserDefaults.standard.dictionary(forKey: "medalsProgress") as? [String: [Bool]] {
            medals = medals.map { category in
                let unlockedStates = progressDict[category.type.rawValue] ?? Array(repeating: false, count: category.medals.count)
                let updatedMedals = zip(category.medals, unlockedStates).map { medal, isUnlocked in
                    MedalInfo(
                        from: Medal(
                            name: medal.name,
                            requirement: medal.requirement,
                            image: medal.image,
                            objective: medal.objective ?? createDefaultObjective(for: category.type, requirement: medal.requirement)
                        ),
                        isUnlocked: isUnlocked
                    )
                }
                return MedalCategory(type: category.type, medals: updatedMedals)
            }
        }
    }

    private func createDefaultObjective(for type: MedalType, requirement: String) -> MedalObjective {
        let target = extractTarget(from: requirement)
        
        switch type {
        case .notesHit:
            return MedalObjective(
                type: type.rawValue,
                target: target,
                lifetime: true,
                resetOnFail: false,
                accuracy: nil
            )
        case .playTime:
            return MedalObjective(
                type: type.rawValue,
                target: target,
                lifetime: true,
                resetOnFail: false,
                accuracy: nil
            )
        case .streaks:
            return MedalObjective(
                type: type.rawValue,
                target: target,
                lifetime: false,
                resetOnFail: true,
                accuracy: nil
            )
        case .perfectTuning:
            return MedalObjective(
                type: type.rawValue,
                target: target,
                lifetime: true,
                resetOnFail: false,
                accuracy: 1.0
            )
        }
    }

    private func extractTarget(from requirement: String) -> Int {
        if let target = Int(requirement.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
            if requirement.contains("minutos") {
                return target * 60
            } else if requirement.contains("horas") {
                return target * 3600
            }
            return target
        }
        return 0
    }
}
