// Archivo: TimeDirectUpdater.swift (Nuevo archivo)
// Esta será una clase completamente nueva que se encargará exclusivamente
// de actualizar las etiquetas de tiempo en la UI, sin depender de la jerarquía actual.

import SpriteKit
import UIKit

class TimeDirectUpdater {
    // Singleton para fácil acceso
    static let shared = TimeDirectUpdater()
    
    // Referencias a las etiquetas que muestran tiempo
    private var timeLabels: [SKLabelNode] = []
    
    // Estado
    private var isActive = false
    private var startTime: Date?
    private var timeLimit: TimeInterval = 180 // Default 3 minutos
    
    // Timer de alta precisión
    private var displayLink: CADisplayLink?
    
    // Inicialización privada para singleton
    private init() {}
    
    // Registrar una etiqueta para actualizarla directamente
    func registerTimeLabel(_ label: SKLabelNode) {
        if !timeLabels.contains(label) {
            timeLabels.append(label)
            print("⏱️ DirectUpdater: Etiqueta de tiempo registrada")
        }
    }
    
    // Configurar el límite de tiempo
    func setTimeLimit(_ limit: TimeInterval) {
        timeLimit = limit
        print("⏱️ DirectUpdater: Límite de tiempo establecido: \(limit)s")
        updateLabels() // Actualizar inmediatamente
    }
    
    // Iniciar la cuenta atrás
    func start() {
        guard !isActive else { return }
        
        isActive = true
        startTime = Date()
        
        // Detener displayLink existente si lo hay
        displayLink?.invalidate()
        
        // Crear nuevo displayLink para sincronizar con el refresco de pantalla
        displayLink = CADisplayLink(target: self, selector: #selector(updateLabels))
        displayLink?.add(to: .main, forMode: .common)
        
        print("⏱️ DirectUpdater: Cuenta atrás iniciada con displayLink")
    }
    
    // Detener la cuenta atrás
    func stop() {
        isActive = false
        displayLink?.invalidate()
        displayLink = nil
        print("⏱️ DirectUpdater: Cuenta atrás detenida")
    }
    
    // Resetear el tiempo
    func reset() {
        stop()
        startTime = nil
        updateLabels() // Actualizar a estado inicial
        print("⏱️ DirectUpdater: Cuenta atrás reseteada")
    }
    
    // Actualizar todas las etiquetas registradas
    @objc private func updateLabels() {
        if !isActive || timeLabels.isEmpty {
            // Si no está activo, mostrar el tiempo completo
            let minutes = Int(timeLimit) / 60
            let seconds = Int(timeLimit) % 60
            let timeText = String(format: "%02d:%02d", minutes, seconds)
            
            DispatchQueue.main.async {
                for label in self.timeLabels {
                    label.text = timeText
                    label.fontColor = .darkGray
                }
            }
            return
        }
        
        guard let start = startTime else { return }
        
        // Calcular tiempo transcurrido y restante
        let elapsedTime = Date().timeIntervalSince(start)
        let remainingTime = max(timeLimit - elapsedTime, 0)
        
        // Formatear tiempo para mostrar
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        let timeText = String(format: "%02d:%02d", minutes, seconds)
        
        // Determinar color según tiempo restante
        let timeColor: SKColor = remainingTime < 30 ? .red : .darkGray
        
        // Actualizar todas las etiquetas en el hilo principal
        DispatchQueue.main.async {
            for label in self.timeLabels {
                label.text = timeText
                label.fontColor = timeColor
            }
        }
        
        // Detener si llegamos a cero
        if remainingTime <= 0 {
            stop()
        }
    }
    
    // Limpiar recursos
    deinit {
        displayLink?.invalidate()
    }
}
