//
//  MainMenuView.swift
//  FrikiTuner
//
//  Created by Jose R. García on 13/2/25.
//

import SwiftUI
import SpriteKit

struct MainMenuView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Title
//            Text("FrikiTuner")
//                .font(.system(size: 40, weight: .bold))
//                .padding(.top, 50)
            
            // Menu Buttons
            VStack(spacing: 20) {
                NavigationLink(destination: SimpleTunerView()) {
                    MenuButton(title: "Afinador", icon: "waveform")
                }
                
                NavigationLink(destination: PracticeTunerView()) {
                    MenuButton(title: "Juego", icon: "gamecontroller")
                }
                
                NavigationLink(destination: PracticeTunerSceneView()) {
                    MenuButton(title: "Sprite", icon: "movieclapper")
                }

            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 40)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue)
                .shadow(radius: 5)
        )
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
