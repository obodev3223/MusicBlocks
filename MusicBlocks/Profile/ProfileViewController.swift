import UIKit
import SpriteKit

class ProfileViewController: UIViewController {
    // MARK: - Properties
    private var profile = UserProfile.load()
    private let medalManager = MedalManager.shared
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var profileHeaderView: ProfileHeaderView!
    private var statsSection: ExpandableSectionView!
    private var achievementsSection: ExpandableSectionView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupViews()
        loadProfile()
    }
    
    // MARK: - Setup
    private func setupNavigationBar() {
        title = "Perfil"
        navigationController?.navigationBar.prefersLargeTitles = false
        view.backgroundColor = .systemBackground
    }
    
    private func setupViews() {
        // Setup ScrollView
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Setup ContentView
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Setup ProfileHeaderView
        profileHeaderView = ProfileHeaderView()
        profileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        profileHeaderView.delegate = self
        contentView.addSubview(profileHeaderView)
        
        // Setup StatsSection
        statsSection = ExpandableSectionView(
            title: "Estadísticas",
            icon: UIImage(systemName: "chart.bar.fill"),
            iconTintColor: .systemPurple
        )
        statsSection.translatesAutoresizingMaskIntoConstraints = false
        statsSection.delegate = self
        contentView.addSubview(statsSection)
        
        // Setup AchievementsSection
        achievementsSection = ExpandableSectionView(
            title: "Logros",
            icon: UIImage(systemName: "trophy.fill"),
            iconTintColor: .systemYellow
        )
        achievementsSection.translatesAutoresizingMaskIntoConstraints = false
        achievementsSection.delegate = self
        contentView.addSubview(achievementsSection)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // ProfileHeaderView constraints
            profileHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            profileHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // StatsSection constraints
            statsSection.topAnchor.constraint(equalTo: profileHeaderView.bottomAnchor, constant: 20),
            statsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // AchievementsSection constraints
            achievementsSection.topAnchor.constraint(equalTo: statsSection.bottomAnchor, constant: 20),
            achievementsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            achievementsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            achievementsSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func loadProfile() {
        profileHeaderView.configure(with: profile)
        updateStats()
        updateAchievements()
    }
    
    private func updateStats() {
        let statsView = StatsView(statistics: profile.statistics)
        statsSection.setContentView(statsView)
    }
    
    private func updateAchievements() {
        let achievementsView = AchievementsView(medals: medalManager.getMedals())
        achievementsSection.setContentView(achievementsView)
    }
}

// MARK: - ProfileHeaderViewDelegate
extension ProfileViewController: ProfileHeaderViewDelegate {
    func profileHeaderView(_ view: ProfileHeaderView, didUpdateUsername username: String) {
        profile.username = username
        profile.save()
    }
    
    func profileHeaderViewDidTapAvatar(_ view: ProfileHeaderView) {
        let avatarPicker = AvatarPickerViewController(
            selectedAvatar: profile.avatarName,
            availableAvatars: ["avatar1", "avatar2", "avatar3", "avatar8"]
        )
        avatarPicker.delegate = self
        let nav = UINavigationController(rootViewController: avatarPicker)
        present(nav, animated: true)
    }
}

// MARK: - AvatarPickerViewControllerDelegate
extension ProfileViewController: AvatarPickerViewControllerDelegate {
    func avatarPicker(_ picker: AvatarPickerViewController, didSelect avatar: String) {
        profile.avatarName = avatar
        profile.save()
        profileHeaderView.configure(with: profile)
        dismiss(animated: true)
    }
}

// MARK: - ExpandableSectionViewDelegate
extension ProfileViewController: ExpandableSectionViewDelegate {
    func expandableSectionDidToggle(_ section: ExpandableSectionView) {
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}
