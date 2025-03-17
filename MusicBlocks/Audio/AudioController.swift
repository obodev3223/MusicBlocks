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
    
    /// Reproduce un efecto de sonido para la pulsación de un botón.
    /// Asegúrate de haber añadido "buttonClick.mp3" al bundle.
    func playButtonSound() {
        guard let url = Bundle.main.url(forResource: "buttonClick", withExtension: "mp3") else {
            print("AudioController: No se encontró el efecto de sonido para botón")
            return
        }
        
        do {
            let buttonSoundPlayer = try AVAudioPlayer(contentsOf: url)
            buttonSoundPlayer.volume = 0.8
            buttonSoundPlayer.prepareToPlay()
            buttonSoundPlayer.play()
            print("AudioController: Efecto de sonido del botón reproducido")
            // Nota: Este reproductor se libera al salir del método.
        } catch {
            print("AudioController: Error al reproducir el efecto de sonido: \(error)")
        }
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
    
    // Play button sound with current effects volume
    func playButtonSoundWithVolume() {
        guard !isMuted else { return } // Skip if muted
        
        guard let url = Bundle.main.url(forResource: "buttonClick", withExtension: "mp3") else {
            print("AudioController: No se encontró el efecto de sonido para botón")
            return
        }
        
        do {
            let buttonSoundPlayer = try AVAudioPlayer(contentsOf: url)
            buttonSoundPlayer.volume = effectsVolume
            buttonSoundPlayer.prepareToPlay()
            buttonSoundPlayer.play()
        } catch {
            print("AudioController: Error al reproducir el efecto de sonido: \(error)")
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
}
