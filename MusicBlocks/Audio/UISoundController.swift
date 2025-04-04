//
//  UISoundController.swift
//  MusicBlocks
//
//  Created by Jose R. García on 20/3/25.
//

import AVFoundation
import AudioKit

/// Controlador para manejar todos los sonidos de la interfaz de usuario del juego
class UISoundController {
    // Singleton para acceso global
    static let shared = UISoundController()
    
    // MARK: - Properties
    
    // Configuración de sonido
    private struct SoundSettings {
        static let defaultMusicVolume: Float = 0.5
        static let defaultEffectsVolume: Float = 0.8
        static let defaultIsMuted: Bool = false
    }
    
    // Keys para almacenar la configuración en UserDefaults
    private struct SoundSettingsKeys {
        static let musicVolume = "musicVolume"
        static let effectsVolume = "effectsVolume"
        static let isMuted = "isMuted"
    }
    
    // Reproductor de música de fondo
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    // MARK: - Sound Settings Accessors
    
    // Volumen de la música (0.0 a 1.0)
    var musicVolume: Float {
        get {
            UserDefaults.standard.float(forKey: SoundSettingsKeys.musicVolume)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SoundSettingsKeys.musicVolume)
            applyMusicVolume()
        }
    }
    
    // Volumen de los efectos (0.0 a 1.0)
    var effectsVolume: Float {
        get {
            UserDefaults.standard.float(forKey: SoundSettingsKeys.effectsVolume)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SoundSettingsKeys.effectsVolume)
        }
    }
    
    // Estado de silencio
    var isMuted: Bool {
        get {
            UserDefaults.standard.bool(forKey: SoundSettingsKeys.isMuted)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SoundSettingsKeys.isMuted)
            applyMuteState()
        }
    }
    
    // MARK: - Sound Type Definitions
    
    // Tipos de sonidos de UI
    enum UISoundType {
        case buttonTap          // Pulsación estándar de botón
        case toggleSwitch       // Activar/desactivar interruptor
        case sliderChange       // Cambio de slider
        case expand             // Expandir panel/sección
        case collapse           // Colapsar panel/sección
        case success            // Acción exitosa
        case error              // Error o acción negativa
        case notification       // Notificación
        case countdownTick      // Tick de cuenta atrás
        case gameStart          // Inicio de juego/nivel
        case menuNavigation     // Navegación entre menús
        
        // Obtener nombre de archivo para este tipo de sonido
        var fileName: String {
            switch self {
            case .buttonTap:        return "button_tap"
            case .toggleSwitch:     return "toggle_switch"
            case .sliderChange:     return "slider_change"
            case .expand:           return "expand"
            case .collapse:         return "collapse"
            case .success:          return "success_sound"
            case .error:            return "error_sound"
            case .notification:     return "notification"
            case .countdownTick:    return "countdown_tick"
            case .gameStart:        return "game_start"
            case .menuNavigation:   return "menu_nav"
            }
        }
        
        // Volumen predeterminado para este tipo de sonido (relativo)
        var defaultVolume: Float {
            switch self {
            case .buttonTap:        return 0.7
            case .toggleSwitch:     return 0.6
            case .sliderChange:     return 0.5
            case .expand, .collapse: return 0.5
            case .success:          return 0.8
            case .error:            return 0.7
            case .notification:     return 0.7
            case .countdownTick:    return 0.6
            case .gameStart:        return 0.9
            case .menuNavigation:   return 0.6
            }
        }
        
        // Tono predeterminado para este tipo de sonido
        var defaultPitch: Float {
            switch self {
            case .buttonTap:        return 1.0
            case .toggleSwitch:     return 1.1
            case .sliderChange:     return 0.9
            case .expand:           return 1.2
            case .collapse:         return 0.8
            case .success:          return 1.3
            case .error:            return 0.7
            case .notification:     return 1.0
            case .countdownTick:    return 1.0
            case .gameStart:        return 1.5
            case .menuNavigation:   return 1.1
            }
        }
        
        // Extensiones de archivo a probar
        var fileExtensions: [String] {
            return ["mp3", "wav", "caf"]
        }
        
        // Respaldo si no existe el archivo principal
        var fallbackSoundType: UISoundType? {
            switch self {
            case .buttonTap:        return nil  // Ninguno, es el sonido básico
            case .toggleSwitch:     return .buttonTap
            case .sliderChange:     return .buttonTap
            case .expand:           return .buttonTap
            case .collapse:         return .buttonTap
            case .success:          return .buttonTap
            case .error:            return .buttonTap
            case .notification:     return .buttonTap
            case .countdownTick:    return .buttonTap
            case .gameStart:        return .buttonTap
            case .menuNavigation:   return .buttonTap
            }
        }
    }
    
    // MARK: - Custom Sound Mapping
    
    // Estructura para mapeos personalizados de tipos de sonido a archivos
    struct CustomSoundMap: Codable {
        var soundMappings: [String: String] = [:]
        
        // Método para obtener el nombre de archivo para un tipo de sonido
        func fileName(for soundType: UISoundType) -> String? {
            return soundMappings[soundType.fileName]
        }
    }
    
    // Variable para almacenar mapeos personalizados
    private var customSoundMap: CustomSoundMap = CustomSoundMap()
    
    // MARK: - Initialization
    
    private init() {
        initializeSoundSettings()
        loadCustomSoundMappings()
    }
    
    // MARK: - Sound Settings Methods
    
    // Inicializar la configuración de sonido si no está ya establecida
    func initializeSoundSettings() {
        // Establecer valores por defecto solo si no existen
        if UserDefaults.standard.object(forKey: SoundSettingsKeys.musicVolume) == nil {
            UserDefaults.standard.set(SoundSettings.defaultMusicVolume, forKey: SoundSettingsKeys.musicVolume)
        }
        
        if UserDefaults.standard.object(forKey: SoundSettingsKeys.effectsVolume) == nil {
            UserDefaults.standard.set(SoundSettings.defaultEffectsVolume, forKey: SoundSettingsKeys.effectsVolume)
        }
        
        if UserDefaults.standard.object(forKey: SoundSettingsKeys.isMuted) == nil {
            UserDefaults.standard.set(SoundSettings.defaultIsMuted, forKey: SoundSettingsKeys.isMuted)
        }
        
        // Aplicar la configuración
        applyMusicVolume()
        applyMuteState()
    }
    
    // Aplicar volumen de música al reproductor
    private func applyMusicVolume() {
        if let player = backgroundMusicPlayer {
            // Si está silenciado, volumen es 0, de lo contrario usar volumen almacenado
            player.volume = isMuted ? 0.0 : musicVolume
        }
    }
    
    // Aplicar estado de silencio a todo el audio
    private func applyMuteState() {
        if let player = backgroundMusicPlayer {
            player.volume = isMuted ? 0.0 : musicVolume
        }
    }
    
    // MARK: - Background Music Methods
    
    /// Inicia la música de fondo con el volumen configurado
    func startBackgroundMusicWithVolume() {
        // Si el reproductor ya existe y está reproduciendo, no hacer nada
        if let player = backgroundMusicPlayer, player.isPlaying {
            return
        }
        
        guard let url = Bundle.main.url(forResource: "backgroundMusic", withExtension: "mp3") else {
            print("No se encontró el archivo de música de fondo")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop infinito
            
            // Aplicar configuración de volumen actual
            let targetVolume = isMuted ? 0.0 : musicVolume
            backgroundMusicPlayer?.volume = 0.0 // Iniciar silencioso y hacer fade in
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
            
            // Solo hacer fade in si no está silenciado
            if !isMuted {
                fadeInBackgroundMusic(to: targetVolume, duration: 1.0)
            }
            
            print("Música de fondo iniciada con volumen \(targetVolume)")
        } catch {
            print("Error al reproducir la música de fondo: \(error)")
        }
    }
    
    /// Detiene la música de fondo con un fade out
    func stopBackgroundMusic(duration: TimeInterval = 0.5) {
        guard let player = backgroundMusicPlayer, player.isPlaying else {
            return
        }
        
        let fadeSteps = 5
        let fadeStepDuration = duration / Double(fadeSteps)
        let originalVolume = player.volume
        
        for step in 0...fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeStepDuration * Double(step)) {
                let fraction = Float(step) / Float(fadeSteps)
                player.volume = originalVolume * (1 - fraction)
                if step == fadeSteps {
                    player.stop()
                }
            }
        }
        print("UISoundController: Iniciando fade out de la música de fondo")
    }
    
    // Función privada para realizar el fade in de la música de fondo.
    private func fadeInBackgroundMusic(to targetVolume: Float, duration: TimeInterval) {
        guard let player = backgroundMusicPlayer else { return }
        let fadeSteps = 40
        let fadeStepDuration = duration / Double(fadeSteps)
        
        for step in 0...fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeStepDuration * Double(step)) {
                let fraction = Float(step) / Float(fadeSteps)
                player.volume = targetVolume * fraction
            }
        }
    }
    
    // MARK: - UI Sound Methods
    
    /// Reproduce un sonido de botón con la configuración de volumen actual
    func playButtonSoundWithVolume() {
        // Omitir si está silenciado o si el volumen está a 0
        guard !isMuted && effectsVolume > 0 else { return }
        
        guard let url = Bundle.main.url(forResource: "buttonClick", withExtension: "mp3") else {
            print("UISoundController: No se encontró el archivo buttonClick.mp3, usando sonido generado")
            generateSimpleButtonSound()
            return
        }
        
        do {
            let buttonSoundPlayer = try AVAudioPlayer(contentsOf: url)
            buttonSoundPlayer.volume = effectsVolume
            buttonSoundPlayer.prepareToPlay()
            buttonSoundPlayer.play()
        } catch {
            print("UISoundController: Error al reproducir sonido de botón, usando sonido generado: \(error)")
            generateSimpleButtonSound()
        }
    }
    
    /// Método mejorado para reproducir un sonido de UI que considera mapeos personalizados
    func playUISound(_ type: UISoundType, volumeMultiplier: Float = 1.0, pitchMultiplier: Float = 1.0) {
        // Salir si está silenciado o si el volumen de efectos es 0
        guard !isMuted && effectsVolume > 0 else { return }
        
        // Calcular volumen y tono finales
        let finalVolume = effectsVolume * type.defaultVolume * volumeMultiplier
        let finalPitch = type.defaultPitch * pitchMultiplier
        
        // Comprobar si hay un mapeo personalizado para este tipo de sonido
        if let customFileName = customSoundMap.fileName(for: type),
           playSound(fromFile: customFileName, extensions: type.fileExtensions, volume: finalVolume, pitch: finalPitch) {
            return
        }
        
        // Si no hay mapeo personalizado o falló, intentar con el sonido predeterminado
        if playSound(fromFile: type.fileName, extensions: type.fileExtensions, volume: finalVolume, pitch: finalPitch) {
            return
        }
        
        // Si no se pudo reproducir, intentar con el sonido de respaldo
        if let fallbackType = type.fallbackSoundType {
            if playSound(fromFile: fallbackType.fileName, extensions: fallbackType.fileExtensions,
                         volume: finalVolume, pitch: finalPitch) {
                return
            }
        }
        
        // Si todo falla, usar el generador de sonido simple
        generateSimpleTone(pitch: finalPitch, volume: finalVolume, duration: 0.1)
    }
    
    /// Método mejorado para reproducir un sonido de botón que busca en varias ubicaciones
    func improvedPlayButtonSound() {
        guard !isMuted && effectsVolume > 0 else { return }
        
        // Lista de posibles nombres de archivo y extensiones a probar
        let fileNames = ["buttonClick", "button_click", "click", "tap"]
        let extensions = ["mp3", "wav", "caf"]
        
        // Intentar cada combinación
        for fileName in fileNames {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                    do {
                        let player = try AVAudioPlayer(contentsOf: url)
                        player.volume = effectsVolume
                        player.prepareToPlay()
                        player.play()
                        print("Reproduciendo sonido: \(fileName).\(ext)")
                        return
                    } catch {
                        print("Error reproduciendo \(fileName).\(ext): \(error)")
                        continue
                    }
                }
            }
        }
        
        // Si llegamos aquí, ningún archivo funcionó, usamos el generador de sonido
        generateSimpleButtonSound()
    }
    
    // MARK: - Custom Sound Mapping Methods
    
    /// Carga la configuración de mapeos de sonido personalizados desde UserDefaults
    func loadCustomSoundMappings() {
        if let data = UserDefaults.standard.data(forKey: "customSoundMappings"),
           let loadedMap = try? JSONDecoder().decode(CustomSoundMap.self, from: data) {
            customSoundMap = loadedMap
            print("Mapeo de sonidos personalizado cargado con \(loadedMap.soundMappings.count) entradas")
        }
    }
    
    /// Guarda un mapeo personalizado para un tipo de sonido específico
    func saveCustomSoundMapping(type: UISoundType, fileName: String) {
        customSoundMap.soundMappings[type.fileName] = fileName
        
        if let encoded = try? JSONEncoder().encode(customSoundMap) {
            UserDefaults.standard.set(encoded, forKey: "customSoundMappings")
            print("Mapeo de sonido guardado: \(type.fileName) -> \(fileName)")
        }
    }
    
    // MARK: - Sound Utility Methods
    
    /// Verifica si el archivo de sonido de botón existe y, si no, crea uno básico
    func ensureButtonSoundExists() {
        // Comprobar si ya existe el archivo de sonido
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("No se pudo acceder al directorio de documentos")
            return
        }
        
        let buttonSoundFile = documentsDirectory.appendingPathComponent("buttonClick.mp3")
        
        // Si el archivo ya existe, no hacemos nada
        if fileManager.fileExists(atPath: buttonSoundFile.path) {
            return
        }
        
        // Si no existe, intentamos copiarlo desde el bundle
        if let bundleSoundPath = Bundle.main.path(forResource: "buttonClick", ofType: "mp3"),
           fileManager.fileExists(atPath: bundleSoundPath) {
            do {
                try fileManager.copyItem(atPath: bundleSoundPath, toPath: buttonSoundFile.path)
                print("Archivo de sonido copiado del bundle")
                return
            } catch {
                print("Error al copiar archivo de sonido: \(error)")
            }
        }
        
        // Si no pudimos copiarlo, generamos un archivo básico
        print("Generando archivo de sonido de botón básico...")
        
        // Nota: La generación real de archivos de audio requeriría una librería adicional
        // como AVFoundation para crear un archivo de audio completo.
        // Este código es solo un ejemplo conceptual.
    }
    
    // MARK: - Private Sound Methods
    
    /// Intenta reproducir un sonido desde un archivo
    private func playSound(fromFile baseName: String, extensions: [String], volume: Float, pitch: Float) -> Bool {
        for ext in extensions {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.volume = volume
                    if player.enableRate {
                        player.rate = pitch
                    }
                    player.prepareToPlay()
                    player.play()
                    return true
                } catch {
                    print("Error reproduciendo \(baseName).\(ext): \(error)")
                    continue
                }
            }
        }
        return false
    }
    
    /// Genera un tono simple como último recurso
    private func generateSimpleTone(pitch: Float, volume: Float, duration: TimeInterval) {
        // Implementación básica usando AudioServices como respaldo final
        let finalPitch = max(0.5, min(2.0, pitch))  // Limitar entre 0.5 y 2.0
        
        // Seleccionar un sonido del sistema según el tono
        // Diferentes sonidos del sistema para simular diferentes tonos
        let soundID: SystemSoundID
        
        if finalPitch < 0.8 {
            soundID = 1104       // Sonido más grave
        } else if finalPitch > 1.3 {
            soundID = 1106       // Sonido más agudo
        } else {
            soundID = 1105       // Sonido medio
        }
        
        AudioServicesPlaySystemSound(soundID)
    }
    
    /// Genera un sonido simple de botón cuando no se encuentra un archivo de sonido
    private func generateSimpleButtonSound() {
        guard !isMuted && effectsVolume > 0 else { return }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, options: [.mixWithOthers])
            try audioSession.setActive(true)
            
            // Configurar un pequeño sonido de tono
            let duration: TimeInterval = 0.1
            let frequency: Double = 1000
            
            let audioEngine = AVAudioEngine()
            let mainMixer = audioEngine.mainMixerNode
            
            let oscilator = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                
                for frame in 0..<Int(frameCount) {
                    // Tiempo relativo al frame actual, en segundos
                    let time = Double(frame) / 44100.0
                    
                    // Atenuación para que el sonido no sea excesivamente fuerte (efecto de fade-out)
                    let fadeFactor = max(0, 1 - time * 3) // Desaparece después de ~0.3 segundos
                    
                    // Amplitud basada en el volumen de efectos
                    let amplitude = Float(fadeFactor) * self.effectsVolume * 0.5
                    
                    // Señal del tono (onda sinusoidal simple)
                    let sample = Float(sin(2 * .pi * frequency * time)) * amplitude
                    
                    // Llenar ambos canales con la misma muestra
                    for buffer in ablPointer {
                        let buf = UnsafeMutableBufferPointer<Float>(buffer)
                        buf[frame] = sample
                    }
                }
                
                return noErr
            }
            
            let format = AVAudioFormat(standardFormatWithSampleRate: audioEngine.outputNode.outputFormat(forBus: 0).sampleRate, channels: 2)
            audioEngine.attach(oscilator)
            audioEngine.connect(oscilator, to: mainMixer, format: format)
            audioEngine.connect(mainMixer, to: audioEngine.outputNode, format: nil)
            
            try audioEngine.start()
            
            // Detener el motor después de la duración del sonido
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                audioEngine.stop()
            }
            
        } catch {
            print("UISoundController: Error al generar sonido simple: \(error)")
        }
    }
}
