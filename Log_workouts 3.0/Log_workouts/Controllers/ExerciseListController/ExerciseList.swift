import UIKit
import RealmSwift
class ExerciseList: UITableViewController{
    var realm: Realm!
    var defaultsValue = Defaults()
    var trainingScreen = false
    var superSetEnabled = false
    var segueIdentifier: String = ""
    var headingCellsAmount = 0
    var extraCells = 0
    var currentSet = ""
    var setCounter: [String:Int] = [:]
    var listOfSupersetTypes: [String] = []
    var textColor : UIColor = .black
    var backgroundColor : UIColor = .white

    
    lazy var exerciseList: [Exercise] = {
        return returnExerciseList()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeRealm()
        registerCells()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))

    }
    
    // MARK: - Realm Initialization
    private func initializeRealm() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Unable to initialize Realm: \(error)")
        }
    }

    private func returnExerciseList() -> [Exercise] {
        superSetEnabled = defaultsValue.superSetEnabled
        var superSetTypes: [Int] = [] // Array to hold unique superset values
        var orderedExercises: [Exercise] = []
        let bodyParts = realm.objects(BodyPart.self) // Fetch body parts from realm


        for bodyPart in bodyParts {
            let bodyPartExercises = bodyPart.exercise

            // Filter the exercises based on the current `superSetEnabled` state
            let filteredExercises = bodyPartExercises.filter { exercise in
                let val = exercise.supersetValue // Get the supersetValue


                if self.superSetEnabled {
                    if !superSetTypes.contains(val) && val < 4 {
                        superSetTypes.append(val)
                        self.headingCellsAmount += 1
                        
                    }
                    return val < 4 // Only return exercises with supersetValue < 4
                } else {
                    return exercise.order > 0 // Filter based on order if superSetEnabled is false
                }
            }

            // Update headingCellsAmount with the count of unique superset values
            orderedExercises.append(contentsOf: filteredExercises) // Append the filtered exercises
        }

        return orderedExercises // Return the ordered list of exercises
    }

    
    // MARK: - Cell Registration
    private func registerCells() {

        tableView.register(UINib(nibName: "ButtonCell", bundle: nil), forCellReuseIdentifier: K.buttonCell)
        
        //MARK: - Workout Preview Screen Cells
        tableView.register(UINib(nibName: "PreviewHeadingCell", bundle: nil), forCellReuseIdentifier: K.previewHeadingCell)
        tableView.register(UINib(nibName: "StandardWorkoutPreviewCell", bundle: nil), forCellReuseIdentifier: K.standardWorkoutPreviewCell)
        tableView.register(UINib(nibName: "SuperSetWorkoutPreviewCell", bundle: nil), forCellReuseIdentifier: K.superSetWorkoutPreviewCell)

        //MARK: - Training Screen
        tableView.register(UINib(nibName: "SuperSetExerciseCell", bundle: nil), forCellReuseIdentifier: K.superSetExerciseCell)
        tableView.register(UINib(nibName: "SuperSetHeadingCell", bundle: nil), forCellReuseIdentifier: K.superSetHeadingCell)
        tableView.register(UINib(nibName: "StandardExerciseCell", bundle: nil), forCellReuseIdentifier: K.standardExerciseCell)

        
        tableView.separatorStyle = .none

    }
    
    func returnString(_ index: Int) -> String{
        var text = ""
        switch index{
        case 0:
            text = "A"
        case 1:
            text = "B"
        case 2:
            text = "C"
        default:
            text = "D"
        }
        
        return text
    }
    
    //MARK: - Configure & Generate Cells

    func configureExerciseCell(for indexPath: IndexPath, exercise: Exercise, identifier: String) -> UITableViewCell {
        var cell: UITableViewCell?
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        
        if trainingScreen{
            backgroundColor = isDarkMode ? darkenColor(oppositeColor(of: darkenColor(UIColor.red, by: 0.6)), by: 0.6) : UIColor.red
        } else {
            backgroundColor = isDarkMode ? darkenColor(oppositeColor(of: darkenColor(UIColor.blue, by: 0.6)), by: 0.6) : UIColor.blue

        }
        
                
        textColor = isDarkMode ? darkenColor(getColor(from: backgroundColor), by: 0.2) : oppositeColor(of: backgroundColor)
     

        switch identifier {
            case K.superSetExerciseCell:
                if let superSetCell = genSuperSetExerciseCell(exercise, for: indexPath) {
                    superSetCell.selectionStyle = .none
                    cell = superSetCell
                }
            
            case K.standardWorkoutPreviewCell:
                if let standardCell = genStandardWorkoutPreviewCell(exercise, for: indexPath) {
                    standardCell.selectionStyle = .none
                    cell = standardCell
                }
            case K.superSetWorkoutPreviewCell:
                if let superSetWorkoutPreviewCell = genSuperSetWorkoutPreviewCell(exercise, for: indexPath) {
                    superSetWorkoutPreviewCell.selectionStyle = .none
                    cell = superSetWorkoutPreviewCell
                }
            case K.superSetHeadingCell:
                if let superSetHeadingCell = genSuperSetHeadingCell(exercise, for: indexPath) {
                    superSetHeadingCell.selectionStyle = .none
                    cell = superSetHeadingCell
                }
            case K.previewHeadingCell:
                if let previewHeadingCell = genPreviewHeadingCell(exercise, for: indexPath) {
                    previewHeadingCell.selectionStyle = .none
                    cell = previewHeadingCell
                }
            default:
                print("Failed to dequeue cell with identifier: \(identifier)")
                return UITableViewCell() // Or handle default case appropriately
            }
        
            
        // Handle the case where the cell could not be dequeued
        if cell == nil {
            print("Failed to dequeue cell with identifier: \(identifier)")
            // Optionally, return a default UITableViewCell
            cell = UITableViewCell()  // Or return a nil cell if desired
        }
        
        let headingIdentifiers = [K.previewHeadingCell, K.superSetHeadingCell]
        if headingIdentifiers.contains(identifier){
            cell?.backgroundColor = textColor.withAlphaComponent(0.8)
        }else{
            cell?.backgroundColor = backgroundColor
        }
        

        
        return cell!
    }

    func genSuperSetHeadingCell(_ exercise: Exercise, for indexPath: IndexPath) -> SuperSetHeadingCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: K.superSetHeadingCell, for: indexPath) as? SuperSetHeadingCell else {
            print("Failed to dequeue SuperSetHeadingCell")
            return nil
        }

        cell.setName.text = currentSet
        cell.setName.textColor = textColor


        if let setCount = defaultsValue.setCounter[currentSet] {
            cell.setAmounts.text = "Sets: \(setCount)"
        } else {
            cell.setAmounts.text = "Sets: 0" // Default value or handle the case where it's nil
        }
        
        cell.setName.textColor = backgroundColor
        cell.setAmounts.textColor = backgroundColor

        return cell
    }
        
    func genSuperSetExerciseCell(_ exercise: Exercise, for indexPath: IndexPath) -> SuperSetExerciseCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: K.superSetExerciseCell, for: indexPath) as? SuperSetExerciseCell else {
            print("Failed to dequeue ExerciseCell")
            return nil
        }
        
        cell.exerciseLabel.text = exercise.title
        cell.repsTextField.text = "\(exercise.currentReps) Reps"
        cell.weightTextField.isHidden = false
        cell.alignmentTextfield.isHidden = true
        if exercise.weights{
            if !exercise.IncrementAdded{
                cell.weightTextField.text = "\(exercise.currentWeight + returnIncrementAmount(exercise)) lb"
            } else{
                cell.weightTextField.text = "\(exercise.currentWeight) lb"
            }
            
        }else{
            cell.alignmentTextfield.isHidden = false
            cell.alignmentTextfield.backgroundColor = backgroundColor
            cell.alignmentTextfield.textColor = backgroundColor
            cell.alignmentTextfield.isEnabled = false
            cell.alignmentTextfield.borderStyle = .none
            cell.weightTextField.isHidden = true
        }
        
        cell.exerciseLabel.textColor = textColor
        cell.repsTextField.textColor = backgroundColor
        cell.repsTextField.backgroundColor = brightenColor(textColor, by: 0.2)
        cell.weightTextField.textColor =  backgroundColor
        cell.weightTextField.backgroundColor = brightenColor(textColor, by: 0.2)
        return cell
    }

    
    func genStandardWorkoutPreviewCell(_ exercise: Exercise, for indexPath: IndexPath) -> StandardWorkoutPreviewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: K.standardWorkoutPreviewCell, for: indexPath) as? StandardWorkoutPreviewCell else {
            print("Failed to dequeue WorkoutPreviewCell")
            return nil
        }
        
        cell.exerciseLabel.text = exercise.title
        cell.setsTextField.text = "\(exercise.currentSets)"
        
        cell.setsLabel.textColor = textColor
        cell.exerciseLabel.textColor = textColor
        cell.setsTextField.textColor = backgroundColor
        cell.setsTextField.backgroundColor = textColor
        
        return cell
    }
        
    func genSuperSetWorkoutPreviewCell(_ exercise: Exercise, for indexPath: IndexPath) -> SuperSetWorkoutPreviewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: K.superSetWorkoutPreviewCell, for: indexPath) as? SuperSetWorkoutPreviewCell else {
            print("Failed to dequeue WorkoutPreviewCell")
            return nil
        }
        cell.textLabel?.text = exercise.title
        cell.textLabel?.textColor = textColor
        return cell
    }
    
    func genPreviewHeadingCell(_ exercise: Exercise, for indexPath: IndexPath) -> PreviewHeadingCell? {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: K.previewHeadingCell, for: indexPath) as?
            PreviewHeadingCell else {
                print("Failed to dequeue WorkoutPreviewCell")
                return nil
            }
        
        cell.setLabel.textColor = backgroundColor
        cell.setsTextField.textColor = textColor
        cell.setsTextField.backgroundColor = backgroundColor
        cell.textLabel?.textColor = backgroundColor
        
        if !superSetEnabled{
            cell.setsTextField.isHidden = true
            cell.setLabel.isHidden = true
            cell.textLabel?.text = exercise.title
        }else{
            var identifier = returnString(exercise.supersetValue)
            cell.textLabel?.text = identifier
            cell.setsTextField.text = cell.returnTextLabel()
        }
        return cell
    }
    
    
    //MARK: - Configure Buttons
    
    func configureDoneWorkoutButtonCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let doneButtonCell = tableView.dequeueReusableCell(withIdentifier: K.buttonCell, for: indexPath) as? ButtonCell else {
            return UITableViewCell() // Fallback if cell dequeuing fails
        }
        
        doneButtonCell.button.setTitle("Done", for: .normal)

        
        doneButtonCell.button.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let color = isDarkMode ? UIColor.white : UIColor.blue

        
        doneButtonCell.button.setTitleColor(color, for: .normal)
        doneButtonCell.selectionStyle = .none
            
        return doneButtonCell
        
    }
    
    @objc func doneButtonPressed() {
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }
    

    func findHeadingCellIndexPath(for setName: String) -> IndexPath? {
        for section in 0..<tableView.numberOfSections {
            for row in 0..<tableView.numberOfRows(inSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                if let cell = tableView.cellForRow(at: indexPath) as? SuperSetHeadingCell,
                   cell.setName.text == setName {
                    return indexPath
                }
            }
        }
        return nil
    }
    
    func resetCounter() {
        defaultsValue.resetSetCounter()
        tableView.endEditing(true)
        
        if superSetEnabled{
            for letter in ["A","B","C","D"]{
                var matches: [Double] = []
                for exercise in exerciseList {
                    if returnString(exercise.supersetValue) == letter {
                        matches.append(Double(exercise.currentSets))
                    }
                }
                if !matches.isEmpty{
                    let average = matches.reduce(0, +) / Double(matches.count)
                    
                    defaultsValue.setCounter[letter] = Int(round(average))
                }
                
            }
        }

    }
    
    func returnIncrementAmount(_ exercise: Exercise) -> Double{
        if defaultsValue.incrementingWeightEnabled{
            if exercise.incrementWeights{
                return defaultsValue.incrementWeightAmount
            }
        }
        return 0
        
    }
    
    func pullColor(_ colorString: String) -> UIColor {
        let color = colorString.components(separatedBy: "-").map { Float($0)! }
        return UIColor(red: CGFloat(color[0]), green: CGFloat(color[1]), blue: CGFloat(color[2]), alpha: 1)
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
    
    func brightenColor(_ color: UIColor, by percentage: CGFloat = 0.2) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get the current RGB and alpha values of the color
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Increase each color component by the percentage, ensuring they stay within bounds
        return UIColor(
            red: min(red + (percentage * (1 - red)), 1.0),
            green: min(green + (percentage * (1 - green)), 1.0),
            blue: min(blue + (percentage * (1 - blue)), 1.0),
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
    
    func getColor(from backgroundColor: UIColor) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get the RGBA components of the background color
        backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate the sum of the RGB components
        let sumColors = red + green + blue
        
        // Set text color to black for lighter backgrounds and white for darker ones
        return sumColors >= 1.5 ? .black : .white
    }
    
}
