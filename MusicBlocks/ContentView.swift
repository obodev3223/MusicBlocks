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
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Logo
                VStack(spacing: 15) {
                    Image(systemName: "tuningfork")
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                    
                    Text("FrikiTuner")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.purple)
                }
                .padding(.bottom, 60)
                
                // Botones de navegación
                VStack(spacing: 20) {
                    NavigationLink(destination: MusicBlocksScene()) {
                        HStack {
                            Image(systemName: "music.note")
                            Text("Practicar")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.purple)
                        )
                        .foregroundColor(.white)
                    }
                    
                    NavigationLink(destination: ProfileView()) {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Mi Perfil")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.purple.opacity(0.8))
                        )
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Text("v1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            setupAudio()
        }
        .onDisappear {
            audioController.stop()
        }
    }
    
    private func setupAudio() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                DispatchQueue.main.async {
                    audioController.start()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
