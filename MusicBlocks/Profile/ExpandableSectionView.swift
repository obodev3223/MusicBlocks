//
//  ExpandableSectionView.swift
//  MusicBlocks
//
//  Created by Jose R. García on 1/3/25.
//

import UIKit

protocol ExpandableSectionViewDelegate: AnyObject {
    func expandableSectionDidToggle(_ section: ExpandableSectionView)
}

class ExpandableSectionView: UIView {
    // MARK: - Properties
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 14)
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var contentView: UIView?
    private var isExpanded = false
    weak var delegate: ExpandableSectionViewDelegate?
    
    // Nueva propiedad para controlar el espacio entre el header y el contenido
    private var contentTopPadding: CGFloat = 0
    
    // MARK: - Initialization
    init(title: String, icon: UIImage?, iconTintColor: UIColor = .systemBlue, contentTopPadding: CGFloat = 8) {
        super.init(frame: .zero)
        titleLabel.text = title
        iconImageView.image = icon
        iconImageView.tintColor = iconTintColor
        self.contentTopPadding = contentTopPadding
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        [headerView, iconImageView, titleLabel, chevronImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        addSubview(headerView)
        headerView.addSubview(iconImageView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(chevronImageView)
        
        setupConstraints()
        setupGesture()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            iconImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            chevronImageView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),
            
            headerView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap))
        headerView.addGestureRecognizer(tapGesture)
        headerView.isUserInteractionEnabled = true
    }
    
    // MARK: - Public Methods
    func setContentView(_ view: UIView) {
        // Remover vista de contenido anterior si existe
        contentView?.removeFromSuperview()
        
        // Configurar nueva vista de contenido
        contentView = view
        if let contentView = contentView {
            contentView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(contentView)
            
            NSLayoutConstraint.activate([
                // Usar el valor de contentTopPadding en lugar del valor fijo de 8
                contentView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: contentTopPadding),
                contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            
            // Ocultar inicialmente el contenido
            contentView.isHidden = !isExpanded
            contentView.alpha = isExpanded ? 1 : 0
        }
    }
    
    // MARK: - Actions
    @objc private func handleHeaderTap() {
        toggleSection()
    }
    
    private func toggleSection() {
        isExpanded.toggle()
        
        UIView.animate(withDuration: 0.3) {
            // Rotar el chevron
            self.chevronImageView.transform = self.isExpanded ?
                CGAffineTransform(rotationAngle: .pi) :
                .identity
            
            // Mostrar/ocultar contenido
            self.contentView?.isHidden = !self.isExpanded
            self.contentView?.alpha = self.isExpanded ? 1 : 0
        }
        
        delegate?.expandableSectionDidToggle(self)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Aplicar sombra al header
        headerView.layer.shadowColor = UIColor.black.cgColor
        headerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        headerView.layer.shadowRadius = 4
        headerView.layer.shadowOpacity = 0.1
        headerView.layer.masksToBounds = false
    }
}
