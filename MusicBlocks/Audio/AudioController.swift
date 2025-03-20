//
//  AudioController.swift
//  MusicBlocks
//
//  Created by Jose R. García on 13/3/25.
//  Actualizado para obtener dinámicamente el requiredHoldTime del bloque actual.
//

import AudioKit
import AudioKitEX
import AVFoundation
import SoundpipeAudioKit

// Extensión para centralizar las definiciones de notificaciones de audio
extension Notification.Name {
    // Notificación para actualización de datos de afinación y nota detectada
    static let audioTunerDataUpdated = Notification.Name("audioTunerDataUpdated")
    
    // Notificación para actualización de estabilidad de la nota
    static let audioStabilityUpdated = Notification.Name("audioStabilityUpdated")
}

protocol AudioControllerDelegate: AnyObject {
    func audioController(_ controller: AudioController, didDetectNote note: String, frequency: Float, amplitude: Float, deviation: Double)
    func audioControllerDidDetectSilence(_ controller: AudioController)
    // Nuevo método para obtener el tiempo requerido para mantener la nota (hold)
    func audioControllerRequiredHoldTime(_ controller: AudioController) -> TimeInterval
}

class AudioController: ObservableObject {
    static let sharedInstance = AudioController()
    weak var delegate: AudioControllerDelegate?
    
    // MARK: - Estructura que contiene mapeos personalizados de tipos de sonido a archivos
        struct CustomSoundMap: Codable {
            var soundMappings: [String: String] = [:]
            
            // Método para obtener el nombre de archivo para un tipo de sonido
            func fileName(for soundType: UISoundType) -> String? {
                return soundMappings[soundType.fileName]
            }
        }
        
        // Variable para almacenar mapeos personalizados
        private var customSoundMap: CustomSoundMap = CustomSoundMap()
    
    // MARK: - Agregar propiedades para controlar el debouncing
    private var lastSuccessfulNoteTime: Date? = nil
    private let minimumTimeBetweenNotes: TimeInterval = 0.8 // 800ms mínimo entre notas exitosas
    
    @Published var tunerData: TunerEngine.TunerData = .inactive
    @Published var stabilityDuration: TimeInterval = 0
    
    private let tunerEngine = TunerEngine.shared
    
    let engine = AudioEngine()
    var pitchTap: PitchTap!
    var mic: AudioEngine.InputNode!
    var silence: Fader!
    
    // Umbrales y configuración
    private let minimumAmplitude: Float = 0.02
    private let minimumFrequency: Float = 20.0
    private let maximumFrequency: Float = 2000.0
    private let stabilityThreshold: Float = 3.0 // Variación máxima permitida en Hz
    private let amplitudeSmoothing: Float = 0.9 // Factor de suavizado para la amplitud
    
    // Variables de seguimiento
    private var lastStableFrequency: Float = 0
    private var stabilityStartTime: Date?
    private var smoothedAmplitude: Float = 0
    private var lastProcessedTime: Date = Date()
    private let minimumProcessingInterval: TimeInterval = 0.05 // 50ms entre procesamientos
    
    // MARK: - Nueva funcionalidad: Música de fondo y efectos de sonido
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    /// Inicia la música de fondo en el menú.
    /// Asegúrate de haber añadido "backgroundMusic.mp3" al bundle de tu proyecto.
    ///
    func startBackgroundMusic() {
        // Si el reproductor ya existe y está reproduciendo, no hacemos nada
        if let player = backgroundMusicPlayer, player.isPlaying {
            print("La música de fondo ya se está reproduciendo")
            return
        }
        guard let url = Bundle.main.url(forResource: "backgroundMusic", withExtension: "mp3")
        else {
            print("No se encontró el archivo de música de fondo")
            return
        }
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1
            // Loop infinito
            let targetVolume: Float = 0.5
            backgroundMusicPlayer?.volume = 0.3
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
            fadeInBackgroundMusic(to: targetVolume, duration: 1.0)
            print("Música de fondo iniciada con fade in")
        }   catch {
            print("Error al reproducir la música de fondo: (error)")
        }
    }
    
    
    /// Función privada para realizar el fade in de la música de fondo.
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
    
    /// Detiene la música de fondo.
    func stopBackgroundMusic (duration: TimeInterval = 0.5) {
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
        print("AudioController: Iniciando fade out de la música de fondo")
    }
    
    // MARK: - Funciones para detección de notas
    private func updateStability(frequency: Float) {
        if abs(frequency - lastStableFrequency) <= stabilityThreshold {
            if stabilityStartTime == nil {
                stabilityStartTime = Date()
            }
            stabilityDuration = Date().timeIntervalSince(stabilityStartTime ?? Date())
        } else {
            lastStableFrequency = frequency
            stabilityStartTime = nil
            stabilityDuration = 0
        }
    }
    
    private func processPitchData(frequency: Float, amplitude: Float) {
        // Suavizar la amplitud para evitar fluctuaciones bruscas
        self.smoothedAmplitude = (self.amplitudeSmoothing * self.smoothedAmplitude) +
                                 ((1 - self.amplitudeSmoothing) * amplitude)
        
        // Limitar tasa de procesamiento para rendimiento
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastProcessedTime) >= minimumProcessingInterval else {
            return
        }
        lastProcessedTime = currentTime
        
        // Verificar que la señal tiene suficiente volumen y está en rango de frecuencia
        if self.smoothedAmplitude > minimumAmplitude,
           frequency >= minimumFrequency && frequency <= maximumFrequency {
            
            // Obtener datos de afinación
            let tunerData = tunerEngine.processPitch(frequency: frequency, amplitude: self.smoothedAmplitude)
            
            // Actualizar UI en tiempo real sin esperar al hold
            DispatchQueue.main.async {
                self.tunerData = tunerData
                
                // NUEVO: Publicar notificaciones con los datos de audio
                self.publishTunerData()
                
                // Actualizar información de estabilidad para UI
                self.updateStability(frequency: frequency)
                self.publishStabilityData()
            }
            
            // Validación del tiempo de "hold" y precisión requeridos
            let requiredHoldTime = delegate?.audioControllerRequiredHoldTime(self) ?? 1.0
            
            // Comprobar si la nota se ha mantenido el tiempo necesario
            if tunerEngine.updateHoldDetection(
                note: tunerData.note,
                currentTime: currentTime.timeIntervalSinceReferenceDate,
                requiredHoldTime: requiredHoldTime
            ) {
                DispatchQueue.main.async {
                    GameLogger.shared.audioDetection("✅ Nota \(tunerData.note) validada tras mantenerla \(requiredHoldTime) segundos")
                    self.delegate?.audioController(
                        self,
                        didDetectNote: tunerData.note,
                        frequency: frequency,
                        amplitude: self.smoothedAmplitude,
                        deviation: tunerData.deviation
                    )
                }
            }
            
        } else {
            // No hay suficiente señal - silencio
            DispatchQueue.main.async {
                self.tunerData = .inactive
                self.stabilityDuration = 0
                
                // NUEVO: Publicar notificaciones para el estado inactivo
                self.publishTunerData()
                self.publishStabilityData()
                
                self.delegate?.audioControllerDidDetectSilence(self)
            }
        }
    }
    
    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                            options: [.defaultToSpeaker, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            guard let input = engine.input else {
                print("Error: No se detectó entrada de audio")
                return
            }
            
            mic = input
            silence = Fader(mic, gain: 0)
            engine.output = silence
            
            pitchTap = PitchTap(mic) { [weak self] frequency, amplitude in
                guard let self = self else { return }
                self.processPitchData(frequency: frequency[0], amplitude: amplitude[0])
            }
            
            try engine.start()
            print("Motor de audio iniciado correctamente")
            
        } catch {
            print("Error en la inicialización del audio: \(error)")
        }
    }
    
    var microphonePermissionStatus: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    func start() {
        guard mic != nil else {
            print("Error: Input de audio no disponible")
            return
        }
        // Resetear valores al iniciar
        smoothedAmplitude = 0
        stabilityDuration = 0
        lastProcessedTime = Date()
        stabilityStartTime = nil
        lastStableFrequency = 0
        tunerData = .inactive
        
        pitchTap.start()
    }
    
    func stop() {
        pitchTap.stop()
        DispatchQueue.main.async {
            self.tunerData = .inactive
            self.stabilityDuration = 0
        }
    }
}

// Extensión para AudioController para publicar notificaciones
extension AudioController {
    // Método para publicar datos del afinador
    func publishTunerData() {
        // Enviar notificación con los datos actuales del afinador
        NotificationCenter.default.post(
            name: .audioTunerDataUpdated,
            object: self,
            userInfo: [
                "note": tunerData.note,
                "frequency": tunerData.frequency,
                "deviation": tunerData.deviation,
                "isActive": tunerData.isActive
            ]
        )
    }
    
    // Método para publicar datos de estabilidad
    func publishStabilityData() {
        NotificationCenter.default.post(
            name: .audioStabilityUpdated,
            object: self,
            userInfo: [
                "duration": stabilityDuration
            ]
        )
    }
}

// Extensión para AudioController para controlar volumen
extension AudioController {
    // MARK: - Sound Settings
    
    // Default values for sound settings
    private struct SoundSettings {
        static let defaultMusicVolume: Float = 0.5
        static let defaultEffectsVolume: Float = 0.8
        static let defaultIsMuted: Bool = false
    }
    
    // Keys for storing sound settings in UserDefaults
    private struct SoundSettingsKeys {
        static let musicVolume = "musicVolume"
        static let effectsVolume = "effectsVolume"
        static let isMuted = "isMuted"
    }
    
    // Get current music volume (0.0 to 1.0)
    var musicVolume: Float {
        get {
            UserDefaults.standard.float(forKey: SoundSettingsKeys.musicVolume)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SoundSettingsKeys.musicVolume)
            applyMusicVolume()
        }
    }
    
    // Get current effects volume (0.0 to 1.0)
    var effectsVolume: Float {
        get {
            UserDefaults.standard.float(forKey: SoundSettingsKeys.effectsVolume)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SoundSettingsKeys.effectsVolume)
        }
    }
    
    // Get/set muted state
    var isMuted: Bool {
        get {
            UserDefaults.standard.bool(forKey: SoundSettingsKeys.isMuted)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SoundSettingsKeys.isMuted)
            applyMuteState()
        }
    }
    
    // Initialize sound settings if not already set
    func initializeSoundSettings() {
        // Only set default values if they don't exist
        if UserDefaults.standard.object(forKey: SoundSettingsKeys.musicVolume) == nil {
            UserDefaults.standard.set(SoundSettings.defaultMusicVolume, forKey: SoundSettingsKeys.musicVolume)
        }
        
        if UserDefaults.standard.object(forKey: SoundSettingsKeys.effectsVolume) == nil {
            UserDefaults.standard.set(SoundSettings.defaultEffectsVolume, forKey: SoundSettingsKeys.effectsVolume)
        }
        
        if UserDefaults.standard.object(forKey: SoundSettingsKeys.isMuted) == nil {
            UserDefaults.standard.set(SoundSettings.defaultIsMuted, forKey: SoundSettingsKeys.isMuted)
        }
        
        // Apply the settings
        applyMusicVolume()
        applyMuteState()
    }
    
    // Apply music volume to the player
    private func applyMusicVolume() {
        if let player = backgroundMusicPlayer {
            // If muted, volume is 0, otherwise use stored volume
            player.volume = isMuted ? 0.0 : musicVolume
        }
    }
    
    // Apply mute state to all audio
    private func applyMuteState() {
        if let player = backgroundMusicPlayer {
            player.volume = isMuted ? 0.0 : musicVolume
        }
    }

    /// Reproduce un efecto de sonido para la pulsación de un botón.
    /// Asegúrate de haber añadido "buttonClick.mp3" al bundle.
    func playButtonSoundWithVolume() {
        // Skip if muted or if volume is set to 0
        guard !isMuted && effectsVolume > 0 else { return }
        
        guard let url = Bundle.main.url(forResource: "buttonClick", withExtension: "mp3") else {
            print("AudioController: No se encontró el archivo buttonClick.mp3, usando sonido generado")
            generateSimpleButtonSound()
            return
        }
        
        do {
            let buttonSoundPlayer = try AVAudioPlayer(contentsOf: url)
            buttonSoundPlayer.volume = effectsVolume
            buttonSoundPlayer.prepareToPlay()
            buttonSoundPlayer.play()
        } catch {
            print("AudioController: Error al reproducir sonido de botón, usando sonido generado: \(error)")
            generateSimpleButtonSound()
        }
    }
    
    // Update the startBackgroundMusic method to respect volume settings
    func startBackgroundMusicWithVolume() {
        // If the player already exists and is playing, don't do anything
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
            
            // Apply current volume settings
            let targetVolume = isMuted ? 0.0 : musicVolume
            backgroundMusicPlayer?.volume = 0.0 // Start silent and fade in
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
            
            // Only fade in if not muted
            if !isMuted {
                fadeInBackgroundMusic(to: targetVolume, duration: 1.0)
            }
            
            print("Música de fondo iniciada con volumen \(targetVolume)")
        } catch {
            print("Error al reproducir la música de fondo: \(error)")
        }
    }
    
    // Añadir este método para generar un sonido simple en caso de que no exista un archivo
    func generateSimpleButtonSound() {
        guard !isMuted && effectsVolume > 0 else { return }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, options: [.mixWithOthers])
            try audioSession.setActive(true)
            
            // Configurar un pequeño sonido de tono
            let duration: TimeInterval = 0.1
            let frequency: Double = 1000
            
            // Eliminamos la línea que no se usa
            // let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
            
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
            print("AudioController: Error al generar sonido simple: \(error)")
        }
    }
}

extension AudioController {

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
    

        
        // Método para cargar configuración de sonidos personalizada
        func loadCustomSoundMappings() {
            if let data = UserDefaults.standard.data(forKey: "customSoundMappings"),
               let loadedMap = try? JSONDecoder().decode(CustomSoundMap.self, from: data) {
                customSoundMap = loadedMap
                print("Mapeo de sonidos personalizado cargado con \(loadedMap.soundMappings.count) entradas")
            }
        }
        
        // Método para guardar configuración de sonidos personalizada
        func saveCustomSoundMapping(type: UISoundType, fileName: String) {
            customSoundMap.soundMappings[type.fileName] = fileName
            
            if let encoded = try? JSONEncoder().encode(customSoundMap) {
                UserDefaults.standard.set(encoded, forKey: "customSoundMappings")
                print("Mapeo de sonido guardado: \(type.fileName) -> \(fileName)")
            }
        }
    
    
    
    
    // Método para verificar si el archivo de sonido existe y, si no, crear uno básico
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
    
    // Mejorar el método playButtonSoundWithVolume para buscar en más ubicaciones
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
    
    // Método mejorado para reproducir sonido que considera mapeos personalizados
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
    
    // Método para intentar reproducir un sonido desde un archivo
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
       
       // Método para generar un tono simple como último recurso
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
        
    // Generador simple para sonidos de UI
    private func generateSimpleUISound(pitch: Float, volume: Float) {
        // Similar a generateSimpleButtonSound pero con control de tono
        // Como esto requeriría una implementación más compleja con AVAudioEngine,
        // podríamos usar un enfoque simplificado para generar un sonido breve
        
        // Usamos SystemSoundServices para un sonido simple del sistema si falla todo lo demás
        AudioServicesPlaySystemSound(1104) // Este es un sonido de sistema genérico
    }
}
