//
//  TopBarView.swift
//  MusicBlocks
//
//  Created by Jose R. García on 24/2/25.
//

import UIKit

class TopBarView: UIView {
    private let livesStackView = UIStackView()
    private let scoreLabel = UILabel()
    private var heartImages: [UIImageView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 5
        
        // Setup lives stack view
        livesStackView.axis = .horizontal
        livesStackView.spacing = 5
        addSubview(livesStackView)
        livesStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup score label
        scoreLabel.font = .systemFont(ofSize: 20, weight: .bold)
        addSubview(scoreLabel)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            livesStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            livesStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            scoreLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            scoreLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func update(lives: Int, maxLives: Int, score: Int) {
        // Update hearts
        heartImages.forEach { $0.removeFromSuperview() }
        heartImages.removeAll()
        
        for i in 0..<maxLives {
            let imageView = UIImageView(image: UIImage(systemName: i < lives ? "heart.fill" : "heart"))
            imageView.tintColor = .red
            heartImages.append(imageView)
            livesStackView.addArrangedSubview(imageView)
        }
        
        // Update score
        scoreLabel.text = "Score: \(score)"
    }
}
