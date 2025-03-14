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
    @State private var gameVersion: String = "--" // Valor por defecto
    @State private var navigateToGame = false  // Controla la navegación al juego
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Logo
                VStack(spacing: 15) {
                    Image("logoMusicBlocks")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 320)
                }
                .padding(.bottom, 20)
                
                // Botones de navegación
                VStack(spacing: 20) {
                    Button(action: {
                        startGameSequence()
                    }) {
                        HStack {
                            Image(systemName: "gamecontroller")
                            Text("Jugar")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.red)
                        )
                        .foregroundColor(.white)
                    }
                    Button(action: {
                        audioController.playButtonSound()
                        // Presentar el ProfileViewController
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootViewController = window.rootViewController {
                            let profileVC = ProfileViewController()
                            let navController = UINavigationController(rootViewController: profileVC)
                            navController.modalPresentationStyle = .fullScreen
                            rootViewController.present(navController, animated: true)
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Mi Perfil")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.red.opacity(0.8))
                        )
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Text(gameVersion)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.bottom, 20)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)
            // Navega a MusicBlocksSceneView cuando navigateToGame sea true
            .navigationDestination(isPresented: $navigateToGame) {
                MusicBlocksSceneView()
            }
        }
        .onAppear {
            setupAudio()
            loadGameVersion()
            // Iniciar la música de fondo en el menú
            audioController.startBackgroundMusic()
        }
        .onDisappear {
            audioController.stop()
        }
    }
    
    /// Solicita acceso al micrófono si es necesario.
    private func setupAudio() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                DispatchQueue.main.async {
                    // Puedes iniciar alguna acción extra si lo deseas.
                }
            }
        }
    }
    
    /// Carga la versión del juego desde el archivo JSON.
    private func loadGameVersion() {
        if let gameConfig = GameLevelProcessor.loadGameLevelsFromFile() {
            DispatchQueue.main.async {
                self.gameVersion = "v\(gameConfig.gameVersion)"
            }
        }
    }
    
    /// Secuencia para iniciar el juego:
    /// 1. Reproduce el sonido de clic.
    /// 2. Después de 0.2 s, inicia el fade out de la música (duración 0.5 s).
    /// 3. Tras 0.6 s en total, navega a la escena del juego.
    private func startGameSequence() {
        audioController.playButtonSound()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            audioController.stopBackgroundMusic(duration: 0.3)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                navigateToGame = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
