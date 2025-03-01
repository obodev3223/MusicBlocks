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
        let button = UIButton()
        let image = UIImage(systemName: "trash")
        button.setImage(image, for: .normal)
        button.setTitle("Borrar datos", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.tintColor = .systemRed
        button.layer.borderColor = UIColor.systemRed.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.imageEdgeInsets = UIEdgeInsets(right: 5)
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