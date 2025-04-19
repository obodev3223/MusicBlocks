//
//  GameLevelProcessor.swift
//  MusicBlocks
//
//  Created by Jose R. García on 28/2/25.
//

import Foundation

// Estructuras para almacenar la configuración del juego
struct GameConfig: Codable {
    let gameVersion: String
    let objectiveTypes: ObjectiveTypes
    let accuracyThresholds: AccuracyThresholds
    let levels: [GameLevel]
    let medals: Medals
    
    enum CodingKeys: String, CodingKey {
        case gameVersion = "game_version"
        case objectiveTypes = "objective_types"
        case accuracyThresholds = "accuracy_thresholds"
        case levels
        case medals
    }
}

struct ObjectiveTypes: Codable {
    let score: ObjectiveTypeDefinition
    let totalNotes: ObjectiveTypeDefinition
    let noteAccuracy: ObjectiveTypeDefinition
    let blockDestruction: ObjectiveTypeDefinition
    let totalBlocks: ObjectiveTypeDefinition
    
    enum CodingKeys: String, CodingKey {
        case score
        case totalNotes = "total_notes"
        case noteAccuracy = "note_accuracy"
        case blockDestruction = "block_destruction"
        case totalBlocks = "total_blocks"
    }
}

struct ObjectiveTypeDefinition: Codable {
    let type: String?
    let description: String
    let params: ObjectiveParams
}

struct ObjectiveParams: Codable {
    let target: Int?
    let timeLimit: Int?
    let minimumAccuracy: Double?
    let details: [String: Int]?
    
    enum CodingKeys: String, CodingKey {
        case target
        case timeLimit = "time_limit"
        case minimumAccuracy = "minimum_accuracy"
        case details
    }
}

struct AccuracyThresholds: Codable {
    let perfect: AccuracyLevel
    let excellent: AccuracyLevel
    let good: AccuracyLevel
}

struct AccuracyLevel: Codable {
    let threshold: Double
    let multiplier: Double
}

struct GameLevel: Codable {
    let levelId: Int
    let name: String
    let maxScore: Int
    let allowedStyles: [String]
    let complexNotes: [String: Double]?
    let fallingSpeed: FallingSpeed
    let lives: Lives
    let objectives: Objectives
    let blocks: [String: Block]
    
    var requiredScore: Int {
            // Si el objetivo primario es de tipo "score", usar ese valor
            if objectives.primary.type == "score" {
                return objectives.primary.target ?? 0
            }
            // Si no, usar un valor por defecto basado en los bloques
            return blocks.values.reduce(0) { $0 + ($1.basePoints * 10) }
        }
    
    enum CodingKeys: String, CodingKey {
        case levelId = "level_id"
        case name
        case maxScore = "max_score"
        case allowedStyles = "allowed_styles"
        case complexNotes = "complex_notes" 
        case fallingSpeed = "falling_speed"
        case lives
        case objectives
        case blocks
    }
}

struct FallingSpeed: Codable {
    let initial: Double
    let increment: Double
}

struct Lives: Codable {
    let initial: Int
    let extraLives: ExtraLives
    
    enum CodingKeys: String, CodingKey {
        case initial
        case extraLives = "extra_lives"
    }
}

struct ExtraLives: Codable {
    let scoreThresholds: [Int]
    let maxExtra: Int
    
    enum CodingKeys: String, CodingKey {
        case scoreThresholds = "score_thresholds"
        case maxExtra = "max_extra"
    }
}

struct Objectives: Codable {
    let primary: Objective
}

struct Objective: Codable {
    let type: String
    let target: Int?
    let timeLimit: Int?
    let minimumAccuracy: Double?
    let details: [String: Int]?
    
    enum CodingKeys: String, CodingKey {
        case type
        case target
        case timeLimit = "time_limit"
        case minimumAccuracy = "minimum_accuracy"
        case details
    }
}

struct Block: Codable {
    let notes: [String]
    let requiredHits: Int
    let requiredTime: Double
    let style: String
    let weight: Double
    let basePoints: Int
    
    enum CodingKeys: String, CodingKey {
        case notes
        case requiredHits
        case requiredTime
        case style
        case weight
        case basePoints = "base_points"
    }
}

struct Medals: Codable {
    let notesHit: [Medal]
    let playTime: [Medal]
    let streaks: [Medal]
    let perfectTuning: [Medal]
    
    enum CodingKeys: String, CodingKey {
        case notesHit = "notes_hit"
        case playTime = "play_time"
        case streaks
        case perfectTuning = "perfect_tuning" 
    }
}

struct Medal: Codable {
    let name: String
    let requirement: String
    let image: String
    let objective: MedalObjective
}

struct MedalObjective: Codable {
    let type: String
    let target: Int
    let lifetime: Bool?
    let resetOnFail: Bool?
    let accuracy: Double?
    
    enum CodingKeys: String, CodingKey {
        case type
        case target
        case lifetime
        case resetOnFail = "reset_on_fail"
        case accuracy
    }
}

class GameLevelProcessor {
    
    /// Procesa el JSON que contiene comentarios y convierte los datos para su uso en la app
    /// - Parameter jsonString: String con el JSON que puede contener comentarios
    /// - Returns: Objeto GameConfig con la configuración del juego o nil si hay error
    static func processGameLevelsJSON(_ jsonString: String) -> GameConfig? {
        // Paso 1: Eliminar los comentarios multilinea /* ... */
        var cleanedJSON = removeMultilineComments(from: jsonString)
        
        // Paso 2: Eliminar los comentarios de una sola línea // ...
        cleanedJSON = removeSingleLineComments(from: cleanedJSON)
        
        // Paso 3: Parsear el JSON limpio
        if let jsonData = cleanedJSON.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                let gameConfig = try decoder.decode(GameConfig.self, from: jsonData)
                return gameConfig
            } catch {
                print("Error decoding JSON: \(error)")
                print("Problema en: \(error.localizedDescription)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context)")
                    case .keyNotFound(let key, let context):
                        print("Key not found: \(key) in \(context)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: \(type) in \(context)")
                    case .valueNotFound(let type, let context):
                        print("Value not found: \(type) in \(context)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                
                // Imprime el JSON limpio para facilitar la depuración
                print("JSON limpio que causó el error:")
                print(cleanedJSON)
            }
        }
        return nil
    }
    
    /// Carga el archivo game_levels.json y procesa sus datos
    /// - Returns: Objeto GameConfig con los datos del juego
    static func loadGameLevelsFromFile() -> GameConfig? {
        guard let path = Bundle.main.path(forResource: "game_levels0", ofType: "json") else {
            print("No se pudo encontrar el archivo game_levels.json")
            return nil
        }
        
        do {
            let jsonString = try String(contentsOfFile: path, encoding: .utf8)
            return processGameLevelsJSON(jsonString)
        } catch {
            print("Error al leer el archivo game_levels.json: \(error)")
            return nil
        }
    }
    
    /// Guarda la configuración del juego en un archivo JSON
    /// - Parameters:
    ///   - gameConfig: Configuración del juego a guardar
    ///   - fileName: Nombre del archivo sin extensión
    /// - Returns: Verdadero si la operación fue exitosa, falso en caso contrario
    static func saveGameConfigToFile(_ gameConfig: GameConfig, fileName: String = "+") -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(gameConfig)
            
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentsDirectory.appendingPathComponent("\(fileName).json")
                try jsonData.write(to: fileURL)
                return true
            }
        } catch {
            print("Error al guardar la configuración: \(error)")
        }
        return false
    }
    
    // MARK: - Métodos privados para procesar el JSON
    
    private static func removeMultilineComments(from input: String) -> String {
        var result = ""
        var inMultilineComment = false
        var i = input.startIndex
        
        while i < input.endIndex {
            // Detectar inicio de comentario multilínea
            if i < input.index(before: input.endIndex) &&
               input[i] == "/" && input[input.index(after: i)] == "*" {
                inMultilineComment = true
                i = input.index(after: i)  // Saltar el "/"
            }
            // Detectar fin de comentario multilínea
            else if inMultilineComment && i < input.index(before: input.endIndex) &&
                    input[i] == "*" && input[input.index(after: i)] == "/" {
                inMultilineComment = false
                i = input.index(i, offsetBy: 2)  // Saltar "*/"
                continue
            }
            
            // Si no estamos en un comentario, añadir el caracter al resultado
            if !inMultilineComment {
                result.append(input[i])
            }
            
            i = input.index(after: i)
        }
        
        return result
    }
    
    private static func removeSingleLineComments(from input: String) -> String {
        var result = ""
        var inString = false
        var inSingleLineComment = false
        var i = input.startIndex
        
        while i < input.endIndex {
            let currentChar = input[i]
            
            // Manejar inicio/fin de cadenas de texto
            if currentChar == "\"" {
                // Verificar que la comilla no esté escapada
                if i > input.startIndex && input[input.index(before: i)] != "\\" {
                    inString = !inString
                }
            }
            
            // Detectar inicio de comentario de una línea (solo fuera de cadenas de texto)
            if !inString && i < input.index(before: input.endIndex) &&
               currentChar == "/" && input[input.index(after: i)] == "/" {
                inSingleLineComment = true
            }
            
            // Fin de línea termina un comentario de una línea
            if inSingleLineComment && (currentChar == "\n" || currentChar == "\r") {
                inSingleLineComment = false
                // Preservamos los saltos de línea para mantener la estructura del documento
                result.append(currentChar)
            }
            // Si no estamos en un comentario, añadir el caracter al resultado
            else if !inSingleLineComment {
                result.append(currentChar)
            }
            
            i = input.index(after: i)
        }
        
        return result
    }
    
    // MARK: - Métodos de acceso para usar los datos en la aplicación
    
    /// Obtiene los niveles disponibles en el juego
    /// - Parameter gameConfig: Configuración del juego
    /// - Returns: Array de niveles
    static func getLevels(from gameConfig: GameConfig) -> [GameLevel] {
        return gameConfig.levels
    }
    
    /// Obtiene los tipos de objetivos disponibles en el juego
    /// - Parameter gameConfig: Configuración del juego
    /// - Returns: Tipos de objetivos
    static func getObjectiveTypes(from gameConfig: GameConfig) -> ObjectiveTypes {
        return gameConfig.objectiveTypes
    }
    
    /// Obtiene los umbrales de precisión para las calificaciones
    /// - Parameter gameConfig: Configuración del juego
    /// - Returns: Umbrales de precisión
    static func getAccuracyThresholds(from gameConfig: GameConfig) -> AccuracyThresholds {
        return gameConfig.accuracyThresholds
    }
    
    /// Obtiene las medallas disponibles en el juego
    /// - Parameter gameConfig: Configuración del juego
    /// - Returns: Configuración de medallas
    static func getMedals(from gameConfig: GameConfig) -> Medals {
        return gameConfig.medals
    }
    
    /// Obtiene un nivel específico por su ID
    /// - Parameters:
    ///   - gameConfig: Configuración del juego
    ///   - id: ID del nivel
    /// - Returns: El nivel solicitado o nil si no existe
    static func getLevel(from gameConfig: GameConfig, withId id: Int) -> GameLevel? {
        if let level = gameConfig.levels.first(where: { $0.levelId == id }) {
            print("📋 Nivel \(id) encontrado: \(level.name)")
            
            // Información detallada sobre objetivos
            print("🎯 OBJETIVOS DEL NIVEL \(id):")
            let objective = level.objectives.primary
            print("  • Tipo: \(objective.type)")
            
            // Mostrar parámetros específicos según el tipo de objetivo
            switch objective.type {
            case "score":
                print("  • Puntuación objetivo: \(objective.target ?? 0)")
                if let timeLimit = objective.timeLimit {
                    print("  • Límite de tiempo: \(timeLimit) segundos")
                }
                
            case "total_notes":
                print("  • Notas a acertar: \(objective.target ?? 0)")
                if let timeLimit = objective.timeLimit {
                    print("  • Límite de tiempo: \(timeLimit) segundos")
                }
                
            case "note_accuracy":
                print("  • Notas a acertar: \(objective.target ?? 0)")
                if let minAccuracy = objective.minimumAccuracy {
                    print("  • Precisión mínima: \(Int(minAccuracy * 100))%")
                }
                if let timeLimit = objective.timeLimit {
                    print("  • Límite de tiempo: \(timeLimit) segundos")
                }
                
            case "block_destruction":
                print("  • Bloques a destruir por tipo:")
                if let details = objective.details {
                    for (blockType, count) in details {
                        print("    - \(blockType): \(count)")
                    }
                }
                if let timeLimit = objective.timeLimit {
                    print("  • Límite de tiempo: \(timeLimit) segundos")
                }
                
            case "total_blocks":
                print("  • Total de bloques a destruir: \(objective.target ?? 0)")
                if let timeLimit = objective.timeLimit {
                    print("  • Límite de tiempo: \(timeLimit) segundos")
                }
                
            default:
                print("  • Tipo de objetivo desconocido")
            }
            
            // Información sobre estilos permitidos
            print("📦 Estilos de bloques permitidos: \(level.allowedStyles)")
            
            // Información sobre bloques configurados
            print("🧱 Bloques configurados:")
            for (style, block) in level.blocks {
                print("  • \(style):")
                print("    - Notas: \(block.notes)")
                print("    - Estilo: \(block.style)")
                print("    - Golpes requeridos: \(block.requiredHits)")
                print("    - Tiempo requerido: \(block.requiredTime)s")
                print("    - Peso: \(block.weight)")
                print("    - Puntos base: \(block.basePoints)")
            }
            
            // Información sobre vidas
            print("❤️ Vidas: \(level.lives.initial) (extras: máx \(level.lives.extraLives.maxExtra))")
            
            // Información sobre velocidad
            print("⏱️ Velocidad: inicial \(level.fallingSpeed.initial)s, incremento \(level.fallingSpeed.increment)s")
            
            return level
        }
        print("❌ No se encontró el nivel con ID \(id)")
        return nil
    }
    
    /// Obtiene los bloques disponibles en un nivel específico
    /// - Parameter level: Nivel del juego
    /// - Returns: Diccionario con los bloques disponibles
    static func getBlocks(from level: GameLevel) -> [String: Block] {
        return level.blocks
    }
    
    /// Corrige una versión JSON existente para adaptarla a los cambios de estructura
    /// - Parameter jsonString: Contenido del archivo JSON a corregir
    /// - Returns: JSON corregido o nil si hay error
    static func fixJSONStructure(_ jsonString: String) -> String? {
        // Primero limpiamos los comentarios
        var cleanedJSON = removeMultilineComments(from: jsonString)
        cleanedJSON = removeSingleLineComments(from: cleanedJSON)
        
        return cleanedJSON
    }
}
