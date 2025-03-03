//
//  BlockContentGenerator.swift
//  MusicBlocks
//
//  Created by Jose R. García on 2/3/25.
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
        leftMargin: CGFloat = 20,
        rightMargin: CGFloat = 20
    ) -> SKNode {
        let contentNode = SKNode()
        
        // MARK: PENTAGRAMA
        // --- Dibujar el pentagrama (5 líneas) ---
        let staffPath = CGMutablePath()
        let lineSpacing: CGFloat = 12
        // Se asume que las líneas se dibujan en y = 24, 12, 0, -12, -24
        for i in 0..<5 {
            let y = 24 - CGFloat(i) * lineSpacing
            let startPoint = CGPoint(x: -blockSize.width / 2 + leftMargin, y: y)
            let endPoint = CGPoint(x: blockSize.width / 2 - rightMargin, y: y)
            staffPath.move(to: startPoint)
            staffPath.addLine(to: endPoint)
        }
        let staffLines = SKShapeNode(path: staffPath)
        staffLines.strokeColor = .black.withAlphaComponent(0.6)
        staffLines.lineWidth = 2
        staffLines.zPosition = 1
        contentNode.addChild(staffLines)
        
        // MARK: CLAVE DE SOL
        // --- Añadir la imagen de la clave de sol ---
        let trebleClef = SKSpriteNode(imageNamed: "trebleClef")
        trebleClef.size = CGSize(width: 50, height: 90)
        trebleClef.position = CGPoint(x: -blockSize.width / 2 + leftMargin / 2 + trebleClef.size.width / 2, y: -2)
        trebleClef.zPosition = 2
        contentNode.addChild(trebleClef)
     
        // MARK: NOTA
        // --- Añadir la nota en forma de imagen ---
        // Se calcula la posición final de la nota sumando un offset personalizado.
        let noteOffset = getNoteOffset(for: desiredNote)
                let notePosition = CGPoint(x: baseNoteX + noteOffset.x,
                                         y: baseNoteY + noteOffset.y)
                
                let noteImage = SKSpriteNode(imageNamed: "wholeNote")
                noteImage.size = CGSize(width: 23, height: 23)
                noteImage.position = notePosition
                noteImage.zPosition = 3
                contentNode.addChild(noteImage)
    
        // MARK: ALTERACIONES
        // --- Visualización de accidentales (sostenido o bemol) ---
        if desiredNote.alteration == .sharp {
                    let accidentalImage = SKSpriteNode(imageNamed: "sharp")
                    accidentalImage.size = CGSize(width: 45, height: 65)
                    accidentalImage.position = CGPoint(x: notePosition.x - 25, y: notePosition.y)
                    accidentalImage.zPosition = 3.5
                    contentNode.addChild(accidentalImage)
                } else if desiredNote.alteration == .flat {
                    let accidentalImage = SKSpriteNode(imageNamed: "flat")
                    accidentalImage.size = CGSize(width: 45, height: 65)
                    accidentalImage.position = CGPoint(x: notePosition.x - 25, y: notePosition.y)
                    accidentalImage.zPosition = 3.5
                    contentNode.addChild(accidentalImage)
                }
        
        // MARK: LINEAS ADICIONALES
        // --- Agregar ledger lines (líneas adicionales) ---
        addLedgerLines(for: notePosition.y, in: contentNode, for: desiredNote)
        
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

extension BlockContentGenerator {
    /// Genera el contenido visual de un bloque usando TunerEngine.Note.
    ///
    /// - Parameters:
    ///   - style: El estilo del bloque (por ejemplo, BlockStyle.defaultBlock).
    ///   - blockSize: El tamaño del bloque.
    ///   - desiredNote: La nota que se quiere visualizar (de tipo TunerEngine.Note).
    ///   - baseNoteX: Posición base en X para la nota (ajústala según tu diseño).
    ///   - baseNoteY: Posición base en Y para la nota.
    ///   - leftMargin: Margen izquierdo para dibujar el pentagrama.
    ///   - rightMargin: Margen derecho para el pentagrama.
    /// - Returns: Un SKNode con todo el contenido (pentagrama, clave, nota, accidentales y ledger lines).
    static func generateBlockContent(
        with style: BlockStyle,
        blockSize: CGSize,
        desiredNote: TunerEngine.Note,
        baseNoteX: CGFloat,
        baseNoteY: CGFloat,
        leftMargin: CGFloat = 20,
        rightMargin: CGFloat = 20
    ) -> SKNode {
        // Obtener el offset de posición vertical para la nota
        let noteOffset = getNoteOffset(for: desiredNote)
        
        let contentNode = SKNode()
        
        // MARK: PENTAGRAMA
        // --- Dibujar el pentagrama (5 líneas) ---
        let staffPath = CGMutablePath()
        let lineSpacing: CGFloat = 12
        // Se asume que las líneas se dibujan en y = 24, 12, 0, -12, -24
        for i in 0..<5 {
            let y = 24 - CGFloat(i) * lineSpacing
            let startPoint = CGPoint(x: -blockSize.width / 2 + leftMargin, y: y)
            let endPoint = CGPoint(x: blockSize.width / 2 - rightMargin, y: y)
            staffPath.move(to: startPoint)
            staffPath.addLine(to: endPoint)
        }
        let staffLines = SKShapeNode(path: staffPath)
        staffLines.strokeColor = .black.withAlphaComponent(0.6)
        staffLines.lineWidth = 2
        staffLines.zPosition = 1
        contentNode.addChild(staffLines)
        
        // MARK: CLAVE DE SOL
        // --- Añadir la imagen de la clave de sol ---
        let trebleClef = SKSpriteNode(imageNamed: "trebleClef")
        trebleClef.size = CGSize(width: 50, height: 90)
        trebleClef.position = CGPoint(x: -blockSize.width / 2 + leftMargin / 2 + trebleClef.size.width / 2, y: -2)
        trebleClef.zPosition = 2
        contentNode.addChild(trebleClef)
     
        // MARK: NOTA
        // --- Añadir la nota en forma de imagen ---
        // Calcular la posición final de la nota usando el offset calculado
        let notePosition = CGPoint(x: baseNoteX + noteOffset.x,
                                   y: baseNoteY + noteOffset.y)
        
        let noteImage = SKSpriteNode(imageNamed: "wholeNote")
        noteImage.size = CGSize(width: 23, height: 23)
        noteImage.position = notePosition
        noteImage.zPosition = 3
        contentNode.addChild(noteImage)
    
        // MARK: ALTERACIONES
        // --- Visualización de accidentales (sostenido o bemol) ---
        if desiredNote.alteration == .sharp {
            let accidentalImage = SKSpriteNode(imageNamed: "sharp")
            accidentalImage.size = CGSize(width: 45, height: 65)
            accidentalImage.position = CGPoint(x: notePosition.x - 25, y: notePosition.y)
            accidentalImage.zPosition = 3.5
            contentNode.addChild(accidentalImage)
        } else if desiredNote.alteration == .flat {
            let accidentalImage = SKSpriteNode(imageNamed: "flat")
            accidentalImage.size = CGSize(width: 45, height: 65)
            accidentalImage.position = CGPoint(x: notePosition.x - 25, y: notePosition.y)
            accidentalImage.zPosition = 3.5
            contentNode.addChild(accidentalImage)
        }
        
        // MARK: LINEAS ADICIONALES
        // --- Agregar ledger lines (líneas adicionales) ---
        addLedgerLines(for: notePosition.y, in: contentNode, for: desiredNote)
        
        return contentNode
    }
    
    /// Calcula el offset vertical para una nota del TunerEngine
    private static func getNoteOffset(for note: TunerEngine.Note) -> CGPoint {
        // Tabla que mapea la combinación de nombre de nota y octava a su offset vertical
        // Estos valores corresponden a los usados en el enum MusicalNote
        let offsets: [String: CGFloat] = [
            // Octava 3
            "LA3": -48, "LA#3": -48, "LA♭3": -48,
            "SI3": -42, "SI#3": -42, "SI♭3": -42,
            
            // Octava 4
            "DO4": -36, "DO#4": -36, "DO♭4": -36,
            "RE4": -30, "RE#4": -30, "RE♭4": -30,
            "MI4": -24, "MI#4": -24, "MI♭4": -24,
            "FA4": -18, "FA#4": -18, "FA♭4": -18,
            "SOL4": -12, "SOL#4": -12, "SOL♭4": -12,
            "LA4": -6, "LA#4": -6, "LA♭4": -6,
            "SI4": 0, "SI#4": 0, "SI♭4": 0,
            
            // Octava 5
            "DO5": 6, "DO#5": 6, "DO♭5": 6,
            "RE5": 12, "RE#5": 12, "RE♭5": 12,
            "MI5": 18, "MI#5": 18, "MI♭5": 18,
            "FA5": 24, "FA#5": 24, "FA♭5": 24,
            "SOL5": 30, "SOL#5": 30, "SOL♭5": 30,
            "LA5": 36, "LA#5": 36, "LA♭5": 36,
            "SI5": 42, "SI#5": 42, "SI♭5": 42,
            
            // Octava 6
            "DO6": 48, "DO#6": 48, "DO♭6": 48
        ]
        
        // Construir la clave para buscar en el diccionario
        let key = "\(note.name)\(note.octave)"
        
        // Obtener el offset vertical o usar valor por defecto
        let yOffset = offsets[key] ?? 0
        
        return CGPoint(x: 0, y: yOffset)
    }
    
    /// Dibuja ledger lines (líneas adicionales) si la nota se sale del pentagrama.
    ///
    /// - Parameters:
    ///   - noteY: La posición Y de la nota.
    ///   - node: El nodo al que se añadirán las ledger lines.
    ///   - note: La nota (TunerEngine.Note) para la cual se determinarán las líneas adicionales.
    private static func addLedgerLines(for noteY: CGFloat, in node: SKNode, for note: TunerEngine.Note) {
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
        
        // Para notas de octavas extremas, añadir líneas adicionales
        let isHigh = note.name == "DO" && note.octave == 6
        let isLow = note.name == "LA" && note.octave == 3
        
        // Para "DO6" y "LA3", dibujamos dos ledger lines.
        if isHigh {
            createLedgerLine(at: staffTop + 6)
            createLedgerLine(at: staffTop + 18)
        } else if isLow {
            createLedgerLine(at: staffBottom - 6)
            createLedgerLine(at: staffBottom - 18)
        } else {
            // Para otras notas, agregar líneas adicionales si se salen del pentagrama
            if noteY > staffTop {
                createLedgerLine(at: staffTop + 6)
            } else if noteY < staffBottom {
                createLedgerLine(at: staffBottom - 6)
            }
        }
    }
}
