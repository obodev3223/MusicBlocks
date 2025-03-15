//
//  GameLogger.swift
//  MusicBlocks
//
//  Created by Jose R. García on 15/3/25.
//

import Foundation

class GameLogger {
    static let shared = GameLogger()
    
    // Configura qué tipos de mensajes quieres ver
    var showTimeUpdates = true
    var showScoreUpdates = true
    var showUIUpdates = true
    var showNoteDetection = false
    var showBlockMovement = false
    
    private var lastLogTimes: [String: TimeInterval] = [:]
    private let minimumInterval: TimeInterval = 2.0 // Solo log cada 2s
    
    func timeUpdate(_ message: String) {
        if showTimeUpdates {
            throttledLog("⏱️ TIEMPO: \(message)", identifier: "time")
        }
    }
    
    func scoreUpdate(_ message: String) {
        if showScoreUpdates {
            throttledLog("📊 SCORE: \(message)", identifier: "score")
        }
    }
    
    func uiUpdate(_ message: String) {
        if showUIUpdates {
            throttledLog("🖼️ UI: \(message)", identifier: "ui")
        }
    }
    
    func noteDetection(_ message: String) {
        if showNoteDetection {
            throttledLog("🎵 NOTA: \(message)", identifier: "note")
        }
    }
    
    func blockMovement(_ message: String) {
        if showBlockMovement {
            throttledLog("📦 BLOQUE: \(message)", identifier: "block")
        }
    }
    
    private func throttledLog(_ message: String, identifier: String) {
        let now = Date().timeIntervalSince1970
        if lastLogTimes[identifier] == nil ||
           (now - (lastLogTimes[identifier] ?? 0)) >= minimumInterval {
            print(message)
            lastLogTimes[identifier] = now
        }
    }
}
