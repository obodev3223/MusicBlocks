//
//  BackgroundPatternNode.swift
//  MusicBlocks
//
//  Created by Jose R. García on 27/2/25.
//

import SpriteKit

class BackgroundPatternNode: SKNode {
    // MARK: - Properties
    let pastelColors: [UIColor]
    private let contrastColor: UIColor
    private let opacity: CGFloat
    private let colors: [UIColor] = []

    // Configuración de elementos
    private let numberOfWaves = 8
    private let numberOfLines = 12
    private let numberOfCircles = 6
    private let numberOfDiagonals = 15
    private let numberOfNotes = 10
    
    // Rangos para símbolos musicales
    private let notesSizeRange: ClosedRange<CGFloat> = 20...50
    private let notesRotationRange: ClosedRange<CGFloat> = -45...45
    
    private let musicImages = [
        "MusicalSymbol_01", "MusicalSymbol_02", "MusicalSymbol_03", "MusicalSymbol_04", "MusicalSymbol_05",
        "MusicalSymbol_06", "MusicalSymbol_07", "MusicalSymbol_08", "MusicalSymbol_09", "MusicalSymbol_10",
        "MusicalSymbol_11", "MusicalSymbol_12", "MusicalSymbol_13", "MusicalSymbol_14", "MusicalSymbol_15",
        "MusicalSymbol_16", "MusicalSymbol_17", "MusicalSymbol_18", "MusicalSymbol_19", "MusicalSymbol_20",
        "MusicalSymbol_21", "MusicalSymbol_22", "MusicalSymbol_23"
    ]
    
    // MARK: - Inicialización
    init(size: CGSize) {
        // Se generan dos colores pastel para el degradado
        self.pastelColors = Self.generatePastelColors()
        // Se calcula un color de contraste (por ejemplo, complementario del primero)
        self.contrastColor = Self.contrastingColor(for: pastelColors.first ?? .white)
        self.opacity = CGFloat.random(in: 0.1...0.2)
        super.init()
        
        // Se agrega el fondo degradado
        addGradientBackground(size: size, colors: pastelColors)
        
        // Se agregan las capas de formas y símbolos en color de contraste
        setupLayers(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implementado")
    }
    
    // MARK: - Métodos de Configuración
    private func addGradientBackground(size: CGSize, colors: [UIColor]) {
        let texture = gradientTexture(size: size, colors: colors)
        let backgroundNode = SKSpriteNode(texture: texture)
        
        // Forzamos anclaje en la esquina inferior izquierda
        backgroundNode.anchorPoint = CGPoint(x: 0, y: 0)
        
        // Así, position (0,0) en el padre coincide con la esquina inferior izqda.
        backgroundNode.position = .zero
        
        backgroundNode.size = size
        backgroundNode.zPosition = -1
        addChild(backgroundNode)
    }

    
    private func setupLayers(size: CGSize) {
        addWavesLayer(size: size)
        addLinesLayer(size: size)
        addCirclesLayer(size: size)
        addDiagonalBarsLayer(size: size)
        addNotesLayer(size: size)
    }
    
    // MARK: - Creación de Capas
    private func addWavesLayer(size: CGSize) {
        let path = CGMutablePath()
        
        for i in 0...numberOfWaves {
            let x = CGFloat(i) * size.width / CGFloat(numberOfWaves)
            path.move(to: CGPoint(x: x, y: 0))
            path.addCurve(
                to: CGPoint(x: x, y: size.height),
                control1: CGPoint(x: x + 60 * sin(CGFloat(i)), y: size.height * 0.3),
                control2: CGPoint(x: x - 60 * cos(CGFloat(i)), y: size.height * 0.7)
            )
        }
        
        let shapeNode = SKShapeNode(path: path)
        shapeNode.strokeColor = contrastColor
        shapeNode.lineWidth = 1.5
        shapeNode.alpha = opacity * 0.7
        addChild(shapeNode)
    }
    
    private func addLinesLayer(size: CGSize) {
        let path = CGMutablePath()
        
        for _ in 0..<numberOfLines {
            let start = CGPoint(
                x: .random(in: 0...size.width),
                y: .random(in: 0...size.height)
            )
            let end = CGPoint(
                x: .random(in: 0...size.width),
                y: .random(in: 0...size.height)
            )
            path.move(to: start)
            path.addLine(to: end)
        }
        
        let shapeNode = SKShapeNode(path: path)
        shapeNode.strokeColor = contrastColor
        shapeNode.lineWidth = 1.0
        shapeNode.alpha = opacity * 0.6
        addChild(shapeNode)
    }
    
    private func addCirclesLayer(size: CGSize) {
        for _ in 0..<numberOfCircles {
            let diameter = CGFloat.random(in: 40...180)
            let circle = SKShapeNode(circleOfRadius: diameter / 2)
            circle.position = CGPoint(
                x: .random(in: 0...size.width),
                y: .random(in: 0...size.height)
            )
            circle.strokeColor = contrastColor
            circle.lineWidth = 1.5
            circle.alpha = opacity * 0.5
            addChild(circle)
        }
    }
    
    private func addDiagonalBarsLayer(size: CGSize) {
        let path = CGMutablePath()
        let spacing: CGFloat = 50
        let rotationAngle: CGFloat = .pi / 4
        
        for x in stride(from: -size.width, through: size.width * 2, by: spacing) {
            let transform = CGAffineTransform(rotationAngle: rotationAngle)
            let start = CGPoint(x: x, y: 0).applying(transform)
            let end = CGPoint(x: x, y: size.height).applying(transform)
            
            path.move(to: start)
            path.addLine(to: end)
        }
        
        let shapeNode = SKShapeNode(path: path)
        shapeNode.strokeColor = contrastColor
        shapeNode.lineWidth = 1.0
        shapeNode.alpha = opacity * 0.4
        addChild(shapeNode)
    }
    
    private func addNotesLayer(size: CGSize) {
        for _ in 0..<numberOfNotes {
            guard let imageName = musicImages.randomElement() else { continue }
            
            let noteSize = CGFloat.random(in: notesSizeRange)
            let texture = SKTexture(imageNamed: imageName)
            let noteNode = SKSpriteNode(texture: texture)
            
            noteNode.size = CGSize(width: noteSize, height: noteSize)
            noteNode.position = CGPoint(
                x: .random(in: 0...size.width),
                y: .random(in: 0...size.height)
            )
            noteNode.zRotation = CGFloat.random(in: notesRotationRange) * .pi / 180
            noteNode.alpha = opacity * 0.8
            noteNode.color = contrastColor
            noteNode.colorBlendFactor = 1.0
            
            addChild(noteNode)
        }
    }
    
    // MARK: - Métodos Auxiliares
    
    private static func generatePastelColors() -> [UIColor] {
        let baseHues = [
            CGFloat.random(in: 0...1),
            CGFloat.random(in: 0...1)
        ]
        
        return baseHues.map { hue in
            UIColor(
                hue: hue,
                saturation: CGFloat.random(in: 0.3...0.4),
                brightness: CGFloat.random(in: 0.9...1.0),
                alpha: 1.0
            )
        }
    }
    
    private static func contrastingColor(for color: UIColor) -> UIColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        if color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            // Se calcula el color complementario
            let complementaryHue = (hue + 0.5).truncatingRemainder(dividingBy: 1.0)
            return UIColor(
                hue: complementaryHue,
                saturation: max(saturation, 0.7),
                brightness: max(brightness - 0.5, 0.3),
                alpha: 1.0
            )
        }
        return .black
    }
    
    private func gradientTexture(size: CGSize, colors: [UIColor]) -> SKTexture {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        UIGraphicsBeginImageContext(gradientLayer.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return SKTexture()
        }
        gradientLayer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return SKTexture(image: image)
    }
}

#if DEBUG
import SwiftUI
import SpriteKit

struct BackgroundPatternNodePreview: UIViewRepresentable {
    let sceneSize: CGSize
    func makeUIView(context: Context) -> SKView {
        // Se crea una SKView con el tamaño de la preview
        let skView = SKView(frame: CGRect(origin: .zero, size: sceneSize))
        
        // Se configura la escena para que se redimensione automáticamente
        let scene = SKScene(size: sceneSize)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .white
        
        // Se crea y posiciona el BackgroundPatternNode
        let patternNode = BackgroundPatternNode(size: sceneSize)
        patternNode.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        scene.addChild(patternNode)
        
        skView.presentScene(scene)
        return skView
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        // Se actualiza el tamaño de la escena para ocupar todo el espacio de la SKView
        if let scene = uiView.scene {
            scene.size = uiView.bounds.size
        }
    }
}

struct BackgroundPatternNode_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            BackgroundPatternNodePreview(sceneSize: geometry.size)
        }
        .ignoresSafeArea()
        .previewDevice("iPhone 16 Pro")
    }
}

#endif
