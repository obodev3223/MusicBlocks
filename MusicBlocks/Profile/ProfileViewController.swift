//
//  ProfileViewController.swift
//  MusicBlocks
//
//  Created by Jose R. García on 1/3/25.
//

import UIKit
import SpriteKit

class ProfileViewController: UIViewController {
    // MARK: - Properties
    private var profile = UserProfile.load()
    private let medalManager = MedalManager.shared
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var profileHeaderView: ProfileHeaderView!
    private var statsSection: ExpandableSectionView!
    private var achievementsSection: ExpandableSectionView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        loadProfile()
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        title = "Perfil"
        navigationController?.navigationBar.prefersLargeTitles = false
        view.backgroundColor = .systemBackground // Asegurarse de que esto se establece
    }
    
    private func setupViews() {
        // Setup ScrollView
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemBackground // Añadir color de fondo
        view.addSubview(scrollView)
        
        // Setup ContentView
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .systemBackground // Añadir color de fondo
        scrollView.addSubview(contentView)
        
        // Setup ProfileHeaderView
        profileHeaderView = ProfileHeaderView()
        profileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderView.delegate = self
        contentView.addSubview(profileHeaderView)
        
        // Setup StatsSection
        statsSection = ExpandableSectionView(
            title: "Estadísticas",
            icon: UIImage(systemName: "chart.bar.fill"),
            iconTintColor: .systemPurple
        )
        statsSection.translatesAutoresizingMaskIntoConstraints = false
        statsSection.delegate = self
        contentView.addSubview(statsSection)
        
        // Setup AchievementsSection
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
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // ProfileHeaderView constraints
            profileHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            profileHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // StatsSection constraints
            statsSection.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor, constant: 20),
            statsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // AchievementsSection constraints
            achievementsSection.topAnchor.constraint(equalTo: statsSection.bottomAnchor, constant: 20),
            achievementsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            achievementsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            achievementsSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func loadProfile() {
        profileHeaderView.configure(with: profile)
        updateStats()
        updateAchievements()
    }
    
    private func updateStats() {
        let statsView = StatsView(statistics: profile.statistics)
        statsSection.setContentView(statsView)
    }
    
    private func updateAchievements() {
        let achievementsView = AchievementsView(medals: medalManager.getMedals())
        achievementsSection.setContentView(achievementsView)
    }
}

// MARK: - ProfileHeaderViewDelegate
extension ProfileViewController: ProfileHeaderViewDelegate {
    func profileHeaderView(_ view: ProfileHeaderView, didUpdateUsername username: String) {
        profile.username = username
        profile.save()
    }
    
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
    func avatarPicker(_ picker: AvatarPickerViewController, didSelect avatar: String) {
        profile.avatarName = avatar
        profile.save()
        profileHeaderView.configure(with: profile)
        dismiss(animated: true)
    }
}

// MARK: - ExpandableSectionViewDelegate
extension ProfileViewController: ExpandableSectionViewDelegate {
    func expandableSectionDidToggle(_ section: ExpandableSectionView) {
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}

#if DEBUG
import SwiftUI

@available(iOS 17.0, *)
extension ProfileViewController {
    private struct Preview: UIViewControllerRepresentable {
        init() {
            // Llamar a prepare antes de crear la preview
            Self.prepare()
        }
        
        func makeUIViewController(context: Context) -> ProfileViewController {
            let viewController = ProfileViewController()
            return viewController
        }
        
        func updateUIViewController(_ uiViewController: ProfileViewController, context: Context) {}
        
        // Movido prepare como método estático dentro de Preview
        private static func prepare() {
            // Crear perfil de prueba
            let profile = UserProfile(
                username: UserProfile.defaultUsername,
                avatarName: "avatar1",
                statistics: Statistics(
                    totalScore: 1500,
                    currentLevel: 5,
                    playTime: 3600,
                    notesHit: 250,
                    currentStreak: 10,
                    bestStreak: 15,
                    perfectLevelsCount: 3,
                    totalGamesPlayed: 20,
                    averageAccuracy: 0.83
                ),
                achievements: Achievements(
                    unlockedMedals: [
                        MedalType.notesHit.rawValue: [true, false, false],
                        MedalType.playTime.rawValue: [true, false, false],
                        MedalType.streaks.rawValue: [true, true, false],
                        MedalType.perfectTuning.rawValue: [true, false, false]
                    ],
                    lastUpdateDate: Date()
                )
            )
            
            // Guardar el perfil de prueba en UserDefaults
            profile.save()
        }
    }
    
    struct ProfileViewController_Preview: PreviewProvider {
        static var previews: some View {
            Group {
                // Preview en Light Mode
                Preview()
                    .ignoresSafeArea()
                    .preferredColorScheme(.light)
                
                // Preview en Dark Mode
                Preview()
                    .ignoresSafeArea()
                    .preferredColorScheme(.dark)
            }
        }
    }
}
#endif
