import UIKit
import RealmSwift

// MARK: - HomeViewController

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    
    var realm: Realm!
    var defaultsValue = Defaults()
    
    // MARK: - Outlets
    
    @IBOutlet weak var workoutButton: UIButton!
    @IBOutlet weak var goalsButton: UIButton!
    @IBOutlet weak var templateButton: UIButton!
    @IBOutlet weak var chartButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDefaults()
        configureNavigationBar()
        setupUI()
        registerNotifications()
        genMode()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - Setup Methods
    
    private func genMode(){
        let newStyle = UserDefaults.standard.bool(forKey: "isDarkMode")

        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = newStyle ? .dark : .light
            }
        }
    }
    
    private func setupDefaults() {
        defaultsValue.templateOn = false
        configureRealm()
    }
    
    private func configureRealm() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Unable to initialize Realm: \(error)")
        }
    }
    
    private func configureNavigationBar() {
        navigationItem.title = "Workout Logger"
        navigationItem.hidesBackButton = true
        navigationController?.navigationBar.backgroundColor = .blue.withAlphaComponent(0.5)
    }
    
    private func setupUI() {
        applyAppearance()
        setupButtonCorners()
        setupVerticalStackView()
        updateExerciseList()
    }
    
    private func setupButtonCorners() {
        goalsButton.layer.cornerRadius = 5
        goalsButton.clipsToBounds = true
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(appearanceDidChange), name: .appearanceDidChange, object: nil)
    }
    
    // MARK: - Appearance
    
    private func applyAppearance() {
        let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        overrideUserInterfaceStyle = isDarkMode ? .dark : .light
    }
    
    @objc private func appearanceDidChange() {
        applyAppearance()
    }
    
    // MARK: - Stack View Setup
    
    func setupVerticalStackView() {
        let stackView = UIStackView(arrangedSubviews: [workoutButton, goalsButton, templateButton, chartButton, settingsButton])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 16
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 150),
            stackView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.50)
        ])
    }
    
    // MARK: - Exercise List Update
    
    func updateExerciseList() {
        for bodypart in realm.objects(BodyPart.self) {
            for exercise in bodypart.exercise {
                handleExercise(exercise)
            }
        }
    }
    
    private func handleExercise(_ exercise: Exercise) {
        if exercise.deloadOn {
            handleDeloadExercise(exercise)
        } else {
            handleRegularExercise(exercise)
        }
    }
    
    private func handleDeloadExercise(_ exercise: Exercise) {
        if !defaultsValue.deloadEnabled {
            write(for: exercise)
        } else if let deloadDate = exercise.deloadDate {
            let daysDifference = Calendar.current.dateComponents([.day], from: deloadDate, to: Date()).day ?? 0
            if daysDifference > 9 {
                write(for: exercise)
            }
        }
    }
    
    private func handleRegularExercise(_ exercise: Exercise) {
        if defaultsValue.deloadEnabled {
            updateDeloadValues(for: exercise)
        }
    }
    
    private func updateDeloadValues(for exercise: Exercise) {
        do {
            try realm.write {
                exercise.deloadReps = exercise.currentReps
                exercise.deloadWeight = exercise.currentWeight
            }
        } catch {
            print("Error updating deload values: \(error)")
        }
    }
    
    // MARK: - Write Method
    
    func write(for exercise: Exercise) {
        do {
            try realm.write {
                exercise.deloadOn = false
                exercise.currentReps *= 2
                exercise.currentWeight *= 2
                exercise.deloadReps = 0
                exercise.deloadWeight = 0.0
            }
        } catch {
            print("Error writing exercise data: \(error)")
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let appearanceDidChange = Notification.Name("appearanceDidChange")
}
