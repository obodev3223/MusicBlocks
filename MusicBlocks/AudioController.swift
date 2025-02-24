//
//  AudioController.swift
//  FrikiTuner
//
//  Created by Jose R. García on 10/2/25.
//
/// AudioController: Controlador singleton para gestión del audio
///
/// Características principales:
/// - Gestiona la entrada de audio y detección de pitch
/// - Implementa el patrón Singleton con sharedInstance
/// - Maneja la estabilidad de la frecuencia detectada
///
/// Componentes principales:
/// - pitchTapData: Datos de frecuencia y amplitud detectados
/// - stabilityDuration: Tiempo de estabilidad de la nota
/// - Configuración del motor de audio y PitchTap
/// - Funciones de control (start/stop)
/// - Gestión de permisos del micrófono
///
import AudioKit
import AudioKitEX
import AVFoundation
import SoundpipeAudioKit

class AudioController: ObservableObject {
    static let sharedInstance = AudioController()
    
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
        // Suavizar la amplitud
        smoothedAmplitude = (amplitudeSmoothing * smoothedAmplitude) + ((1 - amplitudeSmoothing) * amplitude)
        
        // Verificar si ha pasado suficiente tiempo desde el último procesamiento
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastProcessedTime) >= minimumProcessingInterval else {
            return
        }
        lastProcessedTime = currentTime
        
        // Verificar condiciones para procesar el pitch
        if smoothedAmplitude > minimumAmplitude {
            if frequency >= minimumFrequency && frequency <= maximumFrequency {
                let tunerData = tunerEngine.processPitch(
                    frequency: frequency,
                    amplitude: smoothedAmplitude
                )
                DispatchQueue.main.async {
                    self.tunerData = tunerData
                }
                updateStability(frequency: frequency)
            }
        } else {
            DispatchQueue.main.async {
                self.tunerData = .inactive
                self.stabilityDuration = 0
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
        // Limpiar estados al detener
        DispatchQueue.main.async {
            self.tunerData = .inactive
            self.stabilityDuration = 0
        }
    }
}
