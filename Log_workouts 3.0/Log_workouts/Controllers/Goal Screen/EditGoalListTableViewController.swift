import UIKit
import SwipeCellKit
import RealmSwift

class EditGoalListTableViewController: UITableViewController {
    var goals: [Goal] = []
    var realm: Realm!
    weak var delegate: EditExerciseDelegate?


    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "EditGoalTableViewCell", bundle: nil), forCellReuseIdentifier: K.editGoalTableViewCell)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))

        do {
            realm = try Realm()
        } catch {
            fatalError("Unable to initialize Realm: \(error)")
        }
        
        for goal in realm.objects(Goal.self) {
            goals.append(goal)
        }
        self.navigationItem.title = "Edit Goals"
    }

    // MARK: - Table View Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.separatorStyle = .none
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: K.editGoalTableViewCell, for: indexPath) as? EditGoalTableViewCell else {
            return UITableViewCell()
        }
        
        let currentGoal = goals[indexPath.row]
        cell.goalLabel.setTitle(currentGoal.name, for: .normal)
        cell.goalRepsTextField.text = String(currentGoal.goalReps)
        
        cell.onButtonTap = { [weak self] in
              guard let self = self else { return }

              let alert = UIAlertController(title: "Rename Goal", message: "", preferredStyle: .alert)
              alert.addTextField { textField in
                  textField.placeholder = currentGoal.name
                  textField.text = currentGoal.name
              }

              let action = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
                  guard let self = self, let textField = alert.textFields?.first,
                        let newName = textField.text, !newName.isEmpty else { return }
                  
                  // Update goal name in Realm
                  try? self.realm.write {
                      currentGoal.name = newName
                  }

                  // Update cell label
                  cell.goalLabel.setTitle(newName, for: .normal)
              }

              alert.addAction(action)
              self.present(alert, animated: true, completion: nil)
          }

        let on = currentGoal.weightEnabled
        
        cell.weightEnabledSwitch.isOn = on
        cell.weightenabledLabel.text = on ? "Weights On" : "Weights Off"
        cell.goal = currentGoal
        cell.selectionStyle = .none

        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let color = darkenColor(.blue, by: 0.6)
        let textColor = isDarkMode ? oppositeColor(of: color) : color
        let backgroundColor = oppositeColor(of: textColor)

        cell.backgroundColor = backgroundColor
        cell.goalLabel.setTitleColor(textColor, for: .normal)
        cell.repsLabel.textColor = textColor
        cell.weightenabledLabel.textColor = textColor
        cell.goalRepsTextField.backgroundColor = textColor
        cell.goalRepsTextField.textColor = backgroundColor
        
        if let text = cell.goalRepsTextField.placeholder {
            cell.goalRepsTextField.attributedPlaceholder = NSAttributedString(
                string: text,
                attributes: [NSAttributedString.Key.foregroundColor: backgroundColor.withAlphaComponent(0.7)] // Replace with desired color
            )
        }

        return cell
    }

    // MARK: - Actions

    @IBAction func savePressed(_ sender: UIButton) {
        for cell in tableView.visibleCells {
            if let editCell = cell as? EditGoalTableViewCell {
                editCell.updateGoal()
            }
        }
        
        delegate?.didUpdateExercises()

        // Dismiss the view controller
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Color Helper Functions

    func oppositeColor(of color: UIColor) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get the current RGB and alpha values of the color
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate the opposite color by inverting each component
        return UIColor(
            red: 1.0 - red,
            green: 1.0 - green,
            blue: 1.0 - blue,
            alpha: alpha // Keep the original alpha
        )
    }

    func darkenColor(_ color: UIColor, by percentage: CGFloat = 0.2) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get the current RGB and alpha values of the color
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Decrease each color component by the percentage, ensuring they stay within bounds
        return UIColor(
            red: max(red - (percentage * red), 0.0),  // Ensure the red component does not go below 0
            green: max(green - (percentage * green), 0.0), // Ensure the green component does not go below 0
            blue: max(blue - (percentage * blue), 0.0), // Ensure the blue component does not go below 0
            alpha: alpha // Keep the original alpha
        )
    }

    // MARK: - Navigation

    @objc func backButtonTapped() {
        
        delegate?.didUpdateExercises()

        
        navigationController?.popViewController(animated: true)
    }
    
}
