//
//  AvatarPickerViewController.swift
//  MusicBlocks
//
//  Created by Jose R. García on 1/3/25.
//

import UIKit

protocol AvatarPickerViewControllerDelegate: AnyObject {
    func avatarPicker(_ picker: AvatarPickerViewController, didSelect avatar: String)
}

class AvatarPickerViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let collectionView: UICollectionView
    private let availableAvatars: [String]
    private var selectedAvatar: String
    
    weak var delegate: AvatarPickerViewControllerDelegate?
    
    init(selectedAvatar: String, availableAvatars: [String]) {
        self.selectedAvatar = selectedAvatar
        self.availableAvatars = availableAvatars
        
        // Configurar el layout con tamaños estimados
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        title = "Elegir Avatar"
        view.backgroundColor = .systemBackground
        
        // Configurar botones de navegación
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancelar",
            style: .plain,
            target: self,
            action: #selector(handleCancel)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Guardar",
            style: .done,
            target: self,
            action: #selector(handleSave)
        )
        
        // Configurar collection view
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AvatarCell.self, forCellWithReuseIdentifier: "AvatarCell")
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func handleCancel() {
        dismiss(animated: true)
    }
    
    @objc private func handleSave() {
        delegate?.avatarPicker(self, didSelect: selectedAvatar)
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableAvatars.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarCell", for: indexPath) as! AvatarCell
        let avatar = availableAvatars[indexPath.item]
        cell.configure(with: avatar, isSelected: avatar == selectedAvatar)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedAvatar = availableAvatars[indexPath.item]
        collectionView.reloadData()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.width - 48
        let width = availableWidth / 3
        let height = width * 1.4
        
        return CGSize(width: width, height: height)
    }
}

// MARK: - Avatar Cell
class AvatarCell: UICollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(nameLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container constraints
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Image constraints
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor), // Aspecto cuadrado
            
            // Label constraints
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with avatar: String, isSelected: Bool) {
        imageView.image = UIImage(named: avatar)
        nameLabel.text = avatar
        
        containerView.layer.borderWidth = isSelected ? 3 : 0
        containerView.layer.borderColor = isSelected ? UIColor.systemPurple.cgColor : nil
        containerView.backgroundColor = isSelected ? .systemPurple.withAlphaComponent(0.1) : .systemBackground
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        nameLabel.text = nil
        containerView.layer.borderWidth = 0
        containerView.layer.borderColor = nil
        containerView.backgroundColor = .systemBackground
    }
}
