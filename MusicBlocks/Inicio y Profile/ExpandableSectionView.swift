//
//  ExpandableSectionView.swift
//  MusicBlocks
//
//  Created by Jose R. García on 1/3/25.
//

import SpriteKit
import UIKit
import Foundation

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
    
    // Constraints que serán activadas/desactivadas
    private var contentConstraints: [NSLayoutConstraint] = []
    private var collapsedConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    init(title: String, icon: UIImage?, iconTintColor: UIColor = .systemBlue) {
        super.init(frame: .zero)
        titleLabel.text = title
        iconImageView.image = icon
        iconImageView.tintColor = iconTintColor
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
        
        // Crear constraint para el estado colapsado (hace que el bottom de la vista sea igual al bottom del header)
        collapsedConstraint = bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        
        // Activar el constraint de colapso inicialmente ya que empezamos colapsados
        collapsedConstraint?.isActive = true
    }
    
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap))
        headerView.addGestureRecognizer(tapGesture)
        headerView.isUserInteractionEnabled = true
    }
    
    // MARK: - Public Methods
    func setContentView(_ view: UIView) {
        // Remover vista de contenido y constraints anteriores si existen
        contentView?.removeFromSuperview()
        NSLayoutConstraint.deactivate(contentConstraints)
        contentConstraints.removeAll()
        
        // Configurar nueva vista de contenido
        contentView = view
        if let contentView = contentView {
            contentView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(contentView)
            
            // Crear nuevas constraints para el contenido
            let topConstraint = contentView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8)
            let leadingConstraint = contentView.leadingAnchor.constraint(equalTo: leadingAnchor)
            let trailingConstraint = contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
            let bottomConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
            
            // Guardar las constraints para poder activarlas/desactivarlas después
            contentConstraints = [topConstraint, leadingConstraint, trailingConstraint, bottomConstraint]
            
            // Si la sección está expandida, activar las constraints de contenido y desactivar la de colapso
            if isExpanded {
                NSLayoutConstraint.activate(contentConstraints)
                collapsedConstraint?.isActive = false
                contentView.isHidden = false
                contentView.alpha = 1
            } else {
                // Si está colapsada, ocultar el contenido y no activar sus constraints
                contentView.isHidden = true
                contentView.alpha = 0
            }
        }
    }
    
    // MARK: - Actions
    @objc private func handleHeaderTap() {
        toggleSection()
    }
    
    private func toggleSection() {
        isExpanded.toggle()
        
        // Reproducir sonido apropiado
            if isExpanded {
                AudioController.sharedInstance.playUISound(.expand)
            } else {
                AudioController.sharedInstance.playUISound(.collapse)
            }
        
        UIView.animate(withDuration: 0.3) {
            // Rotar el chevron
            self.chevronImageView.transform = self.isExpanded ?
                CGAffineTransform(rotationAngle: .pi) :
                .identity
            
            if self.isExpanded {
                // Expandir: desactivar constraint de colapso, activar constraints de contenido
                self.collapsedConstraint?.isActive = false
                NSLayoutConstraint.activate(self.contentConstraints)
                self.contentView?.isHidden = false
                self.contentView?.alpha = 1
            } else {
                // Colapsar: desactivar constraints de contenido, activar constraint de colapso
                NSLayoutConstraint.deactivate(self.contentConstraints)
                self.collapsedConstraint?.isActive = true
                self.contentView?.isHidden = true
                self.contentView?.alpha = 0
            }
            
            // Forzar actualización del layout
            self.superview?.layoutIfNeeded()
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
