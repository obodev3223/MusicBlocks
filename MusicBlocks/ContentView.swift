//
//  ContentView.swift
//  MusicBlocks
//
//  Created by Jose R. García on 14/2/25.
//

import SwiftUI
import AVFoundation
import SpriteKit

struct ContentView: View {
    @StateObject private var audioController = AudioController.sharedInstance
    
    var body: some View {
        PracticeTunerSceneView()
    }
    
    private func setupAudio() {
        // Solicitar permisos al inicio
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                DispatchQueue.main.async {
                    audioController.start()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
