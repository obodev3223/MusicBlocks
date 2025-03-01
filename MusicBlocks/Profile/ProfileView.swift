//
//  ProfileView.swift
//  FrikiTuner
//
//  Created by Jose R. García on 23/2/25.
//  Last updated by obodev3223 on 28/2/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var profile = UserProfile.load()
    @State private var isEditingUsername = false
    @State private var showingAvatarPicker = false
    @FocusState private var isUsernameFocused: Bool
    @State private var showingStats = false
    @State private var showingAchievements = false
    @State private var showingResetConfirmation = false
    @StateObject private var medalManager = MedalManager.shared
    
    // Avatares disponibles para el usuario
    let availableAvatars = ["avatar1", "avatar2", "avatar3", "avatar8"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cabecera del perfil
                profileHeader
                
                Spacer(minLength: 20)
                
                // Secciones de información
                VStack(spacing: 15) {
                    // Sección de Estadísticas
                    statsSection
                    
                    Divider()
                    
                    // Sección de Logros
                    achievementsSection
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAvatarPicker) {
            AvatarPickerView(
                selectedAvatar: $profile.avatarName,
                availableAvatars: availableAvatars,
                onSave: {
                    profile.save()
                    showingAvatarPicker = false
                },
                onCancel: {
                    showingAvatarPicker = false
                }
            )
        }
        .alert(isPresented: $showingResetConfirmation) {
            Alert(
                title: Text("¿Borrar todos los datos?"),
                message: Text("Esta acción no se puede deshacer y eliminará todas tus estadísticas y progreso."),
                primaryButton: .destructive(Text("Borrar")) {
                    resetUserData()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - View Components
    
    private var profileHeader: some View {
        VStack(spacing: 15) {
            // Avatar con opción de edición
            ZStack(alignment: .bottomTrailing) {
                if availableAvatars.contains(profile.avatarName) {
                    Image(profile.avatarName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 160)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12) // Borde que coincide con la esquina
                                .stroke(Color.purple, lineWidth: 2)
                        )
                        .padding(3)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 120))
                        .foregroundColor(.purple)
                }
                
                Button(action: {
                    showingAvatarPicker = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.purple)
                        .background(Circle().fill(Color.white))
                }
                .offset(x: 5, y: 5)
            }
            .padding(.top, 20)
            
            // Editor de nombre de usuario
            usernameEditor
        }
    }
    
    private var usernameEditor: some View {
        HStack {
            Spacer()
            
            if isEditingUsername {
                TextField("Nombre de usuario", text: $profile.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .focused($isUsernameFocused)
                    .frame(minWidth: 200)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isUsernameFocused = true
                        }
                    }
                
                HStack(spacing: 10) {
                    Button(action: {
                        profile.save()
                        isEditingUsername = false
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        profile = UserProfile.load()
                        isEditingUsername = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                }
            } else {
                Text(profile.username)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Button(action: {
                    isEditingUsername = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.purple)
                }
                .padding(.leading, 5)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
    }
    
    private var statsSection: some View {
        ExpandableSection(
            isExpanded: $showingStats,
            header: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.purple)
                    Text("Estadísticas")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
            },
            content: {
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(title: "Puntuación Total", value: profile.statistics.formattedTotalScore)
                    StatRow(title: "Nivel Actual", value: "\(profile.statistics.currentLevel)")
                    StatRow(title: "Tiempo de Juego", value: profile.statistics.formattedPlayTime)
                    StatRow(title: "Notas acertadas", value: "\(profile.statistics.notesHit)")
                    StatRow(title: "Precisión", value: profile.statistics.formattedAccuracy)
                    StatRow(title: "Mejor racha", value: "\(profile.statistics.bestStreak)")
                    
                    // Botón para borrar datos
                    HStack {
                        Spacer()
                        Button(action: {
                            showingResetConfirmation = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                Text("Borrar datos")
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical, 8)
            }
        )
        .padding(.horizontal)
    }
    
    private var achievementsSection: some View {
        ExpandableSection(
            isExpanded: $showingAchievements,
            header: {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("Logros")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
            },
            content: {
                VStack(spacing: 24) {
                    // Sección de estadísticas generales de medallas
                    medalStatsView
                    
                    // Grid de medallas por categoría
                    MedalsGridView(medals: medalManager.getMedals())
                }
                .padding(.vertical, 8)
            }
        )
        .padding(.horizontal)
    }

    // Vista de estadísticas de medallas
    private var medalStatsView: some View {
        VStack(spacing: 12) {
            Text("Progreso de Medallas")
                .font(.headline)
                .padding(.bottom, 4)
            
            let totalStats = getTotalMedalStats()
            Text("\(totalStats.unlocked) de \(totalStats.total) medallas desbloqueadas")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                ForEach(MedalType.allCases, id: \.self) { type in
                    let stats = getMedalStats(for: type)
                    VStack(spacing: 6) {
                        Text(type.icon)
                            .font(.title2)
                        
                        VStack(spacing: 2) {
                            Text("\(stats.unlocked)/\(stats.total)")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(type.shortTitle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(type.color.opacity(0.1))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }

    // Añade esta función helper
    private func getTotalMedalStats() -> (unlocked: Int, total: Int) {
        let allStats = MedalType.allCases.map { getMedalStats(for: $0) }
        let totalUnlocked = allStats.reduce(0) { $0 + $1.unlocked }
        let total = allStats.reduce(0) { $0 + $1.total }
        return (totalUnlocked, total)
    }

    // Función auxiliar para obtener estadísticas de medallas por categoría
    private func getMedalStats(for type: MedalType) -> (unlocked: Int, total: Int) {
        let category = medalManager.getMedals().first { $0.type == type }
        let unlockedCount = category?.medals.filter { $0.isUnlocked }.count ?? 0
        let totalCount = category?.medals.count ?? 0
        return (unlockedCount, totalCount)
    }
    
    // MARK: - Helper Methods
    
    private func resetUserData() {
        profile.resetStatistics()
        medalManager.updateMedals(
            notesHit: 0,
            playTime: 0,
            currentStreak: 0,
            perfectTuningCount: 0  
        )
    }
}

// MARK: - Vista del selector de avatar
struct AvatarPickerView: View {
    @Binding var selectedAvatar: String
    let availableAvatars: [String]
    let onSave: () -> Void
    let onCancel: () -> Void
    @State private var tempSelectedAvatar: String
    
    init(selectedAvatar: Binding<String>, availableAvatars: [String], onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self._selectedAvatar = selectedAvatar
        self.availableAvatars = availableAvatars
        self.onSave = onSave
        self.onCancel = onCancel
        self._tempSelectedAvatar = State(initialValue: selectedAvatar.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Selecciona tu avatar")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120, maximum: 140), spacing: 20) // Aumentado el tamaño mínimo y máximo
                    ], spacing: 20) {
                        ForEach(availableAvatars, id: \.self) { avatar in
                            Button(action: {
                                tempSelectedAvatar = avatar
                            }) {
                                VStack {
                                    Image(avatar)
                                        .resizable()
                                        .scaledToFit() // Cambiado a scaledToFit para mantener proporciones
                                        .frame(width: 90, height: 120) // Tamaño rectangular vertical
                                        .cornerRadius(12) // Cambiado a esquinas redondeadas
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12) // Borde que coincide con la esquina
                                                .stroke(tempSelectedAvatar == avatar ? Color.purple : Color.clear, lineWidth: 3)
                                        )
                                        .padding(3)
                                    
                                    Text(avatar)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(tempSelectedAvatar == avatar ? Color.purple.opacity(0.1) : Color.clear)
                                )
                            }
                        }
                    }
                    .padding()
                }
                
                HStack(spacing: 20) {
                    Button(action: onCancel) {
                        Text("Cancelar")
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        selectedAvatar = tempSelectedAvatar
                        onSave()
                    }) {
                        Text("Guardar")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.purple)
                            )
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitle("Elegir Avatar", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cerrar") { onCancel() })
        }
    }
}

// MARK: - Componentes auxiliares

struct ExpandableSection<Header: View, Content: View>: View {
    @Binding var isExpanded: Bool
    let header: () -> Header
    let content: () -> Content
    
    var body: some View {
        VStack(spacing: 10) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    header()
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                        .animation(.easeInOut, value: isExpanded)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                content()
                    .padding(.leading, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.vertical, 4)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
    }
}

// MARK: - Preview Provider
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
    }
}
