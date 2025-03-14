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

protocol AudioControllerDelegate: AnyObject {
    func audioController(_ controller: AudioController, didDetectNote note: String, frequency: Float, amplitude: Float, deviation: Double)
    func audioControllerDidDetectSilence(_ controller: AudioController)
    // Nuevo método para obtener el tiempo requerido para mantener la nota (hold)
    func audioControllerRequiredHoldTime(_ controller: AudioController) -> TimeInterval
}

class AudioController: ObservableObject {
    static let sharedInstance = AudioController()
    weak var delegate: AudioControllerDelegate?
    
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
        self.smoothedAmplitude = (self.amplitudeSmoothing * self.smoothedAmplitude) + ((1 - self.amplitudeSmoothing) * amplitude)
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastProcessedTime) >= minimumProcessingInterval else {
            return
        }
        lastProcessedTime = currentTime
        
        if self.smoothedAmplitude > minimumAmplitude,
           frequency >= minimumFrequency && frequency <= maximumFrequency {
            
            let tunerData = tunerEngine.processPitch(frequency: frequency, amplitude: self.smoothedAmplitude)
            // Actualiza la UI en tiempo real sin esperar al hold:
            DispatchQueue.main.async {
                // Por ejemplo, podrías notificar al delegado o actualizar una propiedad publicada
                // Aquí actualizamos el tunerData para que los nodos que observan esa propiedad se actualicen:
                self.tunerData = tunerData
                // Si tienes otro mecanismo para actualizar la UI, hazlo aquí.
            }
            
            // Luego, si se cumple el hold, dispara el evento de acierto
            let requiredHoldTime = delegate?.audioControllerRequiredHoldTime(self) ?? 1.0
            if tunerEngine.updateHoldDetection(note: tunerData.note,
                                               currentTime: currentTime.timeIntervalSinceReferenceDate,
                                               requiredHoldTime: requiredHoldTime) {
                DispatchQueue.main.async {
                    print("🎵 Nota validada tras hold: \(tunerData.note) (requiredHoldTime: \(requiredHoldTime) s)")
                    self.delegate?.audioController(self, didDetectNote: tunerData.note, frequency: frequency, amplitude: self.smoothedAmplitude, deviation: tunerData.deviation)
                }
            }
            updateStability(frequency: frequency)
        } else {
            DispatchQueue.main.async {
                self.tunerData = .inactive
                self.stabilityDuration = 0
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
