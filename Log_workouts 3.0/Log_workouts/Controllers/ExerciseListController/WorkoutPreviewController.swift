import UIKit
import RealmSwift

class WorkoutPreviewController: ExerciseList {
    var defaultColor = "1.0-1.0-1.0"

    override func viewDidLoad() {
        super.viewDidLoad()
        segueIdentifier = K.toTrainingScreen

        exerciseList.sort {
            if superSetEnabled{
                if $0.supersetValue != $1.supersetValue {
                    return $0.supersetValue < $1.supersetValue // First sort by sortedorder
                } else {
                    return $0.superSetOrder < $1.superSetOrder // Then sort by title
                }
            }else{
                if $0.sortedorder != $1.sortedorder {
                    return $0.sortedorder < $1.sortedorder // First sort by sortedorder
                } else {
                    return $0.title < $1.title // Then sort by title
                }
            }

         }
        
        self.navigationItem.title = "Preview"
        navigationController?.navigationBar.backgroundColor = .blue.withAlphaComponent(0.5)


    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exerciseList.count + 1 + headingCellsAmount
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isLastRow = indexPath.row == exerciseList.count + headingCellsAmount

        if isLastRow {
            return super.configureDoneWorkoutButtonCell(for: indexPath)
        } else {
            if superSetEnabled{
                var order = indexPath.row - extraCells
                if indexPath.row == 0{
                    extraCells += 1
                    listOfSupersetTypes.append(returnString(exerciseList[indexPath.row].supersetValue))
                    return super.configureExerciseCell(for: indexPath, exercise: exerciseList[indexPath.row], identifier: K.previewHeadingCell)
                }
                if order == 0{
                    return super.configureExerciseCell(for: indexPath, exercise: exerciseList[order], identifier: K.superSetWorkoutPreviewCell)
                } else if exerciseList[order - 1].supersetValue != exerciseList[order].supersetValue && order < exerciseList.count{
                    if listOfSupersetTypes.contains(returnString(exerciseList[order].supersetValue)){
                        return super.configureExerciseCell(for: indexPath, exercise: exerciseList[order], identifier: K.superSetWorkoutPreviewCell)
                    }
                    else{
                        extraCells += 1
                        listOfSupersetTypes.append(returnString(exerciseList[order].supersetValue))
                        return super.configureExerciseCell(for: indexPath, exercise: exerciseList[order], identifier: K.previewHeadingCell)
                    }
                }else{
                    return super.configureExerciseCell(for: indexPath, exercise: exerciseList[order], identifier: K.superSetWorkoutPreviewCell)
                }

            }else{
                return super.configureExerciseCell(for: indexPath, exercise: exerciseList[indexPath.row], identifier: K.standardWorkoutPreviewCell)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.resetCounter()
        
        for exercise in exerciseList{
            try? realm.write{
                exercise.IncrementAdded = false
            }
        }
    }
    
    @IBAction func createTemplate(_ sender: UIBarButtonItem) {
        
        generateAlert()
        
    }
    
    
    func generateAlert() {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Template", message: "", preferredStyle: .alert)
        alert.addTextField { alertTextField in
            textField = alertTextField
            alertTextField.placeholder = "Enter template name"
        }

        let action = UIAlertAction(title: "Confirm", style: .default) { _ in
            self.handleAlertAction(with: textField.text)
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    private func handleAlertAction(with text: String?) {
        guard let text = text, !text.isEmpty else { return }
        
        let templates = realm.objects(Template.self) // Make sure to handle this correctly
        let template = Template()
        template.name = text
        template.superSetEnabled = superSetEnabled
        
        var backgroundColor = ""
        
        if !templates.isEmpty{
            backgroundColor = templates[templates.count - 1].backgroundColor
        }else{
            backgroundColor = genColor(1)
        }
        
        defaultColor = backgroundColor

        
        template.backgroundColor = self.genColor(2)
        template.textColor = self.textColor()
        
        // Initialize dictionary to store exercises
        var dictionary: [String: [TemplateExercise]] = [:]

        for exercise in exerciseList {
            // Create a new TemplateExercise instance
            let tempExercise = TemplateExercise(
                 name: exercise.title,
                 order: exercise.order,
                 superSetOrder: exercise.superSetOrder,
                 sortOrder: exercise.sortedorder,
                 supersetValue: exercise.supersetValue,
                 sets: exercise.currentSets,
                 reps: exercise.currentReps
             )

            // Initialize the array for the specific template name if needed
            dictionary[text, default: []].append(tempExercise)
        }
        var existingTemplates = defaultsValue.setTemplate
        for (key, exercises) in dictionary {
            existingTemplates[key, default: []].append(contentsOf: exercises)
        }
        
        defaultsValue.setTemplate = existingTemplates

        try? realm.write {
            realm.add(template)
        }

    }
    
    func genColor(_ index: Int) -> String {
        if index == 0 {
            return defaultColor
        } else {
            var color = defaultColor.components(separatedBy: "-").map { Double($0)! }
            if color[index] > 0.3 {
                color[index] -= 0.2
            } else {
                color = (0...2).map { _ in Double.random(in: 0...1) }
                color[index] = 1.0
            }
            defaultColor = color.map { String($0) }.joined(separator: "-")
            return defaultColor
        }
    }

    
    func textColor() -> String {
        let backgroundColor = defaultColor.components(separatedBy: "-").map { Float($0)! }
        let sumColors = backgroundColor.reduce(0, +)
        let color: [Float] = sumColors >= 1.5 ? [0.0, 0.0, 0.0] : [1.0, 1.0, 1.0]
        return color.map { String($0) }.joined(separator: "-")
    }
}
