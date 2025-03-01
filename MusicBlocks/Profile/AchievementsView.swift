import UIKit

class AchievementsView: UIView {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        return stack
    }()
    
    private let medalStatsView = MedalStatsView()
    private let medalsGridView = MedalsGridView()
    
    init(medals: [MedalCategory]) {
        super.init(frame: .zero)
        setupViews()
        configure(with: medals)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        stackView.addArrangedSubview(medalStatsView)
        stackView.addArrangedSubview(medalsGridView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(with medals: [MedalCategory]) {
        medalStatsView.configure(with: medals)
        medalsGridView.configure(with: medals)
    }
}

// MARK: - Medal Stats View
class MedalStatsView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Progreso de Medallas"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let typeStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [titleLabel, subtitleLabel, typeStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            typeStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            typeStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            typeStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            typeStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        layer.cornerRadius = 12
        backgroundColor = .systemGray6
    }
    
    func configure(with medals: [MedalCategory]) {
        // Limpiar vista previa
        typeStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Calcular totales
        let totalStats = getTotalStats(from: medals)
        subtitleLabel.text = "\(totalStats.unlocked) de \(totalStats.total) medallas desbloqueadas"
        
        // Crear vistas para cada tipo
        MedalType.allCases.forEach { type in
            if let category = medals.first(where: { $0.type == type }) {
                let stats = getCategoryStats(for: category)
                let typeView = MedalTypeView(
                    type: type,
                    unlockedCount: stats.unlocked,
                    totalCount: stats.total
                )
                typeStackView.addArrangedSubview(typeView)
            }
        }
    }
    
    private func getTotalStats(from medals: [MedalCategory]) -> (unlocked: Int, total: Int) {
        let unlocked = medals.reduce(0) { $0 + $1.medals.filter { $0.isUnlocked }.count }
        let total = medals.reduce(0) { $0 + $1.medals.count }
        return (unlocked, total)
    }
    
    private func getCategoryStats(for category: MedalCategory) -> (unlocked: Int, total: Int) {
        let unlocked = category.medals.filter { $0.isUnlocked }.count
        return (unlocked, category.medals.count)
    }
}

// MARK: - Medal Type View
class MedalTypeView: UIView {
    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    init(type: MedalType, unlockedCount: Int, totalCount: Int) {
        super.init(frame: .zero)
        setupViews()
        configure(with: type, unlockedCount: unlockedCount, totalCount: totalCount)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [iconLabel, statsLabel, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            iconLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            iconLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            statsLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 4),
            statsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 2),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        layer.cornerRadius = 8
    }
    
    private func configure(with type: MedalType, unlockedCount: Int, totalCount: Int) {
        iconLabel.text = type.icon
        statsLabel.text = "\(unlockedCount)/\(totalCount)"
        titleLabel.text = type.shortTitle
        backgroundColor = typeColor(for: type).withAlphaComponent(0.1)
    }
    
    private func typeColor(for type: MedalType) -> UIColor {
        switch type {
        case .notesHit:
            return .systemBlue
        case .playTime:
            return .systemRed
        case .streaks:
            return .systemYellow
        case .perfectTuning:
            return .systemPurple
        }
    }
}

// MARK: - Medals Grid View
class MedalsGridView: UIView {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(with medals: [MedalCategory]) {
        // Limpiar vista previa
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Crear sección para cada categoría
        medals.forEach { category in
            let categoryView = MedalCategoryView(category: category)
            stackView.addArrangedSubview(categoryView)
        }
    }
}

// MARK: - Medal Category View
class MedalCategoryView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()
    
    private let medalsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        return stack
    }()
    
    init(category: MedalCategory) {
        super.init(frame: .zero)
        setupViews()
        configure(with: category)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [titleLabel, statsLabel, scrollView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        scrollView.addSubview(medalsStack)
        medalsStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            statsLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            statsLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            medalsStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            medalsStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            medalsStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            medalsStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            medalsStack.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    private func configure(with category: MedalCategory) {
        titleLabel.text = category.title
        let stats = getCategoryStats(for: category)
        statsLabel.text = "\(stats.unlocked)/\(stats.total)"
        
        category.medals.forEach { medal in
            let medalView = MedalView(
                medalInfo: medal,
                color: typeColor(for: category.type)
            )
            medalsStack.addArrangedSubview(medalView)
        }
    }
    
    private func getCategoryStats(for category: MedalCategory) -> (unlocked: Int, total: Int) {
        let unlocked = category.medals.filter { $0.isUnlocked }.count
        return (unlocked, category.medals.count)
    }
    
    private func typeColor(for type: MedalType) -> UIColor {
        switch type {
        case .notesHit:
            return .systemBlue
        case .playTime:
            return .systemRed
        case .streaks:
            return .systemYellow
        case .perfectTuning:
            return .systemPurple
        }
    }
}

// MARK: - Medal View
class MedalView: UIView {
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "lock.fill")
        imageView.tintColor = .white
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let requirementLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    init(medalInfo: MedalInfo, color: UIColor) {
        super.init(frame: .zero)
        setupViews()
        configure(with: medalInfo, color: color)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        [imageView, lockImageView, nameLabel, requirementLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            lockImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            lockImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            lockImageView.widthAnchor.constraint(equalToConstant: 20),
            lockImageView.heightAnchor.constraint(equalToConstant: 20),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            requirementLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            requirementLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            requirementLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            requirementLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        layer.cornerRadius = 12
        backgroundColor = .systemGray6
        
        // Establecer ancho fijo para cada medalla
        widthAnchor.constraint(equalToConstant: 120).isActive = true
    }
    
    private func configure(with medalInfo: MedalInfo, color: UIColor) {
        // Configurar imagen
        imageView.image = UIImage(named: medalInfo.image)
        imageView.alpha = medalInfo.isUnlocked ? 1.0 : 0.3
        
        // Configurar visibilidad del candado
        lockImageView.isHidden = medalInfo.isUnlocked
        
        // Configurar textos
        nameLabel.text = medalInfo.name
        nameLabel.textColor = medalInfo.isUnlocked ? .label : .secondaryLabel
        
        requirementLabel.text = medalInfo.requirement
        
        // Configurar borde
        layer.borderWidth = 2
        layer.borderColor = medalInfo.isUnlocked ? color.cgColor : UIColor.systemGray.cgColor
        
        // Configurar opacidad general
        alpha = medalInfo.isUnlocked ? 1.0 : 0.8
        
        // Añadir superposición oscura si está bloqueada
        if !medalInfo.isUnlocked {
            let overlayView = UIView()
            overlayView.backgroundColor = .black
            overlayView.alpha = 0.3
            overlayView.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(overlayView, aboveSubview: imageView)
            
            NSLayoutConstraint.activate([
                overlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
                overlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                overlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                overlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
            
            overlayView.layer.cornerRadius = 30
            overlayView.clipsToBounds = true
        }
    }
}
