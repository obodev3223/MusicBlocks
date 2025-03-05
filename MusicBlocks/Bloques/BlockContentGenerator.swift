//
//  BlockContentGenerator.swift
//  MusicBlocks
//
//  Created by Jose R. García on 3/3/25.
//

import SpriteKit

/// Este struct agrupa funciones para generar el contenido visual interno de un bloque,
/// es decir, el pentagrama, la clave de sol, la imagen de la nota, los accidentales y las ledger lines.
struct BlockContentGenerator {
    
    /// Genera el contenido visual de un bloque.
    static func generateBlockContent(
        with style: BlockStyle,
        blockSize: CGSize,
        desiredNote: MusicalNote,
        baseNoteX: CGFloat,
        baseNoteY: CGFloat,
        leftMargin: CGFloat = 30,
        rightMargin: CGFloat = 30
    ) -> SKNode {
        let contentNode = SKNode()
        
        // MARK: PENTAGRAMA
        let staffPath = CGMutablePath()
        let lineSpacing: CGFloat = 12
        for i in 0..<5 {
            let y = 24 - CGFloat(i) * lineSpacing
            staffPath.move(to: CGPoint(x: -blockSize.width/2 + leftMargin, y: y))
            staffPath.addLine(to: CGPoint(x: blockSize.width/2 - rightMargin, y: y))
        }
        let staffLines = SKShapeNode(path: staffPath)
        staffLines.strokeColor = .black
        staffLines.lineWidth = 2
        staffLines.zPosition = 1
        contentNode.addChild(staffLines)
        
        // MARK: CLAVE DE SOL
        let trebleClef = SKSpriteNode(imageNamed: "trebleClef")
        trebleClef.size = CGSize(width: 50, height: 90)
        trebleClef.position = CGPoint(x: -blockSize.width/2 + leftMargin + 25, y: -2)
        trebleClef.zPosition = 2
        contentNode.addChild(trebleClef)
        
        // MARK: NOTA
        let noteOffset = getNoteOffset(for: desiredNote)
        let notePosition = CGPoint(
            x: baseNoteX,
            y: baseNoteY + noteOffset.y
        )
        
        let noteImage = SKSpriteNode(imageNamed: "wholeNote")
        noteImage.size = CGSize(width: 23, height: 23)
        noteImage.position = notePosition
        noteImage.zPosition = 3
        contentNode.addChild(noteImage)
        
        // MARK: ALTERACIONES
        if desiredNote.alteration != .natural {
            let accidentalImage = SKSpriteNode(imageNamed: getAccidentalImageName(for: desiredNote.alteration))
            accidentalImage.size = CGSize(width: 45, height: 70)
            accidentalImage.position = CGPoint(x: notePosition.x - 23, y: notePosition.y)
            accidentalImage.zPosition = 3
            contentNode.addChild(accidentalImage)
        }
        
        // MARK: LÍNEAS ADICIONALES
        addLedgerLines(for: notePosition.y, in: contentNode, for: desiredNote)
        
        print("Contenido del bloque generado para nota: \(desiredNote.fullName)")
        return contentNode
    }
    
    private static func getNoteOffset(for note: MusicalNote) -> CGPoint {
           // Tabla que mapea la combinación de nombre de nota y octava a su offset vertical
           let baseOffsets: [String: CGFloat] = [
               "DO": -36,
               "RE": -30,
               "MI": -24,
               "FA": -18,
               "SOL": -12,
               "LA": -6,
               "SI": 0
           ]
           
           guard let baseOffset = baseOffsets[note.name] else {
               return .zero
           }
           
           // Ajustar el offset según la octava
           let octaveOffset = CGFloat(note.octave - 4) * 42
           return CGPoint(x: 0, y: baseOffset + octaveOffset)
       }
    
    private static func getAccidentalImageName(for alteration: MusicalNote.Alteration) -> String {
        switch alteration {
        case .sharp:
            return "sharp"
        case .flat:
            return "flat"
        case .natural:
            return ""  // No debería llegar aquí, pero por completitud
        }
    }
    
    /// Dibuja ledger lines (líneas adicionales) si la nota se sale del pentagrama.
    ///
    /// - Parameters:
    ///   - noteY: La posición Y de la nota.
    ///   - node: El nodo al que se añadirán las ledger lines.
    ///   - note: La nota (MusicalNote) para la cual se determinarán las líneas adicionales.
    private static func addLedgerLines(for noteY: CGFloat, in node: SKNode, for note: MusicalNote) {
        let staffTop: CGFloat = 30
        let staffBottom: CGFloat = -30
        let ledgerLineWidth: CGFloat = 30
        let ledgerLineThickness: CGFloat = 2.0
        
        func createLedgerLine(at ledgerY: CGFloat) {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -ledgerLineWidth / 2, y: ledgerY))
            path.addLine(to: CGPoint(x: ledgerLineWidth / 2, y: ledgerY))
            let ledgerLine = SKShapeNode(path: path)
            ledgerLine.strokeColor = .black
            ledgerLine.lineWidth = ledgerLineThickness
            ledgerLine.zPosition = 3.5
            node.addChild(ledgerLine)
        }
        
        // Para "Do6" y "La3", dibujamos dos ledger lines.
        let isHigh = note.name == "DO" && note.octave == 6
                let isLow = note.name == "LA" && note.octave == 3
                
                if isHigh {
                    createLedgerLine(at: staffTop + 6)
                    createLedgerLine(at: staffTop + 18)
                } else if isLow {
                    createLedgerLine(at: staffBottom - 6)
                    createLedgerLine(at: staffBottom - 18)
                } else {
                    if noteY > staffTop {
                        createLedgerLine(at: staffTop + 6)
                    } else if noteY < staffBottom {
                        createLedgerLine(at: staffBottom - 6)
                    }
                }
            }
        }

#if DEBUG
import SwiftUI

// Vista previa del contenido de un bloque
struct BlockPreview: PreviewProvider {
    static var previews: some View {
        BlockPreviewView()
            .frame(width: 300, height: 200)
            .previewLayout(.fixed(width: 300, height: 200))
            .preferredColorScheme(.light)
    }
}

// Vista del bloque para la preview
struct BlockPreviewView: View {
    var body: some View {
        SpriteView(scene: createPreviewScene())
    }
    
    private func createPreviewScene() -> SKScene {
        let scene = SKScene(size: CGSize(width: 300, height: 200))
        scene.backgroundColor = .white
        
        // Crear un bloque de ejemplo
        let blockSize = CGSize(width: 270, height: 110)
        let exampleNote = MusicalNote(name: "LA", alteration: .sharp, octave: 4)
        
        // Crear el contenedor del bloque
        let blockNode = SKNode()
        blockNode.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        
        // Crear el fondo del bloque
        let background = SKShapeNode(rectOf: blockSize, cornerRadius: 15)
        background.fillColor = .white
        background.strokeColor = .black
        background.lineWidth = 2
        blockNode.addChild(background)
        
        // Generar el contenido (pentagrama, nota, etc.)
        let content = BlockContentGenerator.generateBlockContent(
            with: .defaultBlock,
            blockSize: blockSize,
            desiredNote: exampleNote,
            baseNoteX: 0,
            baseNoteY: 0
        )
        blockNode.addChild(content)
        
        scene.addChild(blockNode)
        return scene
    }
}

// Vista previa de diferentes notas
struct BlockNotesPreview: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Ejemplos de Bloques Musicales")
                .font(.headline)
            
            VStack(spacing: 20) {
                BlockNoteView(note: MusicalNote(name: "DO", alteration: .natural, octave: 6))
                    .frame(width: 270, height: 110)
                BlockNoteView(note: MusicalNote(name: "FA", alteration: .sharp, octave: 4))
                    .frame(width: 270, height: 110)
            }
            
            VStack(spacing: 20) {
                BlockNoteView(note: MusicalNote(name: "LA", alteration: .flat, octave: 4))
                    .frame(width: 270, height: 110)
                BlockNoteView(note: MusicalNote(name: "LA", alteration: .natural, octave: 3))
                    .frame(width: 270, height: 110)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .previewLayout(.fixed(width: 600, height: 400))
    }
}

// Vista individual de un bloque con una nota específica
struct BlockNoteView: View {
    let note: MusicalNote
    
    var body: some View {
        SpriteView(scene: createNoteScene())
            .border(Color.gray, width: 1)
    }
    
    private func createNoteScene() -> SKScene {
        let scene = SKScene(size: CGSize(width: 270, height: 110))
        scene.backgroundColor = .white
        
        let blockNode = SKNode()
        blockNode.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        
        let background = SKShapeNode(rectOf: scene.size, cornerRadius: 15)
        background.fillColor = .white
        background.strokeColor = .black
        background.lineWidth = 2
        blockNode.addChild(background)
        
        let content = BlockContentGenerator.generateBlockContent(
            with: .iceBlock,
            blockSize: scene.size,
            desiredNote: note,
            baseNoteX: 0,
            baseNoteY: 0
        )
        blockNode.addChild(content)
        
        scene.addChild(blockNode)
        return scene
    }
}
#endif
