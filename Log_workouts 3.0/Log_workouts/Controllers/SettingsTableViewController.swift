import UIKit
import RealmSwift

struct SwitchCellState {
    var isSwitchOn: Bool
    var textFieldText: String?
    var textFieldPlaceholder: String?
}

class SettingsTableViewController: UITableViewController {
    
    var switchCellStates: [SwitchCellState] = []
    var isDarkMode = false
    
    var backgroundColor: UIColor = .white
    var textColor: UIColor = .white
    
    var defaultsValue = Defaults()
    var realm: Realm!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        initializeRealm()
        NotificationCenter.default.addObserver(self, selector: #selector(appearanceDidChange), name: .appearanceDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData() // Refresh the UI whenever the view appears
    }
    
    // MARK: - Table View Data Source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4 // Number of settings options
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        isDarkMode = traitCollection.userInterfaceStyle == .dark
        tableView.separatorStyle = .none

        backgroundColor = oppositeColor(of: UIColor(red: 1.0, green: 1.0, blue: 0.6, alpha: 1.0))
        textColor = oppositeColor(of: backgroundColor)

        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.switchCell, for: indexPath) as! SwitchCell
        configureCell(cell, at: indexPath)
        return cell
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        navigationItem.title = "Settings"
        tableView.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: K.switchCell)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
    }
    
    private func initializeRealm() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Unable to initialize Realm: \(error)")
        }
    }
    
    // MARK: - Cell Configuration
    
    private func configureCell(_ cell: SwitchCell, at indexPath: IndexPath) {
        cell.selectionStyle = .none
        cell.label.textColor = textColor
        cell.backgroundColor = backgroundColor
        
        switch indexPath.row {
        case 0:
            configureAutoDeloadCell(cell)
        case 1:
            configureSuperSetCell(cell)
        case 2:
            configureIncrementWeightsCell(cell)
        case 3:
            configureDarkModeCell(cell)
        default:
            break
        }
    }
    
    private func configureAutoDeloadCell(_ cell: SwitchCell) {
        cell.textArray = ["Auto Deload Off", "Auto Deload On"]
        cell.label.text = cell.textArray[defaultsValue.deloadEnabled ? 1 : 0]
        cell.label.textColor = textColor

        cell.switchName.isOn = defaultsValue.deloadEnabled
        cell.textField.isHidden = true
    }
    
    private func configureSuperSetCell(_ cell: SwitchCell) {
        cell.textArray = ["SuperSet Disabled", "SuperSet Enabled"]
        cell.label.text = cell.textArray[defaultsValue.superSetEnabled ? 1 : 0]
        cell.switchName.isOn = defaultsValue.superSetEnabled
        cell.textField.isHidden = true
    }
    
    private func configureIncrementWeightsCell(_ cell: SwitchCell) {
        cell.textArray = ["Increment Weights Off", "Increment Weights On"]
        cell.label.text = cell.textArray[defaultsValue.incrementingWeightEnabled ? 1 : 0]
        cell.switchName.isOn = defaultsValue.incrementingWeightEnabled
        
        let weightAmount = String(defaultsValue.incrementWeightAmount)
        cell.textField.text = cell.switchName.isOn ? weightAmount : ""
        cell.textField.placeholder = cell.switchName.isOn ? "" : weightAmount
        cell.textField.isEnabled = cell.switchName.isOn
        
        configureTextFieldAppearance(cell)
    }
    
    private func configureDarkModeCell(_ cell: SwitchCell) {

        cell.textArray = ["Dark Mode", "Light Mode"]
        cell.label.text = cell.textArray[!isDarkMode ? 1 : 0]
        cell.switchName.isOn = !isDarkMode
        cell.textField.isHidden = true
    }
    
    private func configureTextFieldAppearance(_ cell: SwitchCell) {
        cell.textField.textColor = backgroundColor
        cell.textField.backgroundColor = textColor
        
        if let placeholder = cell.textField.placeholder {
            cell.textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: darkenColor(backgroundColor, by: 0.2)]
            )
        }
    }
    
    // MARK: - Actions
    
    @IBAction func save(_ sender: UIButton) {
        for cell in tableView.visibleCells {
            if let switchCell = cell as? SwitchCell {
                switchCell.update() // Update switch cell state
            }
        }
        navigationController?.popViewController(animated: true)
    }
    
    @objc func backButtonTapped() {
        let newDarkMode = traitCollection.userInterfaceStyle == .dark
        if isDarkMode != newDarkMode{
            toggleAppearance()
        }
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Color Utility Functions
    
    func darkenColor(_ color: UIColor, by percentage: CGFloat = 0.2) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return UIColor(
            red: max(red - (percentage * red), 0.0),
            green: max(green - (percentage * green), 0.0),
            blue: max(blue - (percentage * blue), 0.0),
            alpha: alpha
        )
    }
    
    func oppositeColor(of color: UIColor) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return UIColor(
            red: 1.0 - red,
            green: 1.0 - green,
            blue: 1.0 - blue,
            alpha: alpha
        )
    }
    
    // MARK: - Appearance Handling
    
    @objc func appearanceDidChange() {
        switchCellStates.removeAll()
        
        for cell in tableView.visibleCells {
            if let switchCell = cell as? SwitchCell {
                let state = SwitchCellState(
                    isSwitchOn: switchCell.switchName.isOn,
                    textFieldText: switchCell.textField.text,
                    textFieldPlaceholder: switchCell.textField.placeholder
                )
                switchCellStates.append(state)
            }
        }
        
        tableView.reloadData()
        restoreCellStates()
    }
    
    private func restoreCellStates() {
        for (index, cell) in tableView.visibleCells.enumerated() {
            if let switchCell = cell as? SwitchCell {
                let state = switchCellStates[index]
                switchCell.switchName.isOn = state.isSwitchOn
                switchCell.textField.text = state.textFieldText
                switchCell.textField.placeholder = state.textFieldPlaceholder
                switchCell.label.textColor = textColor
                switchCell.textField.textColor = backgroundColor
                switchCell.textField.backgroundColor = textColor
                
                // Handle specific logic for the increment weights and dark mode cells
                if switchCell.label.text?.contains("Increment") == true {
                    switchCell.textField.isHidden = false
                    switchCell.textField.isEnabled = switchCell.switchName.isOn
                }
                
                if switchCell.label.text?.contains("Mode") == true {
                    switchCell.label.text = switchCell.textArray[switchCell.switchName.isOn ? 1 : 0]
                }
            }
        }
    }
    
    func toggleAppearance() {
        // Check the current appearance mode
        let currentStyle = UserDefaults.standard.bool(forKey: "isDarkMode")
        let newStyle = !currentStyle
        
        // Save the new style preference
        UserDefaults.standard.set(newStyle, forKey: "isDarkMode")
        
        // Update the appearance for all windows in the current scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = newStyle ? .dark : .light
            }
        }
        
        NotificationCenter.default.post(name: .appearanceDidChange, object: nil)

    }
}
