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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Logo
                VStack(spacing: 15) {
                    Image("logoMusicBlocks")
                        .resizable() // Permite que la imagen sea redimensionable
                        .scaledToFit() // Mantiene la proporción de la imagen
                        .frame(width: 320, height: 320) // Establece el tamaño deseado
                    
                    
                }
                .padding(.bottom, 20)
                
                // Botones de navegación
                VStack(spacing: 20) {
                                    NavigationLink(destination: MusicBlocksSceneView()) {
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
                    // Agregamos un onTapGesture para detener la música de fondo al pulsar "Jugar"
                                        .simultaneousGesture(TapGesture().onEnded {
                                            audioController.stopBackgroundMusic()
                                            audioController.playButtonSound()
                                        })
                    
                    // Reemplazamos el NavigationLink con un botón personalizado
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
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            setupAudio()
            loadGameVersion()
            // Iniciar la música de fondo al aparecer el menú
                        audioController.startBackgroundMusic()
        }
        .onDisappear {
            audioController.stop()
        }
    }
    
    private func setupAudio() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                DispatchQueue.main.async {
//                    audioController.start()
                }
            }
        }
    }
    private func loadGameVersion() {
        if let gameConfig = GameLevelProcessor.loadGameLevelsFromFile() {
            // Añadimos "v" al inicio de la versión
            DispatchQueue.main.async {
                self.gameVersion = "v\(gameConfig.gameVersion)"
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
