//
//  ProfileViewController.swift
//  MusicBlocks
//
//  Created by Jose R. García on 1/3/25.
//

import UIKit
import SpriteKit

/// `ProfileViewController` maneja la visualización y gestión del perfil del usuario.
/// Incluye la información del perfil, estadísticas y logros del usuario.
class ProfileViewController: UIViewController {
    // MARK: - Properties
    
    /// El perfil del usuario actual cargado desde UserDefaults
    private var profile = UserProfile.load()
    
    /// Gestor singleton para manejar las medallas y logros
    private let medalManager = MedalManager.shared
    
    /// ScrollView principal que contiene todo el contenido del perfil
    private var scrollView: UIScrollView!
    
    /// Vista contenedora para todos los elementos del perfil
    private var contentView: UIView!
    
    /// Vista de cabecera que muestra la información básica del perfil (avatar y nombre)
    private var profileHeaderView: ProfileHeaderView!
    
    /// Sección expandible que muestra las estadísticas del usuario
    private var statsSection: ExpandableSectionView!
    
    /// Sección expandible que muestra los logros del usuario
    private var achievementsSection: ExpandableSectionView!
    
    // MARK: - Lifecycle
    
    /// Configura la vista inicial cuando se carga el controlador
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        loadProfile()
    }
    
    // MARK: - Setup
    
    /// Configura la barra de navegación y el color de fondo
    private func setupNavigationBar() {
        title = "Perfil"
        navigationController?.navigationBar.prefersLargeTitles = false
        view.backgroundColor = .systemBackground
        
        // Agregar botón para volver al menú principal
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "house.fill"),
            style: .plain,
            target: self,
            action: #selector(returnToMainMenu)
        )
        menuButton.tintColor = .systemRed
        navigationItem.leftBarButtonItem = menuButton
    }
    
    /// Acción para volver al menú principal (ContentView)
    @objc private func returnToMainMenu() {
        // Cerrar este view controller y volver al ContentView
        dismiss(animated: true)
    }
    
    /// Configura todas las vistas y su jerarquía
    private func setupViews() {
        // Setup ScrollView
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        
        // Setup ContentView - Contenedor principal
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .systemBackground
        scrollView.addSubview(contentView)
        
        // Setup ProfileHeaderView - Vista de cabecera del perfil
        profileHeaderView = ProfileHeaderView()
        profileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderView.delegate = self
        contentView.addSubview(profileHeaderView)
        
        // Setup StatsSection - Sección de estadísticas
        statsSection = ExpandableSectionView(
            title: "Estadísticas",
            icon: UIImage(systemName: "chart.bar.fill"),
            iconTintColor: .systemRed
        )
        statsSection.translatesAutoresizingMaskIntoConstraints = false
        statsSection.delegate = self
        contentView.addSubview(statsSection)
        
        // Setup AchievementsSection - Sección de logros
        achievementsSection = ExpandableSectionView(
            title: "Logros",
            icon: UIImage(systemName: "trophy.fill"),
            iconTintColor: .systemYellow
        )
        achievementsSection.translatesAutoresizingMaskIntoConstraints = false
        achievementsSection.delegate = self
        contentView.addSubview(achievementsSection)
        
        setupConstraints()
    }
    
    /// Configura las constraints de todas las vistas
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView - Ocupa todo el espacio disponible
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView - Se ajusta al ancho del ScrollView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // ProfileHeaderView - Margen superior e inferior
            profileHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            profileHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // StatsSection - Separación respecto al header
            statsSection.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor, constant: 20),
            statsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // AchievementsSection - Espaciado reducido respecto a stats
            achievementsSection.topAnchor.constraint(equalTo: statsSection.bottomAnchor, constant: 8),
            achievementsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            achievementsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            achievementsSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    /// Carga y configura los datos del perfil en las vistas
    private func loadProfile() {
        profileHeaderView.configure(with: profile)
        updateStats()
        updateAchievements()
    }
    
    /// Actualiza la vista de estadísticas con los datos actuales
    private func updateStats() {
        let statsView = StatsView(statistics: profile.statistics)
        statsView.delegate = self  // Esta línea es la que falta
        statsSection.setContentView(statsView)
    }
    
    /// Actualiza la vista de logros con las medallas actuales
    private func updateAchievements() {
        let achievementsView = AchievementsView(medals: medalManager.getMedals())
        achievementsSection.setContentView(achievementsView)
    }
    
    /// Maneja la visualización del alert para editar el nombre de usuario
    /// Maneja la visualización del alert para editar el nombre de usuario
    private func showEditUsernameAlert(currentUsername: String) {
        // Asegurarnos de que estamos en el hilo principal
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: "Editar Nombre",
                message: "Introduce tu nuevo nombre de usuario",
                preferredStyle: .alert
            )
            
            // Añadir campo de texto
            alertController.addTextField { textField in
                textField.text = currentUsername
                textField.placeholder = "Nombre de usuario"
                textField.autocapitalizationType = .words
            }
            
            // Acción de guardar
            let saveAction = UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
                guard let self = self,
                      let textField = alertController.textFields?.first,
                      let newUsername = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !newUsername.isEmpty else {
                    return
                }
                
                // Actualizar el nombre de usuario
                self.profile.username = newUsername
                self.profile.save()
                
                // Actualizar la interfaz
                self.profileHeaderView.configure(with: self.profile)
            }
            
            // Acción de cancelar
            let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel)
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            
            // Presentar el alert desde el presentador correcto
            if let presentingController = self.presentingViewController {
                presentingController.present(alertController, animated: true)
            } else {
                self.present(alertController, animated: true)
            }
        }
    }

    /// Obtiene el view controller más alto en la jerarquía
    private func getTopViewController() -> UIViewController? {
        // Obtener la escena activa y su ventana
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        var topController = keyWindow.rootViewController
        
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        
        return topController
    }
}

// MARK: - ProfileHeaderViewDelegate
extension ProfileViewController: ProfileHeaderViewDelegate {
    /// Maneja la actualización del nombre de usuario
    func profileHeaderView(_ view: ProfileHeaderView, didUpdateUsername username: String) {
        // Aquí simplemente actualizamos el modelo con el nuevo nombre
        profile.username = username
        profile.save()
    }
    
    /// Maneja la selección del avatar mostrando el picker
    func profileHeaderViewDidTapAvatar(_ view: ProfileHeaderView) {
        let avatarPicker = AvatarPickerViewController(
            selectedAvatar: profile.avatarName,
            availableAvatars: ["avatar1", "avatar2", "avatar3", "avatar8"]
        )
        avatarPicker.delegate = self
        let nav = UINavigationController(rootViewController: avatarPicker)
        present(nav, animated: true)
    }
}

// MARK: - AvatarPickerViewControllerDelegate
extension ProfileViewController: AvatarPickerViewControllerDelegate {
    /// Maneja la selección de un nuevo avatar
    func avatarPicker(_ picker: AvatarPickerViewController, didSelect avatar: String) {
        profile.avatarName = avatar
        profile.save()
        profileHeaderView.configure(with: profile)
        dismiss(animated: true)
    }
}

// MARK: - ExpandableSectionViewDelegate
extension ProfileViewController: ExpandableSectionViewDelegate {
    /// Anima los cambios cuando una sección se expande o colapsa
    func expandableSectionDidToggle(_ section: ExpandableSectionView) {
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}

// Añadir conformidad al protocolo StatsViewDelegate en la clase ProfileViewController
extension ProfileViewController: StatsViewDelegate {
    func statsViewDidTapResetButton(_ statsView: StatsView) {
        // Mostrar alerta de confirmación
        let alert = UIAlertController(
            title: "Borrar datos",
            message: "¿Estás seguro de que deseas borrar todas tus estadísticas? Esta acción no se puede deshacer.",
            preferredStyle: .alert
        )
        
        // Acción para confirmar el borrado
        let resetAction = UIAlertAction(title: "Borrar", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Crear estadísticas nuevas (resetear todo a valores iniciales)
            self.profile.statistics = Statistics()
            self.profile.save()
            
            // Actualizar la vista con las estadísticas reseteadas
            self.updateStats()
            
            // Mostrar mensaje de confirmación
            self.showToast(message: "Estadísticas restablecidas")
        }
        
        // Acción para cancelar
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel)
        
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        
        // Presentar la alerta
        present(alert, animated: true)
    }
    
    // Método auxiliar para mostrar un mensaje toast
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        view.addSubview(toastLabel)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toastLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.7),
            toastLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.5, animations: {
            toastLabel.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 1.5, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0
            }, completion: { _ in
                toastLabel.removeFromSuperview()
            })
        })
    }
}

#if DEBUG
// MARK: - SwiftUI Preview
import SwiftUI

struct ProfileViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ProfileViewController {
        // Crear datos de ejemplo para la preview
        let profile = UserProfile(
            username: "Jugador de Prueba",
            avatarName: "avatar1",
            statistics: Statistics(
                totalScore: 2500,
                currentLevel: 7,
                playTime: 7200, // 2 horas
                notesHit: 450,
                currentStreak: 15,
                bestStreak: 25,
                perfectLevelsCount: 5,
                totalGamesPlayed: 35,
                averageAccuracy: 0.88
            ),
            achievements: Achievements(
                unlockedMedals: [
                    MedalType.notesHit.rawValue: [true, true, false],
                    MedalType.playTime.rawValue: [true, true, false],
                    MedalType.streaks.rawValue: [true, true, true],
                    MedalType.perfectTuning.rawValue: [true, true, false]
                ],
                lastUpdateDate: Date()
            )
        )
        profile.save()
        
        // Crear y devolver el view controller
        let profileVC = ProfileViewController()
        return profileVC
    }
    
    func updateUIViewController(_ uiViewController: ProfileViewController, context: Context) {
        // No es necesario actualizar nada aquí
    }
}

struct ProfileViewController_Preview: PreviewProvider {
    static var previews: some View {
        // Vista de previsualización para modo claro y oscuro
        Group {
            ProfileViewControllerPreview()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.light)
                .previewDisplayName("Perfil - Modo Claro")
            
            ProfileViewControllerPreview()
                .edgesIgnoringSafeArea(.all)
                .preferredColorScheme(.dark)
                .previewDisplayName("Perfil - Modo Oscuro")
        }
    }
}
#endif
