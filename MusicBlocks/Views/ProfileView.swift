//
//  ProfileView.swift
//  FrikiTuner
//
//  Created by Jose R. García on 23/2/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var profile = UserProfile.load()
    @State private var isEditingUsername = false
    @State private var tempUsername = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Cabecera de perfil
            VStack(spacing: 15) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                
                if isEditingUsername {
                    TextField("Nombre de usuario", text: $tempUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                } else {
                    Text(profile.username)
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 40)
            
            // Botón de editar nombre
            Button(action: {
                if isEditingUsername {
                    if !tempUsername.isEmpty {
                        profile.username = tempUsername
                        profile.save()
                    }
                    isEditingUsername = false
                } else {
                    tempUsername = profile.username
                    isEditingUsername = true
                }
            }) {
                HStack {
                    Image(systemName: isEditingUsername ? "checkmark.circle.fill" : "pencil.circle.fill")
                    Text(isEditingUsername ? "Guardar" : "Editar nombre")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.purple)
                .cornerRadius(10)
            }
            
            if isEditingUsername {
                Button(action: {
                    isEditingUsername = false
                    tempUsername = ""
                }) {
                    Text("Cancelar")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            
            Spacer()
        }
        .navigationTitle("Mi Perfil")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
    }
}