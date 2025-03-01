//
//  StatsView.swift
//  MusicBlocks
//
//  Created by Jose R. García on 1/3/25.
//

import UIKit

class StatsView: UIView {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        return stack
    }()
    
    private let resetButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        
        // Configurar el contenido
        configuration.image = UIImage(systemName: "trash")
        configuration.title = "Borrar datos"
        configuration.imagePadding = 5 // Espaciado entre imagen y texto
        
        // Configurar el estilo
        configuration.baseForegroundColor = .systemRed
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        
        // Crear el botón con la configuración
        let button = UIButton(configuration: configuration)
        
        // Configurar el borde
        button.layer.borderColor = UIColor.systemRed.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 8
        
        return button
    }()
    
    init(statistics: Statistics) {
        super.init(frame: .zero)
        setupViews()
        configure(with: statistics)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        addSubview(resetButton)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            resetButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16),
            resetButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            resetButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    private func configure(with statistics: Statistics) {
        // Limpiar vista previa
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Añadir filas de estadísticas
        addStatRow(title: "Puntuación Total", value: statistics.formattedTotalScore)
        addStatRow(title: "Nivel Actual", value: "\(statistics.currentLevel)")
        addStatRow(title: "Tiempo de Juego", value: statistics.formattedPlayTime)
        addStatRow(title: "Notas acertadas", value: "\(statistics.notesHit)")
        addStatRow(title: "Precisión", value: statistics.formattedAccuracy)
        addStatRow(title: "Mejor racha", value: "\(statistics.bestStreak)")
    }
    
    private func addStatRow(title: String, value: String) {
        let row = StatRowView(title: title, value: value)
        stackView.addArrangedSubview(row)
    }
}

class StatRowView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    init(title: String, value: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        valueLabel.text = value
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [titleLabel, valueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}
