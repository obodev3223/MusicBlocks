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
        let alert = UIAlertController(
            title: "Editar nombre",
            message: "Introduce tu nuevo nombre de usuario",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.text = self.usernameLabel.text
            textField.clearButtonMode = .whileEditing
        }
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let newUsername = textField.text,
                  !newUsername.isEmpty else { return }
            
            self.usernameLabel.text = newUsername
            self.delegate?.profileHeaderView(self, didUpdateUsername: newUsername)
        })
        
        // Obtener la ventana principal usando la nueva API
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}
