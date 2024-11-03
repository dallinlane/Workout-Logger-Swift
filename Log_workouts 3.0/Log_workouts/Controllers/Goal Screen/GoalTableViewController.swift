import UIKit
import SwipeCellKit
import RealmSwift

class GoalTableViewController: UITableViewController {
    var goal: Goal?
    var chartGoals: [GoalTotalWeight] = []
    
    var realm: Realm!
    var numberOfCells = 0
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
        
        self.title = goal?.name
        
        tableView.register(UINib(nibName: "StandardCell", bundle: nil), forCellReuseIdentifier: K.standardCell)
        tableView.register(UINib(nibName: "GoalUITableViewCell", bundle: nil), forCellReuseIdentifier: K.goalUITableViewCell)
        tableView.register(UINib(nibName: "ButtonCell", bundle: nil), forCellReuseIdentifier: K.buttonCell)

        do {
            realm = try Realm()
        } catch {
            fatalError("Unable to initialize Realm: \(error)")
        }
        
        for g in realm.objects(GoalTotalWeight.self) {
            chartGoals.append(g)
        }
        
        self.navigationItem.title = "Update Goal Progress"
    }

    // MARK: - Table View Data Source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        shouldContinue()
        return numberOfCells
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let currentGoal = goal else { return UITableViewCell() }
        
        let backgroundColor = pullColor(currentGoal.backgroundColor)
        let textColor = oppositeColor(of: backgroundColor)
        tableView.separatorStyle = .none
        
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            
            if numberOfCells == 3 {
                let totalRep = (goal?.goalReps ?? 0) - (goal?.repsDone ?? 0)
                cell.textLabel?.text = "\(totalRep) reps remaining"
            } else {
                cell.textLabel?.text = "Congratulations you finished your goal for Today!"
            }
            cell.selectionStyle = .none
            cell.backgroundColor = backgroundColor
            cell.textLabel?.textColor = textColor
            return cell
            
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: K.goalUITableViewCell, for: indexPath) as? GoalUITableViewCell else { return UITableViewCell() }
            
            cell.backgroundColor = textColor
            cell.weightTextField.textColor = textColor
            cell.weightTextField.backgroundColor = backgroundColor
            cell.repsTextField.textColor = textColor
            cell.repsTextField.backgroundColor = backgroundColor
            cell.repsLabel.textColor = backgroundColor
            cell.weightLabel.textColor = backgroundColor

            cell.goal = currentGoal
            cell.repsTextField.text = String(currentGoal.currentReps)
            if currentGoal.weightEnabled {
                cell.weightTextField.text = String(currentGoal.currentWeight)
            } else {
                cell.weightLabel.isHidden = true
                cell.weightTextField.isHidden = true
            }
            
            cell.selectionStyle = .none
            return cell
            
        default:
            guard let confirmButton = tableView.dequeueReusableCell(withIdentifier: K.buttonCell, for: indexPath) as? ButtonCell else {
                return UITableViewCell() // Fallback if cell dequeuing fails
            }
            confirmButton.button.setTitle("Confirm", for: .normal)
            confirmButton.button.addTarget(self, action: #selector(confirmButtonPressed(_:)), for: .touchUpInside)
            confirmButton.button.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .white : .blue, for: .normal)
            confirmButton.selectionStyle = .none

            return confirmButton
        }
    }
    
    // MARK: - Actions

    @objc func confirmButtonPressed(_ sender: UIButton) {
        // Attempt to perform a Realm write transaction
        
        let indexPath = IndexPath(row: 1, section: 0)
        guard let cell = tableView.cellForRow(at: indexPath) as? GoalUITableViewCell else {
            return
        }
        cell.repsTextFieldChanged(cell.repsTextField)

        if !cell.weightTextField.isHidden {
            cell.weightTextFieldChanged(cell.weightTextField)
        }
        
        if let currentGoal = goal {
            currentGoal.repsList.append(currentGoal.currentReps)
            currentGoal.weightList.append(currentGoal.currentWeight)
            do {
                try realm.write {
                    // Update the repsLeft property
                    goal?.repsDone += currentGoal.currentReps
                    goal?.totalWeight += currentGoal.currentWeight * Double(currentGoal.currentReps)
                   
                    let averageWeight = Double(currentGoal.weightList.reduce(0, +)) / Double(currentGoal.weightList.count)
                    var averageSet = 0.0
                    for index in 0..<currentGoal.weightList.count {
                        averageSet += (currentGoal.weightList[index] * Double(currentGoal.repsList[index]))
                    }
                    averageSet /= Double(currentGoal.weightList.count)

                    goal?.averageWeightPerRep = averageWeight
                    goal?.averageWeightPerSet = averageSet
                }
                updateChartGoals()
            } catch {
                print("Error updating repsLeft: \(error.localizedDescription)")
            }
        }

        shouldContinue()
        tableView.endEditing(true)
        tableView.reloadData()
    }
    
    // MARK: - Helper Functions

    func shouldContinue() {
        guard let repsDone = goal?.repsDone else { return }
        guard let goalReps = goal?.goalReps else { return }
        guard let goalDate = goal?.date else { return }
        numberOfCells = 3

        let calendar = Calendar.current
        if repsDone >= goalReps {
            if calendar.isDateInToday(goalDate) {
                numberOfCells = 1
            } else {
                try? realm.write {
                    goal?.repsDone = 0
                    goal?.date = Date()
                }
            }
        } else if !calendar.isDateInToday(goalDate) {
            try? realm.write {
                goal?.repsDone = 0
                goal?.date = Date()
            }
        }
    }
    
    func updateChartGoals() {
        var updated = false
        guard let g = goal else { return }
        for chartGoal in chartGoals {
            if chartGoal.title == g.name {
                let calendar = Calendar.current
                if calendar.isDateInToday(chartGoal.date) {
                    try? realm.write {
                        chartGoal.totalReps += g.currentReps
                        chartGoal.totalWeight = g.totalWeight
                        chartGoal.averageWeightPerRep = g.averageWeightPerRep
                        chartGoal.averageWeightPerSet = g.averageWeightPerSet
                    }
                    updated = true
                }
            }
        }
        
        if !updated {
            let goalTotalWeight = GoalTotalWeight()
            goalTotalWeight.date = g.date
            goalTotalWeight.title = g.name
            goalTotalWeight.totalWeight = g.totalWeight
            goalTotalWeight.totalReps += g.currentReps
            goalTotalWeight.averageWeightPerRep = g.averageWeightPerRep
            goalTotalWeight.averageWeightPerSet = g.averageWeightPerSet
            
            try? realm.write {
                realm.add(goalTotalWeight)
            }
            chartGoals.append(goalTotalWeight)
        }
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
    
    // MARK: - Navigation

    @objc func backButtonTapped() {
        // Handle back button tap action
        navigationController?.popViewController(animated: true)
    }
}
