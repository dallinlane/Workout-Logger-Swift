import UIKit
import SwipeCellKit
import RealmSwift

class GoalListTableViewController: SwipeCellViewController, EditExerciseDelegate {
    var goal: Goal?
    
    lazy var goalList: [Goal] = {
        return returnGoalList()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "StandardCell", bundle: nil), forCellReuseIdentifier: K.standardCell)
        
        var backgroundColor = ""
        if !goalList.isEmpty {
            backgroundColor = goalList[goalList.count - 1].backgroundColor
        } else {
            backgroundColor = genColor(1)
        }
        super.defaultColor = backgroundColor
        
        segueIdentifier = K.toTrainingScreen
        
        goalList.sort {
            if $0.date != $1.date {
                return $0.date < $1.date // First sort by sortedorder
            } else {
                return $0.name < $1.name // Then sort by title
            }
        }
        self.navigationItem.title = "Goals"
    }
    
    func didUpdateExercises() {
        returnGoalList()
        tableView.reloadData()
    }

    // MARK: - Table View Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goalList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellIdentifier = K.standardCell
        let cell = super.tableView(tableView, cellForRowAt: indexPath) as! StandardCell

        let currentGoal = goalList[indexPath.row]

        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let color =  pullColor(currentGoal.backgroundColor)
        let backgroundColor = isDarkMode ?  darkenColor(oppositeColor(of: color), by: 0.4) : color
        
        cell.textLabel?.text = currentGoal.name
        cell.backgroundColor = backgroundColor
        cell.textLabel?.textColor = getColor(from: backgroundColor)

        return cell
    }

    // MARK: - Actions

    @IBAction func createNewGoal(_ sender: UIBarButtonItem) {
        generateAlert()
    }

    // MARK: - Alert Generation

    func generateAlert() {
        var nameTextField = UITextField()
        var repsTextField = UITextField()
        
        let alert = UIAlertController(title: "New Goal", message: "", preferredStyle: .alert)
        alert.addTextField { alertTextField in
            nameTextField = alertTextField
            alertTextField.placeholder = "Enter Goal name"
        }
        
        alert.addTextField { alertTextField in
            repsTextField = alertTextField
            alertTextField.placeholder = "Enter Goal Reps"
        }

        let action = UIAlertAction(title: "Confirm", style: .default) { _ in
            self.handleAlertAction(with: nameTextField.text, repsText: repsTextField.text)
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Handle Alert Action

    private func handleAlertAction(with text: String?, repsText: String?) {
        let goals = realm.objects(Goal.self) // Make sure to handle this correctly
        let goal = Goal()
        
        guard let text = text, !text.isEmpty else { return }
        goal.name = text
        goal.backgroundColor = self.genColor(2)
        goal.textColor = self.textColor()
        
        if let repsText = repsText, let reps = Int(repsText) {
            goal.goalReps = reps
        } else {
            goal.goalReps = 10 // Default value if input is invalid
        }
        
        try? realm.write {
            realm.add(goal)
        }
        
        self.goalList = returnGoalList()
        tableView.reloadData()
    }

    // MARK: - Goal List Management

    private func returnGoalList() -> [Goal] {
        let goalArray = realm.objects(Goal.self)
        let sortedGoals = goalArray.sorted(byKeyPath: "name", ascending: true)
        return Array(sortedGoals)
    }

    override func updateModel(at indexPath: IndexPath) {
        let goalToDelete = goalList[indexPath.row]

        do {
            try realm.write {
                realm.delete(goalToDelete)
            }
        } catch {
            print("Error deleting goal: \(error.localizedDescription)")
        }
        
        goalList = returnGoalList()
    }

    // MARK: - Table View Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        goal = goalList[indexPath.row]
        performSegue(withIdentifier: K.toGoalScreen, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.toGoalScreen {
            defaultsValue.templateOn = true
            
            // Log current state before accessing data
            print("Preparing for segue. templateName: \(templateName)")
            
            if let destinationVC = segue.destination as? GoalTableViewController {
                destinationVC.goal = goal
            }
        } else {
            if let destinationVC = segue.destination as? EditGoalListTableViewController {
                destinationVC.delegate = self
            }
        }
    }
}
