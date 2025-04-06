//
//  AudioController.swift
//  MusicBlocks
//
//  Created by Jose R. García on 20/3/25.
//  Refactorizado: Funcionalidad de sonidos UI movida a UISoundController.swift
//  Mejorado: Sistema de detección de ataque para instrumentos clásicos
//

import AudioKit
import AudioKitEX
import AVFoundation
import SoundpipeAudioKit
import Foundation

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
    // Método para obtener el tiempo requerido para mantener la nota (hold)
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
    private let uiSoundController = UISoundController.shared
    
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
    
    // MARK: - Nuevas propiedades para mejorar la detección de ataque
    private var frequencyBuffer: [Float] = []
    private var amplitudeBuffer: [Float] = []
    private let bufferSize = 10 // Tamaño del buffer para promediar (ajustar según necesidades)
    private var attackPhaseDetected = false
    private var attackPhaseStartTime: Date?
    private let attackPhaseMaxDuration: TimeInterval = 0.5 // Duración máxima de la fase de ataque (500ms)
    private var sustainPhaseFrequencies: [Float] = []
    private var smoothedFrequency: Float = 0
    private let frequencySmoothing: Float = 0.8 // Factor de suavizado para la frecuencia
    private var noteStabilityCounter = 0
    private let requiredStabilityCount = 5 // Número de lecturas estables necesarias para confirmar nota
    
    // MARK: - Properties para acceder a los ajustes de sonido
    // (delegando al UISoundController)
    
    var musicVolume: Float {
        get { uiSoundController.musicVolume }
        set { uiSoundController.musicVolume = newValue }
    }
    
    var effectsVolume: Float {
        get { uiSoundController.effectsVolume }
        set { uiSoundController.effectsVolume = newValue }
    }
    
    var isMuted: Bool {
        get { uiSoundController.isMuted }
        set { uiSoundController.isMuted = newValue }
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
            
            // MEJORA: Añadir frecuencia y amplitud al buffer
            addToBuffers(frequency: frequency, amplitude: self.smoothedAmplitude)
            
            // MEJORA: Detectar fase de ataque vs. fase sostenida
            processAttackPhase(currentTime: currentTime)
            
            // Usar la frecuencia suavizada en lugar de la frecuencia directa
            let processedFrequency = self.smoothedFrequency
            
            // Obtener datos de afinación
            let tunerData = tunerEngine.processPitch(frequency: processedFrequency, amplitude: self.smoothedAmplitude)
            
            // Actualizar UI en tiempo real sin esperar al hold
            DispatchQueue.main.async {
                self.tunerData = tunerData
                
                // Publicar notificaciones con los datos de audio
                self.publishTunerData()
                
                // Actualizar información de estabilidad para UI
                self.updateStability(frequency: processedFrequency)
                self.publishStabilityData()
            }
            
            // MEJORA: Solo procesar detección final si estamos en fase sostenida
            if !attackPhaseDetected {
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
                            frequency: processedFrequency,
                            amplitude: self.smoothedAmplitude,
                            deviation: tunerData.deviation
                        )
                    }
                }
            }
            
        } else {
            // No hay suficiente señal - silencio
            DispatchQueue.main.async {
                self.tunerData = .inactive
                self.stabilityDuration = 0
                
                // Publicar notificaciones para el estado inactivo
                self.publishTunerData()
                self.publishStabilityData()
                
                // Reiniciar detección de ataque cuando hay silencio
                self.resetAttackDetection()
                
                self.delegate?.audioControllerDidDetectSilence(self)
            }
        }
    }
    
    // MARK: - Métodos nuevos para mejorar la detección de ataque
    
    /// Añade nuevas lecturas a los buffers de frecuencia y amplitud
    private func addToBuffers(frequency: Float, amplitude: Float) {
        // Suavizar también la frecuencia para evitar fluctuaciones rápidas
        self.smoothedFrequency = (self.frequencySmoothing * self.smoothedFrequency) +
                                ((1 - self.frequencySmoothing) * frequency)
        
        // Añadir al buffer con límite de tamaño
        frequencyBuffer.append(frequency)
        amplitudeBuffer.append(amplitude)
        
        // Mantener el buffer en el tamaño deseado
        if frequencyBuffer.count > bufferSize {
            frequencyBuffer.removeFirst()
            amplitudeBuffer.removeFirst()
        }
        
        // Si estamos en fase sostenida, recopilar muestras para análisis
        if !attackPhaseDetected && frequencyBuffer.count >= bufferSize {
            sustainPhaseFrequencies.append(calculateAverageFrequency())
            // Limitar el tamaño del historial de fase sostenida
            if sustainPhaseFrequencies.count > 30 {
                sustainPhaseFrequencies.removeFirst()
            }
        }
    }
    
    /// Procesa la detección de fase de ataque vs. fase sostenida
    private func processAttackPhase(currentTime: Date) {
        // Si no tenemos suficientes muestras, asumir que estamos en fase de ataque
        if frequencyBuffer.count < bufferSize {
            attackPhaseDetected = true
            attackPhaseStartTime = attackPhaseStartTime ?? currentTime
            return
        }
        
        // Si ya estamos en fase sostenida, mantenerla
        if !attackPhaseDetected {
            return
        }
        
        // Calcular variaciones en la amplitud y frecuencia
        let amplitudeVariation = calculateAmplitudeVariation()
        let frequencyVariation = calculateFrequencyVariation()
        
        // Detectar si hemos superado la fase de ataque
        let isStable = (amplitudeVariation < 0.15) && (frequencyVariation < 5.0)
        
        if isStable {
            noteStabilityCounter += 1
        } else {
            noteStabilityCounter = max(0, noteStabilityCounter - 1)
        }
        
        // Si hemos tenido suficientes lecturas estables, cambiar a fase sostenida
        if noteStabilityCounter >= requiredStabilityCount {
            GameLogger.shared.audioDetection("🎵 Fase de ataque terminada, comenzando fase sostenida")
            attackPhaseDetected = false
            noteStabilityCounter = 0
            attackPhaseStartTime = nil
            sustainPhaseFrequencies.removeAll()
        }
        
        // Si la fase de ataque dura demasiado tiempo, forzar cambio a fase sostenida
        if let startTime = attackPhaseStartTime,
           currentTime.timeIntervalSince(startTime) > attackPhaseMaxDuration {
            GameLogger.shared.audioDetection("⚠️ Fase de ataque forzada a terminar por tiempo máximo")
            attackPhaseDetected = false
            attackPhaseStartTime = nil
            sustainPhaseFrequencies.removeAll()
        }
    }
    
    /// Reinicia la detección de ataque
    private func resetAttackDetection() {
        attackPhaseDetected = true
        attackPhaseStartTime = nil
        frequencyBuffer.removeAll()
        amplitudeBuffer.removeAll()
        sustainPhaseFrequencies.removeAll()
        noteStabilityCounter = 0
    }
    
    /// Calcula la variación de amplitud en el buffer
    private func calculateAmplitudeVariation() -> Float {
        guard amplitudeBuffer.count >= 2 else { return 1.0 }
        
        let maxAmplitude = amplitudeBuffer.max() ?? 0
        let minAmplitude = amplitudeBuffer.min() ?? 0
        
        // Normalizar la variación respecto al valor máximo
        return maxAmplitude > 0 ? (maxAmplitude - minAmplitude) / maxAmplitude : 1.0
    }
    
    /// Calcula la variación de frecuencia en el buffer
    private func calculateFrequencyVariation() -> Float {
        guard frequencyBuffer.count >= 2 else { return 100.0 }
        
        let maxFrequency = frequencyBuffer.max() ?? 0
        let minFrequency = frequencyBuffer.min() ?? 0
        
        return maxFrequency - minFrequency
    }
    
    /// Calcula la frecuencia promedio del buffer
    private func calculateAverageFrequency() -> Float {
        guard !frequencyBuffer.isEmpty else { return 0 }
        let sum = frequencyBuffer.reduce(0, +)
        return sum / Float(frequencyBuffer.count)
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
        smoothedFrequency = 0
        stabilityDuration = 0
        lastProcessedTime = Date()
        stabilityStartTime = nil
        lastStableFrequency = 0
        tunerData = .inactive
        resetAttackDetection()
        
        pitchTap.start()
    }
    
    func stop() {
        pitchTap.stop()
        DispatchQueue.main.async {
            self.tunerData = .inactive
            self.stabilityDuration = 0
        }
    }
    
    // MARK: - Métodos para gestionar configuración de sonido
    
    /// Inicializa la configuración de sonido si no está ya establecida
    func initializeSoundSettings() {
        uiSoundController.initializeSoundSettings()
    }
    
    // MARK: - Delegación de métodos de música y sonido a UISoundController
    
    /// Inicia la música de fondo con el volumen configurado
    func startBackgroundMusicWithVolume() {
        uiSoundController.startBackgroundMusicWithVolume()
    }
    
    /// Detiene la música de fondo con un fade out
    func stopBackgroundMusic(duration: TimeInterval = 0.5) {
        uiSoundController.stopBackgroundMusic(duration: duration)
    }
    
    /// Reproduce un sonido de botón con la configuración de volumen actual
    func playButtonSoundWithVolume() {
        uiSoundController.playButtonSoundWithVolume()
    }
    
    /// Reproduce un sonido de UI específico
    func playUISound(_ type: UISoundController.UISoundType, volumeMultiplier: Float = 1.0, pitchMultiplier: Float = 1.0) {
        uiSoundController.playUISound(type, volumeMultiplier: volumeMultiplier, pitchMultiplier: pitchMultiplier)
    }
    
    /// Carga mapeos de sonidos personalizados
    func loadCustomSoundMappings() {
        uiSoundController.loadCustomSoundMappings()
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
        // Obtener el requiredTime del bloque actual a través del delegado
        let requiredTime = delegate?.audioControllerRequiredHoldTime(self) ?? 1.0
        
        NotificationCenter.default.post(
            name: .audioStabilityUpdated,
            object: self,
            userInfo: [
                "duration": stabilityDuration,
                "requiredTime": requiredTime,  // Añadir el requiredTime a la notificación
                "inAttackPhase": attackPhaseDetected  // Añadir información sobre la fase de ataque
            ]
        )
    }
}
