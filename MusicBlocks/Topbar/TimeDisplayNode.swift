//
//  TimeDisplayNode.swift
//  MusicBlocks
//
//  Created by Jose R. García el 25/4/25.
//  Solución independiente para visualización de tiempo en interfaces de juego
//

import SpriteKit
import Foundation

/// Nodo que muestra un contador de tiempo en formato MM:SS
/// Se actualiza automáticamente y puede mostrar tiempo transcurrido o cuenta regresiva
class TimeDisplayNode: SKNode {
    // MARK: - Propiedades
    
    /// Configuración visual
    private struct Layout {
        static let iconSize: CGFloat = 18
        static let fontSize: CGFloat = 12
        static let iconTextSpacing: CGFloat = 16
    }
    
    // Componentes visuales
    private let timeIcon: SKSpriteNode
    private let timeLabel: SKLabelNode
    
    // Control de tiempo
    private let timeLimit: TimeInterval
    private var startTime: Date
    private var lastUpdateTime: TimeInterval = 0
    
    // Control de actualización
    private var displayLink: CADisplayLink?
    private var runLoop: RunLoop?
    private var updateTimer: Timer?
    
    // MARK: - Inicialización
    
    /// Inicializa un nodo de visualización de tiempo
    /// - Parameter timeLimit: Tiempo límite en segundos (0 para sin límite)
    init(timeLimit: TimeInterval) {
        // Configuración visual
        let iconTexture = SKTexture(imageNamed: "timer_icon")
        timeIcon = SKSpriteNode(texture: iconTexture)
        
        // Mantener proporción del icono
        let originalSize = iconTexture.size()
        let scale = Layout.iconSize / max(originalSize.width, originalSize.height, 1.0)
        timeIcon.size = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        
        // Configurar etiqueta de tiempo
        self.timeLabel = SKLabelNode(fontNamed: "Helvetica")
        self.timeLimit = timeLimit
        self.startTime = Date()
        
        super.init()
        
        // Establecer nombre para encontrar este nodo fácilmente en la jerarquía
        self.name = "TimeDisplayNode"
        
        setupTimeComponents()
        startDisplayLink()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopDisplayLink()
    }
    
    // MARK: - Configuración
    
    private func setupTimeComponents() {
        // Posicionar el icono
        timeIcon.position = CGPoint(x: -Layout.iconTextSpacing/2, y: 0)
        addChild(timeIcon)
        
        // Configurar la etiqueta de tiempo
        timeLabel.fontSize = Layout.fontSize
        timeLabel.fontColor = .darkGray
        timeLabel.verticalAlignmentMode = .center
        timeLabel.horizontalAlignmentMode = .left
        timeLabel.position = CGPoint(x: timeIcon.position.x + Layout.iconTextSpacing, y: 0)
        addChild(timeLabel)
        
        // Actualización inicial
        update()
    }
    
    // MARK: - Control de DisplayLink
    
    /// Inicia el mecanismo de actualización automática (DisplayLink o Timer)
    private func startDisplayLink() {
        // Detener cualquier actualización existente
        stopDisplayLink()
        
        // Intentar usar DisplayLink (más eficiente) primero
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Usar un método de actualización alternativo en caso de que DisplayLink no sea ideal
            #if targetEnvironment(simulator)
                // Usar Timer en el simulador (más compatible)
                self.startTimerUpdate()
            #else
                // Usar DisplayLink en dispositivos reales
                self.displayLink = CADisplayLink(target: self, selector: #selector(self.displayLinkFired))
                self.runLoop = RunLoop.current
                
                // Configurar para que se ejecute cada cuadro en el modo común
                self.displayLink?.add(to: self.runLoop!, forMode: .common)
                
                // Reducir frecuencia para mejor rendimiento (6 actualizaciones por segundo)
                if #available(iOS 15.0, *) {
                    self.displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 6, maximum: 6, preferred: 6)
                } else {
                    self.displayLink?.preferredFramesPerSecond = 6
                }
            #endif
        }
    }
    
    /// Inicia un Timer como método alternativo de actualización
    private func startTimerUpdate() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.update()
        }
        RunLoop.current.add(updateTimer!, forMode: .common)
    }
    
    /// Detiene todos los mecanismos de actualización automática
    private func stopDisplayLink() {
        // Detener DisplayLink
        displayLink?.invalidate()
        displayLink = nil
        
        // Detener Timer si existe
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Actualización
    
    /// Se llama en cada tick del DisplayLink
    @objc private func displayLinkFired() {
        // Solo actualizar si han pasado al menos 100ms desde la última actualización
        // Esto reduce la carga de procesamiento
        let currentTime = CACurrentMediaTime()
        if currentTime - lastUpdateTime >= 0.1 {
            lastUpdateTime = currentTime
            update()
        }
    }
    
    /// Actualiza la visualización del tiempo
    func update() {
        // Si no hay límite de tiempo, mostrar infinito
        if timeLimit <= 0 {
            timeLabel.text = "∞"
            return
        }
        
        // Calcular tiempo transcurrido
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Calcular tiempo restante (limitado a 0)
        let remainingTime = max(timeLimit - elapsedTime, 0)
        
        // Convertir a minutos y segundos
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        
        // Formatear como MM:SS
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        // Cambiar color cuando queda poco tiempo (menos de 30 segundos)
        if remainingTime < 30 {
            timeLabel.fontColor = .red
        } else {
            timeLabel.fontColor = .darkGray
        }
        
        // Si el tiempo ha expirado, detener la actualización automática
        if remainingTime <= 0 {
            stopDisplayLink()
        }
    }
    
    // MARK: - API Pública
    
    /// Establece un nuevo tiempo de inicio para el contador
    /// - Parameter newStartTime: Nueva fecha de inicio
    func setStartTime(_ newStartTime: Date) {
        // Asignar la nueva fecha de inicio
        startTime = newStartTime
        update()
        
        // Reiniciar el DisplayLink si se había detenido
        if displayLink == nil {
            startDisplayLink()
        }
    }
    
    // MARK: - Ciclo de vida
    
    /// Se llama cuando el nodo se añade o elimina de una escena
    override func didChangeParents() {
        super.didChangeParents()
        
        // Si el nodo ahora tiene un parent, activar el DisplayLink
        if self.parent != nil {
            startDisplayLink()
        } else {
            // Si el nodo ya no tiene un parent, detener el DisplayLink
            stopDisplayLink()
        }
    }
}

#if DEBUG
import SwiftUI

// MARK: - Previews
extension TimeDisplayNode {
    static func createPreviewScene() -> SKScene {
        let scene = SKScene(size: CGSize(width: 300, height: 200))
        scene.backgroundColor = .white
        
        // Crear varios nodos de tiempo con diferentes configuraciones
        let timeNodes: [(timeLimit: TimeInterval, position: CGPoint)] = [
            (0, CGPoint(x: 150, y: 160)),    // Infinito
            (60, CGPoint(x: 150, y: 120)),   // 1 minuto
            (180, CGPoint(x: 150, y: 80)),   // 3 minutos
            (25, CGPoint(x: 150, y: 40))     // 25 segundos (crítico)
        ]
        
        for config in timeNodes {
            let node = TimeDisplayNode(timeLimit: config.timeLimit)
            node.position = config.position
            
            // Para el de 25 segundos, simular que han pasado 5 segundos
            if config.timeLimit == 25 {
                node.setStartTime(Date().addingTimeInterval(-5))
            }
            
            scene.addChild(node)
        }
        
        return scene
    }
}

struct TimeDisplayNodePreview: PreviewProvider {
    static var previews: some View {
        SpriteView(scene: TimeDisplayNode.createPreviewScene())
            .frame(width: 300, height: 200)
            .previewLayout(.fixed(width: 300, height: 200))
    }
}
#endif
