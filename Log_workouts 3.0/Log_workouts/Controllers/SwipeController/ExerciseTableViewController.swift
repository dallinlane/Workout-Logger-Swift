import UIKit
import RealmSwift

class ExerciseTableViewController: SwipeCellViewController, EditExerciseDelegate {
    
    func didUpdateExercises() {
        loadExercise()
        tableView.reloadData()
    }
    
    // MARK: - Properties
    var exercises: Results<Exercise>?

    var selectedBodyPart: BodyPart? {
        didSet {
            loadExercise()
        }
    }
    
    var isVisible: Bool {
        return (exercises?.count ?? 0) > 0
    }
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCells()
        self.navigationItem.title = selectedBodyPart?.name
        

    }
    // MARK: - Cell Registration
    private func registerCells() {
        tableView.register(UINib(nibName: "StandardCell", bundle: nil), forCellReuseIdentifier: K.standardCell)
        tableView.register(UINib(nibName: "SuperSetCell", bundle: nil), forCellReuseIdentifier: K.supersetCell)
        tableView.register(UINib(nibName: "ButtonCell", bundle: nil), forCellReuseIdentifier: K.buttonCell)
    }
    
    // MARK: - Data Loading
    private func loadExercise() {
        exercises = selectedBodyPart?.exercise.sorted(by: [
            SortDescriptor(keyPath: "sortedorder", ascending: true),
            SortDescriptor(keyPath: "title", ascending: true)
        ])
        
        toggleVisibility()
        tableView.reloadData()
    }
    
    private func updateNavigationBar() {
        if let lastExercise = exercises?.last {
            if let bodyPart = selectedBodyPart{
                super.defaultColor = bodyPart.backgroundColor
                title = bodyPart.name
            }
        }
    }

    // MARK: - TableView Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (exercises?.count ?? 0) + 1 // +1 for the load workout button
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isLastRow = indexPath.row == (exercises?.count ?? 0)
        
        if isLastRow {
            return configureLoadWorkoutButtonCell(for: indexPath)
        } else {
            return configureExerciseCell(for: indexPath)
        }
        
    }

    private func configureLoadWorkoutButtonCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let loadButtonCell = tableView.dequeueReusableCell(withIdentifier: K.buttonCell, for: indexPath) as? ButtonCell else {
            return UITableViewCell() // Fallback if cell dequeuing fails
        }
        loadButtonCell.button.setTitle("Load Exercise Preview", for: .normal)
        loadButtonCell.button.addTarget(self, action: #selector(loadButtonPressed), for: .touchUpInside)
        loadButtonCell.button.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .white : .blue, for: .normal)
        loadButtonCell.isHidden = !isVisible
        loadButtonCell.selectionStyle = .none

        return loadButtonCell
    }

    private func configureExerciseCell(for indexPath: IndexPath) -> UITableViewCell {
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        var backgroundColor = isDarkMode ? UIColor.blue : UIColor.white
        
        var textColor = oppositeColor(of: backgroundColor)
        
        let cellIdentifier = superSetEnabled ? K.supersetCell : K.standardCell
        super.cellIdentifier = cellIdentifier
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        


        guard let exercise = exercises?[indexPath.row] else {
            cell.textLabel?.text = "NO Exercise"
            return cell
        }

        configureCellAppearance(cell, with: exercise)
        
        let bodyPart = realm.objects(BodyPart.self).filter("name == %@", selectedBodyPart?.name).first
        if let exercises = bodyPart?.exercise{
            let exercise = exercises[indexPath.row]
           
            let color = pullColor(exercise.backgroundColor)
            
            backgroundColor = isDarkMode ?  darkenColor(oppositeColor(of: color), by: 0.4) : color
            
            textColor = getColor(from: backgroundColor)
            
            cell.backgroundColor = backgroundColor
            cell.textLabel?.textColor = textColor
        }
        


        if let supersetCell = cell as? SuperSetCell{
            
            textColor = oppositeColor(of: backgroundColor)
            
            textColor = isDarkMode ? textColor.withAlphaComponent(0.6) : textColor
                        
            supersetCell.superSetSegmentPicker.setTitleTextAttributes([.foregroundColor: backgroundColor ], for: .normal)
            
            
            supersetCell.superSetSegmentPicker.selectedSegmentTintColor = backgroundColor

            supersetCell.superSetSegmentPicker.setTitleTextAttributes([.foregroundColor: textColor], for: .selected) // Selected text color

            supersetCell.superSetSegmentPicker.backgroundColor = textColor
            
            return supersetCell

        }
        return cell
    }

    private func configureCellAppearance(_ cell: UITableViewCell, with exercise: Exercise) {
        if let superSetCell = cell as? SuperSetCell, superSetEnabled {
            var prevSetVal = exercise.supersetValue
            superSetCell.superSetSegmentPicker.selectedSegmentIndex = exercise.supersetValue
            superSetCell.segmentPressed = { [weak self] in
                guard let self = self else { return }
                let selectedSegmentValue = superSetCell.superSetSegmentPicker.selectedSegmentIndex
                try? self.realm.write {
                    exercise.supersetValue = selectedSegmentValue
                }
                var currentVal = exercise.supersetValue
                if (prevSetVal == 4 && currentVal != 4) ||
                   (prevSetVal != 4 && currentVal == 4) {
                    updateExerciseStatus(exercise)
                }
            }
        } else if let standardCell = cell as? StandardCell {
            DispatchQueue.main.async {
                standardCell.orderLabel.text = exercise.order != 0 ? String(exercise.order) : ""
            }
        }
        
        cell.textLabel?.text = exercise.title
    }
    

    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath.row == exercises?.count {
            return
        }
        guard let exercise = exercises?[indexPath.row], !superSetEnabled else { return }
        updateExerciseStatus(exercise)
        tableView.reloadData()
    }
    
    private func updateExerciseStatus(_ exercise: Exercise) {
        try? realm.write {
            if superSetEnabled {
                if exercise.supersetValue != 4{
                    // Increment and assign supersetorder if supersetenabled is true
                    defaultsValue.superSetOrder += 1
                    exercise.superSetOrder = defaultsValue.superSetOrder
                }else{
                    reorder(exercise.superSetOrder)
                    exercise.superSetOrder = 0
                    defaultsValue.superSetOrder -= 1
                }
            } else{
                exercise.done.toggle()
                if exercise.done {
                    // Increment and assign order if supersetenabled is false
                    defaultsValue.order += 1
                    exercise.order = defaultsValue.order
                    exercise.sortedorder = exercise.order
                }else {
                    reorder(exercise.order)
                    exercise.order = 0
                    defaultsValue.order -= 1
                    exercise.sortedorder = 9999
                }
            }
        }
    }

    // MARK: - Add & Load Buttons
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        super.generateAlert(alertTitle: "Add New Exercise", actionTitle: "Confirm", currentBodyPart: selectedBodyPart)
    }

    func toggleVisibility() {
        if let buttonCell = tableView.cellForRow(at: IndexPath(row: exercises?.count ?? 0, section: 0)) as? ButtonCell {
            buttonCell.isHidden = !isVisible // Hide button cell if no exercises are available
        }
    }

    @objc func loadButtonPressed() {
        if shouldGoToNextScreen(){
            performSegue(withIdentifier: K.toWorkoutPreviewScreen, sender: self)
        }
    }


    // MARK: - Update Model
    override func updateModel(at indexPath: IndexPath) {
        loadExercise()
        super.delete(cell: exercises?[indexPath.row])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? EditExerciseTableViewController{
            guard let exercises = selectedBodyPart?.exercise else {return}
            destinationVC.exercises = Array(exercises)
            destinationVC.delegate = self // Set the delegate here

        }

    }
    
    func shouldGoToNextScreen() -> Bool{
        for bodyPart in realm.objects(BodyPart.self){
            for exercise in bodyPart.exercise{
                if superSetEnabled{
                    if exercise.supersetValue != 4{
                        return true
                    }
                }else {
                    if exercise.order != 0{
                        return true
                    }
                }
            }
        }
        let alert = UIAlertController(title: "You Need to have selected at least one exercise to proceed to the next Screen", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        present(alert, animated: true, completion: nil)

        return false
    }
    
}
