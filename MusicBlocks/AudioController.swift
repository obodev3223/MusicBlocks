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
    
    private var lastStableFrequency: Float = 0
    private var stabilityStartTime: Date?
    private let stabilityThreshold: Float = 3.0 // Variación máxima permitida en Hz
    
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
                        if amplitude[0] > 0.02 {
                            let fundamentalFreq = frequency[0]
                            if fundamentalFreq >= 20 && fundamentalFreq <= 2000 {
                                let tunerData = self.tunerEngine.processPitch(
                                    frequency: fundamentalFreq,
                                    amplitude: amplitude[0]
                                )
                                DispatchQueue.main.async {
                                    self.tunerData = tunerData
                                }
                                self.updateStability(frequency: fundamentalFreq)
                            }
                        }
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
        pitchTap.start()
    }
    
    func stop() {
        pitchTap.stop()
    }
}
