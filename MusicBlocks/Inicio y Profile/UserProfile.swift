//
//  UserProfile.swift
//  MusicBlocks
//
//  Created by Jose R. García on 8/3/25.
//

import Foundation

/// Estructura principal que representa el perfil del usuario en el juego.
/// Contiene toda la información personal, estadísticas y logros del jugador.
struct UserProfile: Codable {
    /// Nombre de usuario mostrado en el perfil
    var username: String
    
    /// Nombre del avatar seleccionado por el usuario
    var avatarName: String
    
    /// Estadísticas acumuladas del jugador
    var statistics: Statistics
    
    /// Logros y medallas desbloqueadas
    var achievements: Achievements
    
    /// Flag to indicate when a player has completed all available levels
    var hasCompletedAllLevels: Bool
    
    /// Nombre de usuario por defecto para nuevos perfiles
    static let defaultUsername = "Pequeño músico"
    
    /// Avatar por defecto para nuevos perfiles
    static let defaultAvatarName = "avatar1"
    
    /// Inicializador con valores por defecto para crear un nuevo perfil
    /// - Parameters:
    ///   - username: Nombre de usuario, por defecto "Pequeño músico"
    ///   - avatarName: Nombre del avatar, por defecto "avatar1"
    ///   - statistics: Estadísticas iniciales
    ///   - achievements: Logros iniciales
    ///   - hasCompletedAllLevels: Flag for all levels completion
    init(username: String = defaultUsername,
         avatarName: String = defaultAvatarName,
         statistics: Statistics = Statistics(),
         achievements: Achievements = Achievements(),
         hasCompletedAllLevels: Bool = false) {
        self.username = username
        self.avatarName = avatarName
        self.statistics = statistics
        self.achievements = achievements
        self.hasCompletedAllLevels = hasCompletedAllLevels
    }
    
    /// Carga el perfil del usuario desde UserDefaults
    /// - Returns: El perfil guardado o un nuevo perfil con valores por defecto
    static func load() -> UserProfile {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        return UserProfile()
    }
    
    /// Guarda el perfil actual en UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
    }
}

// MARK: - Statistics
/// Estructura que mantiene todas las estadísticas del jugador
struct Statistics: Codable {
    /// Puntuación total acumulada en todos los juegos
    var totalScore: Int
    
    /// Nivel actual del jugador
    var currentLevel: Int
    
    /// Tiempo total de juego en segundos
    var playTime: TimeInterval
    
    /// Número total de notas acertadas
    var notesHit: Int
    
    /// Racha actual de notas acertadas consecutivas
    var currentStreak: Int
    
    /// Mejor racha de notas acertadas consecutivas
    var bestStreak: Int
    
    /// Número de niveles completados con precisión perfecta
    var perfectLevelsCount: Int
    
    /// Número total de partidas jugadas
    var totalGamesPlayed: Int
    
    /// Precisión promedio en todas las partidas
    var averageAccuracy: Double
    
    /// Número total de partidas ganadas
    var gamesWon: Int
    
    /// Número total de partidas perdidas
    var gamesLost: Int
    
    /// Inicializador con valores por defecto para nuevas estadísticas
    init(totalScore: Int = 0,
         currentLevel: Int = 1,
         playTime: TimeInterval = 0,
         notesHit: Int = 0,
         currentStreak: Int = 0,
         bestStreak: Int = 0,
         perfectLevelsCount: Int = 0,
         totalGamesPlayed: Int = 0,
         averageAccuracy: Double = 0.0,
         gamesWon: Int = 0,
         gamesLost: Int = 0) {
        self.totalScore = totalScore
        self.currentLevel = currentLevel
        self.playTime = playTime
        self.notesHit = notesHit
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.perfectLevelsCount = perfectLevelsCount
        self.totalGamesPlayed = totalGamesPlayed
        self.averageAccuracy = averageAccuracy
        self.gamesWon = gamesWon
        self.gamesLost = gamesLost
    }
    
    
    /// Actualiza la precisión promedio con un nuevo valor
    /// - Parameter newAccuracy: Nueva precisión a incorporar en el promedio (0.0 a 1.0)
    mutating func updateAccuracy(with newAccuracy: Double) {
        if totalGamesPlayed == 0 {
            averageAccuracy = newAccuracy
        } else {
            let totalAccuracy = averageAccuracy * Double(totalGamesPlayed)
            averageAccuracy = (totalAccuracy + newAccuracy) / Double(totalGamesPlayed + 1)
        }
        totalGamesPlayed += 1
    }
    
    /// Actualiza la racha actual y, si corresponde, la mejor racha
    /// - Parameter hitNote: true si acertó la nota, false si falló
    mutating func updateStreak(hitNote: Bool) {
        if hitNote {
            currentStreak += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
        } else {
            currentStreak = 0
        }
    }
    
    /// Añade tiempo de juego al total
    /// - Parameter time: Tiempo a añadir en segundos
    mutating func addPlayTime(_ time: TimeInterval) {
        playTime += time
    }
}

// MARK: - Achievements
/// Estructura que gestiona los logros y medallas del jugador
struct Achievements: Codable {
    /// Diccionario que almacena el estado de desbloqueo de las medallas
    /// La clave es el tipo de medalla y el valor es un array de booleanos
    var unlockedMedals: [String: [Bool]]
    
    /// Fecha de la última actualización de los logros
    var lastUpdateDate: Date
    
    /// Inicializador con valores por defecto para nuevos logros
    init(unlockedMedals: [String: [Bool]] = [:], lastUpdateDate: Date = Date()) {
        self.unlockedMedals = unlockedMedals
        self.lastUpdateDate = lastUpdateDate
    }
    
    /// Actualiza el estado de una medalla específica
    /// - Parameters:
    ///   - type: Tipo de medalla
    ///   - index: Índice de la medalla en su categoría
    ///   - isUnlocked: true si se ha desbloqueado, false si no
    mutating func updateMedal(type: MedalType, index: Int, isUnlocked: Bool) {
        if unlockedMedals[type.rawValue] == nil {
            unlockedMedals[type.rawValue] = Array(repeating: false, count: 5)
        }
        unlockedMedals[type.rawValue]?[index] = isUnlocked
        lastUpdateDate = Date()
    }
    
    /// Verifica si una medalla específica está desbloqueada
    /// - Parameters:
    ///   - type: Tipo de medalla
    ///   - index: Índice de la medalla en su categoría
    /// - Returns: true si está desbloqueada, false si no
    func isMedalUnlocked(type: MedalType, index: Int) -> Bool {
        return unlockedMedals[type.rawValue]?[index] ?? false
    }
}

// MARK: - Formatters
extension Statistics {
    /// Devuelve el tiempo de juego formateado (ej: "1:30 h" o "45 min")
    var formattedPlayTime: String {
        let hours = Int(playTime) / 3600
        let minutes = Int(playTime) / 60 % 60
        if hours > 0 {
            return String(format: "%d:%02d h", hours, minutes)
        } else {
            return String(format: "%d min", minutes)
        }
    }
    
    /// Devuelve la puntuación total formateada con separadores locales
    var formattedTotalScore: String {
        return NumberFormatter.localizedString(from: NSNumber(value: totalScore), number: .decimal)
    }
    
    /// Devuelve la precisión promedio formateada como porcentaje
    var formattedAccuracy: String {
        return String(format: "%.1f%%", averageAccuracy * 100)
    }
}

// MARK: - Helper Methods
extension UserProfile {
    /// - Parameters:
    ///   - score: Puntos ganados en la partida
    ///   - noteHit: Indica si se acertó una nota
    ///   - noteHits: Nuevo parámetro para múltiples notas
    ///   - currentStreak: Nuevo parámetro para racha actual
    ///   - bestStreak: Nuevo parámetro para mejor racha
    ///   - accuracy: Precisión de la partida (0.0 a 1.0)
    ///   - levelCompleted: Indica si se completó un nivel
    ///   - isPerfect: Indica si el nivel se completó con precisión perfecta
    ///   - playTime: Tiempo jugado en la partida
    // En UserProfile.swift - método updateStatistics()

    // En UserProfile.swift - Método updateStatistics()

    mutating func updateStatistics(
        score: Int = 0,
        noteHit: Bool = false,      // Usar solo para incrementos individuales durante el juego
        noteHits: Int = 0,          // Usar para actualizar el total al final del juego
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        accuracy: Double? = nil,
        levelCompleted: Bool = false,
        isPerfect: Bool = false,
        playTime: TimeInterval = 0,
        gamesWon: Int = 0,          // Incremento para partidas ganadas (0 o 1)
        gamesLost: Int = 0) {       // Incremento para partidas perdidas (0 o 1)
            
            // Puntuación siempre se acumula
            statistics.totalScore += score
            
            // SOLO cuando estamos en modo "incremento individual"
            if noteHit {
                statistics.notesHit += 1
                statistics.updateStreak(hitNote: true)
            } else if noteHit == false && (gamesWon > 0 || gamesLost > 0) {
                // Si es una actualización de fin de juego y no hay noteHit
                statistics.updateStreak(hitNote: false)
            }
            
            // Actualización en bloque de notas acertadas (solo si hay un valor positivo)
            if noteHits > 0 {
                statistics.notesHit += noteHits
                print("🎵 Incrementadas \(noteHits) notas acertadas, total: \(statistics.notesHit)")
            }
            
            // Actualizar rachas
            if currentStreak > 0 && currentStreak > statistics.currentStreak {
                statistics.currentStreak = currentStreak
            }
            
            if bestStreak > 0 && bestStreak > statistics.bestStreak {
                statistics.bestStreak = bestStreak
            }
            
            // Actualizar precision si se proporciona
            if let accuracy = accuracy {
                // En lugar de llamar a updateAccuracy que incrementa totalGamesPlayed
                // lo hacemos manualmente para evitar incrementos extra
                if accuracy > 0 {
                    // Calculamos el nuevo promedio directamente
                    if statistics.totalGamesPlayed == 0 {
                        statistics.averageAccuracy = accuracy
                    } else {
                        let totalAccuracy = statistics.averageAccuracy * Double(statistics.totalGamesPlayed)
                        statistics.averageAccuracy = (totalAccuracy + accuracy) / Double(statistics.totalGamesPlayed + 1)
                    }
                    
                    // NO incrementamos totalGamesPlayed aquí, lo hacemos abajo
                    print("📊 Actualizada precisión a: \(statistics.formattedAccuracy)")
                }
            }
            
            // Solo contar niveles perfectos al final del juego si se indica
            if isPerfect {
                statistics.perfectLevelsCount += 1
                print("🌟 Incrementado contador de niveles perfectos: \(statistics.perfectLevelsCount)")
            }
            
            // Acumular tiempo de juego si es mayor que cero
            if playTime > 0 {
                statistics.addPlayTime(playTime)
                print("⏱️ Tiempo añadido: \(Int(playTime))s, Total: \(Int(statistics.playTime))s")
            }
            
            // Incrementar contadores de partidas SOLO si se proporciona un incremento (0 o 1)
            if gamesWon > 0 || gamesLost > 0 {
                statistics.gamesWon += gamesWon
                statistics.gamesLost += gamesLost
                
                // Recalcular el total basado en los contadores individuales
                statistics.totalGamesPlayed = statistics.gamesWon + statistics.gamesLost
                
                print("🎮 Partidas jugadas: \(statistics.totalGamesPlayed) (ganadas: \(statistics.gamesWon), perdidas: \(statistics.gamesLost))")
            }
            
            // Actualizar medallas
            MedalManager.shared.updateMedals(
                notesHit: statistics.notesHit,
                playTime: statistics.playTime,
                currentStreak: statistics.currentStreak,
                perfectTuningCount: statistics.perfectLevelsCount
            )
            
            save()
        }
    
    /// Restablece todas las estadísticas y logros a sus valores iniciales
    func resetStatistics() {
        var resetProfile = self
        resetProfile.statistics = Statistics()
        resetProfile.achievements = Achievements()
        resetProfile.save()
    }
}
