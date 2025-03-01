//
//  AchievementBadge.swift
//  FrikiTuner
//
//  Created by Jose R. García on 28/2/25.
//

import SwiftUI

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
    
    var color: Color {
        switch self {
        case .notesHit:
            return .blue
        case .playTime:
            return .red
        case .streaks:
            return .yellow
        case .perfectTuning:
            return .purple
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
            return "Perfección"
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
            return "Perfect"
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

// MARK: - Achievement Badge View
struct AchievementBadge: View {
    let title: String
    let icon: String
    let isUnlocked: Bool
    let color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                if isUnlocked {
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(isUnlocked ? .primary : .secondary)
        }
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Medal Badge View

struct MedalBadge: View {
    let medalInfo: MedalInfo
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Image(medalInfo.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .opacity(medalInfo.isUnlocked ? 1.0 : 0.3)
                
                if !medalInfo.isUnlocked {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(
                        medalInfo.isUnlocked ? color : Color.gray,
                        lineWidth: 2
                    )
                    .opacity(medalInfo.isUnlocked ? 0.8 : 0.3)
            )
            
            VStack(spacing: 4) {
                Text(medalInfo.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(medalInfo.isUnlocked ? .primary : .secondary)
                
                Text(medalInfo.requirement)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 120)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            medalInfo.isUnlocked ? color.opacity(0.3) : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .opacity(medalInfo.isUnlocked ? 1.0 : 0.8)
    }
}

// MARK: - Medals Grid View
struct MedalsGridView: View {
    let medals: [MedalCategory]
    
    var body: some View {
        VStack(spacing: 24) {
            ForEach(medals, id: \.title) { category in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(category.title)
                            .font(.headline)
                        
                        let stats = getCategoryStats(for: category)
                        Text("\(stats.unlocked)/\(stats.total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(category.medals, id: \.name) { medal in
                                MedalBadge(
                                    medalInfo: medal,
                                    color: categoryColor(for: category.type)
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .background(Color.white) // Fondo blanco para cada categoría
            }
        }
        .background(Color.white) // Fondo blanco general
    }
    
    private func getCategoryStats(for category: MedalCategory) -> (unlocked: Int, total: Int) {
        let unlockedCount = category.medals.filter { $0.isUnlocked }.count
        return (unlockedCount, category.medals.count)
    }
    
    private func categoryColor(for type: MedalType) -> Color {
        type.color
    }
}

// MARK: - Medal Manager
final class MedalManager: ObservableObject {
    static let shared = MedalManager()
    
    @Published private(set) var medals: [MedalCategory] = []
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
        objectWillChange.send()
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

    // Función auxiliar para crear objetivos por defecto según el tipo de medalla
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

    // Función auxiliar para extraer el target del requirement
    private func extractTarget(from requirement: String) -> Int {
        // Extrae los números del texto del requisito
        if let target = Int(requirement.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
            // Para tiempo de juego, convierte minutos/horas a segundos
            if requirement.contains("minutos") {
                return target * 60
            } else if requirement.contains("horas") {
                return target * 3600
            }
            return target
        }
        return 0 // valor por defecto si no se puede extraer un número
    }
}

// MARK: - Previews
// Extension para facilitar la creación de previews
extension Medal {
    static var previewMedals: [Medal] {
        [
            Medal(
                name: "Aprendiz del Pentagrama",
                requirement: "50 notas acertadas",
                image: "Badge-azul-1",
                objective: MedalObjective(
                    type: "notes_hit",
                    target: 50,
                    lifetime: true,
                    resetOnFail: false,
                    accuracy: nil
                )
            ),
            Medal(
                name: "Intérprete Prometedor",
                requirement: "250 notas acertadas",
                image: "Badge-azul-2",
                objective: MedalObjective(
                    type: "notes_hit",
                    target: 250,
                    lifetime: true,
                    resetOnFail: false,
                    accuracy: nil
                )
            ),
            Medal(
                name: "Virtuoso del Ritmo",
                requirement: "1,000 notas acertadas",
                image: "Badge-azul-3",
                objective: MedalObjective(
                    type: "notes_hit",
                    target: 1000,
                    lifetime: true,
                    resetOnFail: false,
                    accuracy: nil
                )
            ),
            Medal(
                name: "Toca y Aprende",
                requirement: "30 minutos jugados",
                image: "Badge-rojo-1",
                objective: MedalObjective(
                    type: "play_time",
                    target: 1800,
                    lifetime: true,
                    resetOnFail: false,
                    accuracy: nil
                )
            ),
            Medal(
                name: "Sesión de Ensayo",
                requirement: "2 horas jugadas",
                image: "Badge-rojo-2",
                objective: MedalObjective(
                    type: "play_time",
                    target: 7200,
                    lifetime: true,
                    resetOnFail: false,
                    accuracy: nil
                )
            )
        ]
    }
}

// Actualizar el preview
struct Previews_AchievementBadge: PreviewProvider {
    static var previews: some View {
        MedalsGridView(medals: [
            MedalCategory(
                type: .notesHit,
                medals: [
                    MedalInfo(
                        from: Medal(
                            name: "Aprendiz del Pentagrama",
                            requirement: "50 notas acertadas",
                            image: "Badge-azul-1",
                            objective: MedalObjective(
                                type: "notes_hit",
                                target: 50,
                                lifetime: true,
                                resetOnFail: false,
                                accuracy: nil
                            )
                        ),
                        isUnlocked: true
                    ),
                    MedalInfo(
                        from: Medal(
                            name: "Intérprete Prometedor",
                            requirement: "250 notas acertadas",
                            image: "Badge-azul-2",
                            objective: MedalObjective(
                                type: "notes_hit",
                                target: 250,
                                lifetime: true,
                                resetOnFail: false,
                                accuracy: nil
                            )
                        ),
                        isUnlocked: false
                    ),
                    MedalInfo(
                        from: Medal(
                            name: "Virtuoso del Ritmo",
                            requirement: "1,000 notas acertadas",
                            image: "Badge-azul-3",
                            objective: MedalObjective(
                                type: "notes_hit",
                                target: 1000,
                                lifetime: true,
                                resetOnFail: false,
                                accuracy: nil
                            )
                        ),
                        isUnlocked: false
                    )
                ]
            ),
            MedalCategory(
                type: .playTime,
                medals: [
                    MedalInfo(
                        from: Medal(
                            name: "Toca y Aprende",
                            requirement: "30 minutos jugados",
                            image: "Badge-rojo-1",
                            objective: MedalObjective(
                                type: "play_time",
                                target: 1800,
                                lifetime: true,
                                resetOnFail: false,
                                accuracy: nil
                            )
                        ),
                        isUnlocked: true
                    ),
                    MedalInfo(
                        from: Medal(
                            name: "Sesión de Ensayo",
                            requirement: "2 horas jugadas",
                            image: "Badge-rojo-2",
                            objective: MedalObjective(
                                type: "play_time",
                                target: 7200,
                                lifetime: true,
                                resetOnFail: false,
                                accuracy: nil
                            )
                        ),
                        isUnlocked: false
                    )
                ]
            )
        ])
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Medals Grid")
    }
}
