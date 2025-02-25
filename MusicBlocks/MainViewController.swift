import UIKit
import AVFoundation

class MainViewController: UIViewController {
    private let audioController = AudioController.sharedInstance
    
    private lazy var logoImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 80)
        let image = UIImage(systemName: "tuningfork", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .systemPurple
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "FrikiTuner"
        label.font = .systemFont(ofSize: 40, weight: .bold)
        label.textColor = .systemPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var buttonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var practiceButton: UIButton = {
        let button = createNavigationButton(
            title: "Practicar",
            symbol: "music.note",
            color: .systemPurple
        )
        button.addTarget(self, action: #selector(practiceButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var profileButton: UIButton = {
        let button = createNavigationButton(
            title: "Mi Perfil",
            symbol: "person.fill",
            color: UIColor.systemPurple.withAlphaComponent(0.8)
        )
        button.addTarget(self, action: #selector(profileButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.text = "v1.0"
        // Corregimos la definición de la fuente usando el estilo preferido del sistema
        label.font = UIFont.preferredFont(forTextStyle: .caption2)
        // O alternativamente podríamos usar un tamaño específico:
        // label.font = UIFont.systemFont(ofSize: 11) // 11 es el tamaño típico para caption2
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudio()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioController.stop()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(buttonsStackView)
        view.addSubview(versionLabel)
        
        buttonsStackView.addArrangedSubview(practiceButton)
        buttonsStackView.addArrangedSubview(profileButton)
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 15),
            
            buttonsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonsStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            versionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func createNavigationButton(title: String, symbol: String, color: UIColor) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = color
        configuration.cornerStyle = .large
        
        var container = AttributeContainer()
        container.font = .headline
        configuration.attributedTitle = AttributedString(title, attributes: container)
        
        configuration.image = UIImage(systemName: symbol)
        configuration.imagePadding = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15)
        
        let button = UIButton(configuration: configuration)
        return button
    }
    
    private func setupAudio() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            if granted {
                DispatchQueue.main.async {
                    self?.audioController.start()
                }
            }
        }
    }
    
    @objc private func practiceButtonTapped() {
        let practiceTunerVC = PracticeTunerViewController()
        navigationController?.pushViewController(practiceTunerVC, animated: true)
    }
    
    @objc private func profileButtonTapped() {
        let profileVC = ProfileViewController()
        navigationController?.pushViewController(profileVC, animated: true)
    }
}
