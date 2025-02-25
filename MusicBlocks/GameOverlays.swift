//
//  GameOverlays.swift
//  FrikiTuner
//
//  Created by Jose R. García on 14/2/25.
//

import SwiftUI

struct SuccessOverlay: View {
    let multiplier: Int
    let message: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(getColor())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(message)
                        .font(.title2)
                        .bold()
                        .foregroundColor(getColor())
                    
                    if multiplier > 0 {
                        Text("x\(multiplier)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.leading, 5)
                    }
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 5)
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    private func getColor() -> Color {
        switch multiplier {
        case 3: return .purple    // Excelente
        case 2: return .green     // Perfecto
        case 1: return .blue      // Bien
        default: return .gray
        }
    }
}

struct FailureOverlay: View {
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("¡Intenta de nuevo!")
                .font(.title2)
                .bold()
                .foregroundColor(.red)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 5)
        )
        .transition(.scale.combined(with: .opacity))
    }
}


struct GameOverOverlay: View {
    let score: Int
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("¡Fin del juego!")
                .font(.title)
                .bold()
                .foregroundColor(.purple)
            
            Text("Puntuación final: \(score)")
                .font(.title2)
                .foregroundColor(.purple)
            
            Button(action: action) {
                Text("Jugar de nuevo")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.purple)
                    )
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(radius: 15)
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// Extensión para manejar los mensajes de corrección


// Preview para desarrollo y testing
struct SuccessOverlay_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SuccessOverlay(multiplier: 1, message: "Bien")
            SuccessOverlay(multiplier: 2, message: "Perfecto")
            SuccessOverlay(multiplier: 3, message: "Excelente")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

struct GameOverlays_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SuccessOverlay(multiplier: 2, message: "Perfecto") // Añadir el multiplicador requerido
            FailureOverlay()
            GameOverOverlay(score: 42) {}
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
