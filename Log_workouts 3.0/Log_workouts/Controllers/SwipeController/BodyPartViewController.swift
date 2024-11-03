import UIKit
import RealmSwift

class BodyPartViewController: SwipeCellViewController, EditExerciseDelegate {
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Muscle Groups"

        loadMuscleGroups()
    }
    
    func didUpdateExercises() {
        loadMuscleGroups()
        tableView.reloadData()
    }

    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bodyPartArray?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        if let muscle = bodyPartArray?[indexPath.row] {
            cell.textLabel?.text = muscle.name
        }
        
        let unsortedBodyPart = realm.objects(BodyPart.self)
        
        
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let bodyPart = unsortedBodyPart[indexPath.row]
        let color = pullColor(bodyPart.backgroundColor)

        let backgroundColor = isDarkMode ?  darkenColor(oppositeColor(of: color), by: 0.4) : color
        
        cell.backgroundColor = backgroundColor
        
        cell.textLabel?.textColor = getColor(from: backgroundColor)

        
        return cell
    }

    // MARK: - Actions
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        super.generateAlert(alertTitle: "Add New Muscle Group", actionTitle: "Confirm", currentBodyPart: nil)
    }

    // MARK: - Data Loading
    func loadMuscleGroups() {
        guard let bodyPartArray = bodyPartArray, bodyPartArray.count > 0 else { return }
        
        let lastBodyPart = bodyPartArray[bodyPartArray.count - 1]
        super.defaultColor = lastBodyPart.backgroundColor

        tableView.reloadData()
    }

    // MARK: - Delete Data from Swipe
    override func updateModel(at indexPath: IndexPath) {
        super.delete(cell: bodyPartArray?[indexPath.row])
    }

    // MARK: - Table View Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        performSegue(withIdentifier: K.toExerciseSelectionScreen, sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? ExerciseTableViewController,
           let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.selectedBodyPart = bodyPartArray?[indexPath.row]
        }
        
        if let destinationVC = segue.destination as? EditExerciseTableViewController{
            destinationVC.bodyParts = Array(realm.objects(BodyPart.self))
            destinationVC.bodyPartController = true
            destinationVC.delegate = self
        }
    }
}
