import UIKit
import RealmSwift


class EditExerciseTableViewController: UITableViewController {
    weak var delegate: EditExerciseDelegate?
    var defaultsValue = Defaults()
    var exercises : [Exercise] = []
    var bodyPartController = false
    var bodyParts : [BodyPart] = []
    

    var realm: Realm!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: K.switchCell)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))


        do {
            realm = try Realm()
        } catch {
            fatalError("Unable to initialize Realm: \(error)")
        }
        self.navigationItem.title = bodyPartController ? "Edit Muscle Groups" : "Edit Exercises"
        
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if bodyPartController{
            return bodyParts.count
        }
        return 3 * exercises.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        
        let color = isDarkMode ? UIColor(red: 0, green: 0.2, blue: 0.4, alpha: 0.9) : UIColor(red: 1.0, green: 1.0, blue: 0.6, alpha: 1.0)
        let backgroundColor = color
        let textColor = oppositeColor(of: color)
        
        tableView.separatorStyle = .none
        let darkerBackgroundColor = darkenColor(backgroundColor, by: 0.3)
        let darkertextColor = darkenColor(textColor, by: 0.3)

 
        
        // Determine which type of cell to display based on the row
        if bodyPartController{
            let bodyPart = bodyParts[indexPath.row]
            return titleCell(indexPath: indexPath, backgroundColor: darkerBackgroundColor, textColor: darkertextColor, title: bodyPart.name)
        } else{
            
            let exerciseIndex = indexPath.row / 3
            let exercise = exercises[exerciseIndex]
            
            switch indexPath.row % 3 {
            case 0:
                // Row 0: Cell for exercise name
                return titleCell(indexPath: indexPath, backgroundColor: darkerBackgroundColor, textColor: darkertextColor, title: exercise.title)
                
            case 1:
                // Row 1: Bodyweight toggle (Switch cell)
                guard let cell = tableView.dequeueReusableCell(withIdentifier: K.switchCell, for: indexPath) as? SwitchCell else{ return UITableViewCell()}
                
                cell.textArray = ["Bodyweight", "Weights"]
                cell.exerciseName = exercise.title
                cell.label.text = cell.textArray[exercise.weights ? 1 : 0]
                cell.switchName.isOn = exercise.weights // Assuming 'isBodyweight' is a property of Exercise
                cell.textField.isHidden = true
                cell.selectionStyle = .none
                
                cell.textLabel?.textColor = textColor
                cell.backgroundColor = backgroundColor

                // Add more configurations here if needed
                return cell
                
            default:
                // Row 2: Increment weight toggle (Switch cell)
                guard let cell = tableView.dequeueReusableCell(withIdentifier: K.switchCell, for: indexPath) as? SwitchCell else{ return UITableViewCell()}

                cell.exerciseName = exercise.title
                cell.textArray = ["Increment Weight off", "Increment Weight on"]
                cell.label.text = cell.textArray[exercise.incrementWeights ? 1 : 0]
                cell.switchName.isOn = exercise.incrementWeights // Assuming 'isIncrementWeight' is a property of Exercise
                cell.textField.isHidden = true
                cell.selectionStyle = .none
                
                cell.textLabel?.textColor = textColor
                cell.backgroundColor = backgroundColor

                // Add more configurations here if needed
                return cell
            }
        }
    }
    
    func titleCell(indexPath: IndexPath, backgroundColor: UIColor, textColor: UIColor, title: String) -> SwitchCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.switchCell, for: indexPath) as! SwitchCell
        cell.selectionStyle = .none
        cell.backgroundColor = backgroundColor
        cell.textLabel?.textColor = backgroundColor
        cell.exerciseName = title
        cell.textField.text = title
        cell.textField.textColor = backgroundColor
        cell.textField.backgroundColor = textColor
        cell.switchName.isHidden = true
        cell.label.isHidden = true
    

        return cell
    }

  
    @IBAction func save(_ sender: Any) {
        if !bodyPartController{
            for cell in tableView.visibleCells {
                if let switchCell = cell as? SwitchCell {
                    for exercise in exercises {
                        if exercise.title == switchCell.exerciseName{
                            if !switchCell.switchName.isHidden{
                                switchCell.updateExercice(exercise)
                            }
                        }
                    }
                }
            }
            
            for cell in tableView.visibleCells {
                if let switchCell = cell as? SwitchCell,
                   let indexPath = tableView.indexPath(for: switchCell) {
                    if indexPath.row % 3 == 0 {
                        guard let exercise = realm.objects(Exercise.self).filter("title == %@", switchCell.exerciseName).first else { return }

                        
                        guard let text = switchCell.textField.text else{ return }
                        
                        
                        try? realm.write{
                            exercise.title = text
                        }
                    }
                }
            }
        } else {
            for cell in tableView.visibleCells {
                if let switchCell = cell as? SwitchCell,
                   let indexPath = tableView.indexPath(for: switchCell) {
                    guard let bodyPart = realm.objects(BodyPart.self).filter("name == %@", switchCell.exerciseName).first else { return }
                        
                        guard let text = switchCell.textField.text else{ return }
                        
                        try? realm.write{
                            bodyPart.name = text
                        }
                    }
                }
            }
       
        
        delegate?.didUpdateExercises()

        
        navigationController?.popViewController(animated: true)
    }
 
    
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
    @objc func backButtonTapped() {
        // Handle back button tap action
        navigationController?.popViewController(animated: true)
    }
}


protocol EditExerciseDelegate: AnyObject {
    func didUpdateExercises()
}

