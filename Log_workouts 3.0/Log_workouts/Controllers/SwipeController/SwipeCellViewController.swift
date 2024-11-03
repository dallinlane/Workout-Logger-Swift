import UIKit
import SwipeCellKit
import RealmSwift

class SwipeCellViewController: UITableViewController, SwipeTableViewCellDelegate {
    
    // MARK: - Properties
    var defaultColor: String = "1.0-1.0-1.0"
    var realm: Realm!
    var cellIdentifier = "cell"
    var defaultsValue = Defaults()
    var bodyPartArray: Results<BodyPart>?
    var superSetEnabled = false
    var segueIdentifier = ""
    var templateName = ""
    lazy var templateList: [String] = Array(defaultsValue.setTemplate.keys).sorted()




    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        superSetEnabled = defaultsValue.superSetEnabled
        initializeRealm()
        loadBodyParts()
        tableView.rowHeight = 80.0
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

    // MARK: - Load Body Parts
    private func loadBodyParts() {
        bodyPartArray = realm.objects(BodyPart.self).sorted(byKeyPath: "name", ascending: true)
    }
    
    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueCell(for: indexPath)
        cell.delegate = self
        tableView.separatorStyle = .none
        cell.selectionStyle = .none

        return cell
    }
    
    

    private func dequeueCell(for indexPath: IndexPath) -> SwipeTableViewCell {
        switch cellIdentifier {
        case "cell":
            return tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SwipeTableViewCell
        case K.supersetCell:
            return tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SuperSetCell
        default:
            return tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! StandardCell
        }
    }
    
    
    // MARK: - Swipe Actions
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

        let delegateAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            self.updateModel(at: indexPath)
        }
        delegateAction.image = UIImage(named: "delete-icon")
        return [delegateAction]
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        var options = SwipeTableOptions()
        options.expansionStyle = .destructive
        return options
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

       
        if segueIdentifier == K.toTrainingScreen{
      
//            performSegue(withIdentifier: segueIdentifier, sender: self)
        }
    }
    
    // MARK: - Data Handling
    func delete(cell: Object?) {
        guard let cell = cell else { return }

        var orders = [Int]()
        if let bodyPart = cell as? BodyPart {
            orders = bodyPart.exercise.map { $0.order }
        } else if let exercise = cell as? Exercise {
            orders.append(exercise.order)
        }

        try? realm.write {
            realm.delete(cell)
            for order in orders where order > 0 {
                defaultsValue.order -= 1
                reorder(order)
            }
        }
    }
    
    func reorder(_ order: Int) {
        guard let bodyParts = bodyPartArray else { return }
        for bodyPart in bodyParts {
            let bodyPartExercises = bodyPart.exercise
            bodyPartExercises.filter { $0.order > order }.forEach { exercise in
                if superSetEnabled{
                    exercise.superSetOrder -= 1
                }else{
                    exercise.order -= 1
                    exercise.sortedorder = exercise.order
                }
            }
        }
    }

    func updateModel(at indexPath: IndexPath) {
        // Implement model update logic
    }

    // MARK: - Color Generation
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

    // MARK: - Alert Generation
    func generateAlert(alertTitle: String, actionTitle: String, currentBodyPart: BodyPart?) {
        var textField = UITextField()
        let alert = UIAlertController(title: alertTitle, message: "", preferredStyle: .alert)
        alert.addTextField { alertTextField in
            textField = alertTextField
            alertTextField.placeholder = "Enter name"
        }

        let action = UIAlertAction(title: actionTitle, style: .default) { _ in
            self.handleAlertAction(with: textField.text, currentBodyPart: currentBodyPart)
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    private func handleAlertAction(with text: String?, currentBodyPart: BodyPart?) {
        guard let text = text, !text.isEmpty else { return }

        if let currentBodyPart = currentBodyPart {
            let exercise = Exercise()
            exercise.title = text
            exercise.backgroundColor = self.genColor(2)
            exercise.textColor = self.textColor()
            save { currentBodyPart.exercise.append(exercise) }
        } else {
            let bodyPart = BodyPart()
            bodyPart.name = text
            bodyPart.backgroundColor = self.genColor(1)
            bodyPart.textColor = self.textColor()
            save { self.realm.add(bodyPart) }
        }
        tableView.reloadData()
    }

    // MARK: - Realm Save
    func save(_ writeBlock: @escaping () -> Void) {
        try? realm.write {
            writeBlock()
        }
    }

    // MARK: - Color Utilities
    func pullColor(_ colorString: String) -> UIColor {
        let color = colorString.components(separatedBy: "-").map { Float($0)! }
        return UIColor(red: CGFloat(color[0]), green: CGFloat(color[1]), blue: CGFloat(color[2]), alpha: 1)
    }

    func textColor() -> String {
        let backgroundColor = defaultColor.components(separatedBy: "-").map { Float($0)! }
        let sumColors = backgroundColor.reduce(0, +)
        let color: [Float] = sumColors >= 1.5 ? [0.0, 0.0, 0.0] : [1.0, 1.0, 1.0]
        return color.map { String($0) }.joined(separator: "-")
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
    
    @objc func backButtonTapped() {
        // Handle back button tap action
        navigationController?.popViewController(animated: true)
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
