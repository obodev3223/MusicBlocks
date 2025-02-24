//
//  ProfileViewController.swift
//  MusicBlocks
//
//  Created by Jose R. García on 24/2/25.
//

import UIKit

class ProfileViewController: UIViewController {
    private var userProfile = UserProfile.load()
    
    private lazy var usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Nombre de usuario"
        textField.text = userProfile.username
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var saveButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .systemPurple
        configuration.title = "Guardar"
        
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Mi Perfil"
        
        view.addSubview(usernameTextField)
        view.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            saveButton.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    @objc private func saveButtonTapped() {
        guard let username = usernameTextField.text, !username.isEmpty else {
            return
        }
        
        userProfile.username = username
        userProfile.save()
        
        // Mostrar feedback al usuario
        let alertController = UIAlertController(
            title: "Perfil actualizado",
            message: "Los cambios se han guardado correctamente",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}
