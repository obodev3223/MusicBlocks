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
        leftMargin: CGFloat = 40,
        rightMargin: CGFloat = 40
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
        trebleClef.position = CGPoint(x: -blockSize.width/2 + leftMargin + 30, y: 0)
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
            accidentalImage.size = CGSize(width: 25, height: 45)
            accidentalImage.position = CGPoint(x: notePosition.x - 25, y: notePosition.y)
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

