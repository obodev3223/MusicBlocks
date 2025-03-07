//
//  StatsView.swift
//  MusicBlocks
//
//  Created by Jose R. García on 1/3/25.
//

import UIKit

protocol StatsViewDelegate: AnyObject {
    func statsViewDidTapResetButton(_ statsView: StatsView)
}

class StatsView: UIView {
    
    // MARK: - Properties
    weak var delegate: StatsViewDelegate?
    
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
        setupActions()
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
    
    private func setupActions() {
            // Añadir acción al botón de reset
            resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        }
        
    @objc private func resetButtonTapped() {
        print("Botón de reset tocado") // Añadir para depuración
        // Notificar al delegado que se ha pulsado el botón de reset
        delegate?.statsViewDidTapResetButton(self)
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

#if DEBUG
import SwiftUI

@available(iOS 17.0, *)
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsViewRepresentable()
            .padding()
            .previewDisplayName("Light Mode")
        
        StatsViewRepresentable()
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
    
    private struct StatsViewRepresentable: UIViewRepresentable {
        func makeUIView(context: Context) -> StatsView {
            let mockStats = Statistics(
                totalScore: 1500,
                currentLevel: 5,
                playTime: 3600,
                notesHit: 250,
                currentStreak: 10,
                bestStreak: 15,
                perfectLevelsCount: 3,
                totalGamesPlayed: 20,
                averageAccuracy: 0.83
            )
            return StatsView(statistics: mockStats)
        }
        
        func updateUIView(_ uiView: StatsView, context: Context) {}
    }
}
#endif
