//
//  ProfileHeaderView.swift
//  MusicBlocks
//
//  Created by Jose R. García on 1/3/25.
//

import UIKit

protocol ProfileHeaderViewDelegate: AnyObject {
    func profileHeaderView(_ view: ProfileHeaderView, didUpdateUsername username: String)
    func profileHeaderViewDidTapAvatar(_ view: ProfileHeaderView)
    func profileHeaderViewDidRequestUsernameEdit(_ view: ProfileHeaderView, currentUsername: String) // Nuevo método
}

class ProfileHeaderView: UIView {
    // MARK: - Properties
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemPurple.cgColor
        return imageView
    }()
    
    private let editAvatarButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 30)
        button.setImage(UIImage(systemName: "pencil.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemPurple
        button.backgroundColor = .white
        button.layer.cornerRadius = 15
        return button
    }()
    
    private let usernameLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 20, weight: .medium)
            label.textAlignment = .center
            label.isUserInteractionEnabled = true
            return label
        }()
            
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameTapped))
        usernameLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc private func usernameTapped() {
        // Cambiado para usar el nombre correcto del método delegate
        delegate?.profileHeaderView(self, didUpdateUsername: usernameLabel.text ?? "")
    }
    
    private let editUsernameButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 14)
        button.setImage(UIImage(systemName: "pencil", withConfiguration: config), for: .normal)
        button.tintColor = .systemPurple
        return button
    }()
    
    weak var delegate: ProfileHeaderViewDelegate?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        [avatarImageView, editAvatarButton, usernameLabel, editUsernameButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        setupConstraints()
        setupActions()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            avatarImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 120),
            avatarImageView.heightAnchor.constraint(equalToConstant: 160),
            
            editAvatarButton.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 5),
            editAvatarButton.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 5),
            editAvatarButton.widthAnchor.constraint(equalToConstant: 30),
            editAvatarButton.heightAnchor.constraint(equalToConstant: 30),
            
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 15),
            usernameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            usernameLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            editUsernameButton.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 5),
            editUsernameButton.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        editAvatarButton.addTarget(self, action: #selector(handleAvatarTap), for: .touchUpInside)
        editUsernameButton.addTarget(self, action: #selector(handleUsernameTap), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(with profile: UserProfile) {
        usernameLabel.text = profile.username
        
        if profile.avatarName.isEmpty {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .systemPurple
        } else {
            avatarImageView.image = UIImage(named: profile.avatarName)
        }
    }
    
    // MARK: - Actions
    @objc private func handleAvatarTap() {
        delegate?.profileHeaderViewDidTapAvatar(self)
    }

    @objc private func handleUsernameTap() {
        delegate?.profileHeaderViewDidRequestUsernameEdit(self, currentUsername: usernameLabel.text ?? "")
    }
}

#if DEBUG
import SwiftUI

@available(iOS 17.0, *)
struct ProfileHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview en modo claro
        ProfileHeaderViewRepresentable()
            .frame(height: 250)
            .padding()
            .previewDisplayName("Light Mode")
        
        // Preview en modo oscuro
        ProfileHeaderViewRepresentable()
            .frame(height: 250)
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
    
    private struct ProfileHeaderViewRepresentable: UIViewRepresentable {
        func makeUIView(context: Context) -> ProfileHeaderView {
            let view = ProfileHeaderView()
            view.configure(with: UserProfile.mock)
            return view
        }
        
        func updateUIView(_ uiView: ProfileHeaderView, context: Context) {}
    }
}

extension UserProfile {
    static var mock: UserProfile {
        UserProfile(
            username: "Usuario de Prueba",
            avatarName: "avatar1",
            statistics: Statistics(
                totalScore: 1000,
                currentLevel: 5,
                playTime: 3600,
                notesHit: 100,
                currentStreak: 5,
                bestStreak: 10,
                perfectLevelsCount: 2,
                totalGamesPlayed: 15,
                averageAccuracy: 0.85
            ),
            achievements: Achievements(
                unlockedMedals: [:],
                lastUpdateDate: Date()
            )
        )
    }
}
#endif
