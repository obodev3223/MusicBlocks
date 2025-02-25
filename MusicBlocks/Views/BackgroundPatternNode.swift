import SpriteKit

class BackgroundPatternNode: SKNode {
    // MARK: - Properties
    private let colors: [UIColor]
    private let opacity: CGFloat
    
    // Configuración de elementos
    private let numberOfWaves = 8
    private let numberOfLines = 12
    private let numberOfCircles = 6
    private let numberOfDiagonals = 15
    private let numberOfNotes = 10
    
    // Rangos para símbolos musicales
    private let notesSizeRange: ClosedRange<CGFloat> = 20...60
    private let notesRotationRange: ClosedRange<CGFloat> = -45...45
    
    private let musicImages = [
        "MusicalSymbol_01", "MusicalSymbol_02", "MusicalSymbol_03", "MusicalSymbol_04", "MusicalSymbol_05",
        "MusicalSymbol_06", "MusicalSymbol_07", "MusicalSymbol_08", "MusicalSymbol_09", "MusicalSymbol_10",
        "MusicalSymbol_11", "MusicalSymbol_12", "MusicalSymbol_13", "MusicalSymbol_14", "MusicalSymbol_15",
        "MusicalSymbol_16", "MusicalSymbol_17", "MusicalSymbol_18", "MusicalSymbol_19", "MusicalSymbol_20",
        "MusicalSymbol_21", "MusicalSymbol_22", "MusicalSymbol_23"
    ]
    
    // MARK: - Initialization
    init(size: CGSize) {
        self.colors = Self.generatePastelColors()
        self.opacity = CGFloat.random(in: 0.1...0.2)
        super.init()
        
        setupLayers(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupLayers(size: CGSize) {
        addWavesLayer(size: size)
        addLinesLayer(size: size)
        addCirclesLayer(size: size)
        addDiagonalBarsLayer(size: size)
        addNotesLayer(size: size)
    }
    
    // MARK: - Layer Creation Methods
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
        shapeNode.strokeColor = colors[0]
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
        shapeNode.strokeColor = colors[1]
        shapeNode.lineWidth = 1.0
        shapeNode.alpha = opacity * 0.6
        addChild(shapeNode)
    }
    
    private func addCirclesLayer(size: CGSize) {
        for _ in 0..<numberOfCircles {
            let diameter = CGFloat.random(in: 40...180)
            let circle = SKShapeNode(circleOfRadius: diameter/2)
            circle.position = CGPoint(
                x: .random(in: 0...size.width),
                y: .random(in: 0...size.height)
            )
            circle.strokeColor = colors[0]
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
        shapeNode.strokeColor = colors[1]
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
            noteNode.color = colors[0]
            noteNode.colorBlendFactor = 1.0
            
            addChild(noteNode)
        }
    }
    
    // MARK: - Helper Methods
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
}