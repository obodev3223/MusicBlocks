//
//  SoundControlsView.swift
//  MusicBlocks
//
//  Created by Jose R. García on 17/3/25.
//

import SwiftUI

struct SoundControlsView: View {
    @Binding var isExpanded: Bool
    @Binding var musicVolume: Float
    @Binding var effectsVolume: Float
    @Binding var isMuted: Bool
    
    // Callback to apply the new settings (called immediately on change)
    var onApplySettings: () -> Void
    
    // Animation duration
    private let animationDuration: Double = 0.3
    
    var body: some View {
        VStack(spacing: 0) {
            // Icon button to expand/collapse the panel
            Button(action: {
                withAnimation(.easeInOut(duration: animationDuration)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 18))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    )
            }
            .padding(.bottom, 8)
            
            // Expanded panel with volume controls
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Ajustes de sonido")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        // Close button
                        Button(action: {
                            withAnimation(.easeInOut(duration: animationDuration)) {
                                isExpanded = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Music volume control with immediate effect
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundColor(.red)
                        Text("Música")
                            .font(.subheadline)
                            .foregroundColor(.black)
                        Slider(value: Binding(
                            get: { musicVolume },
                            set: {
                                musicVolume = $0
                                onApplySettings() // Apply immediately
                            }
                        ), in: 0...1)
                        .accentColor(.red)
                    }
                    
                    // Sound effects volume control with immediate effect
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.red)
                        Text("Efectos")
                            .font(.subheadline)
                            .foregroundColor(.black)
                        Slider(value: Binding(
                            get: { effectsVolume },
                            set: {
                                effectsVolume = $0
                                onApplySettings() // Apply immediately
                            }
                        ), in: 0...1)
                        .accentColor(.red)
                    }
                    
                    // Mute toggle with immediate effect
                    Toggle(isOn: Binding(
                        get: { isMuted },
                        set: {
                            isMuted = $0
                            onApplySettings() // Apply immediately
                        }
                    )) {
                        HStack {
                            Image(systemName: "speaker.slash")
                                .foregroundColor(.red)
                            Text("Silenciar todo")
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .frame(width: isExpanded ? 250 : 40)
        .animation(.easeInOut(duration: animationDuration), value: isExpanded)
    }
}

// Optional Preview Provider for SwiftUI previews
struct SoundControlsView_Previews: PreviewProvider {
    static var previews: some View {
        SoundControlsView(
            isExpanded: .constant(true),
            musicVolume: .constant(0.7),
            effectsVolume: .constant(0.5),
            isMuted: .constant(false),
            onApplySettings: { print("Settings changed") }
        )
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Expanded")
        
        SoundControlsView(
            isExpanded: .constant(false),
            musicVolume: .constant(0.7),
            effectsVolume: .constant(0.5),
            isMuted: .constant(false),
            onApplySettings: { print("Settings changed") }
        )
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Collapsed")
    }
}
