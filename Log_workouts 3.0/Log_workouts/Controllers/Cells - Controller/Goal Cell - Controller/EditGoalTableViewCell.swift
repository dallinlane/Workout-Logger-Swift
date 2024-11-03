import UIKit
import RealmSwift

class EditGoalTableViewCell: UITableViewCell {
    @IBOutlet weak var goalLabel: UIButton!
    @IBOutlet weak var repsLabel: UILabel!
    @IBOutlet weak var goalRepsTextField: UITextField!
    @IBOutlet weak var weightenabledLabel: UILabel!
    @IBOutlet weak var weightEnabledSwitch: UISwitch!
    
    private var stackView: UIStackView!

    
    var realm: Realm!
    var goal: Goal?
    var onButtonTap: (() -> Void)?


    override func awakeFromNib() {
        super.awakeFromNib()
        do {
            realm = try Realm()
        } catch {
            fatalError("Unable to initialize Realm: \(error)")
        }
        
        setTextFieldWidth(textField: goalRepsTextField, width: 60)

        setupStackView()
        
        goalRepsTextField.addTarget(self, action: #selector(textFieldEditingDidBegin(_:)), for: .editingDidBegin)
        goalRepsTextField.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)
        
    }
    
    private func setupStackView() {
           // Create and configure the stack view
           stackView = UIStackView(arrangedSubviews: [goalLabel, repsLabel, goalRepsTextField, weightenabledLabel, weightEnabledSwitch])
           stackView.axis = .horizontal
           stackView.alignment = .center
           stackView.spacing = 8 // Adjust spacing as needed
           stackView.translatesAutoresizingMaskIntoConstraints = false
           
           // Add the stack view to the content view
           contentView.addSubview(stackView)

           // Set constraints for the stack view
           NSLayoutConstraint.activate([
               stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
               stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
               stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
               goalLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.25),
               goalLabel.widthAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 1.5),


           ])
        
        weightenabledLabel.widthAnchor.constraint(equalToConstant: 95).isActive = true // Adjust the value as needed

       }
    
    func updateGoal() {
        if let goal = goal {
            // Use optional binding to safely unwrap the text field value
            try? realm.write{
                if goalRepsTextField.text != ""{
                    goal.goalReps = Int(goalRepsTextField.text ?? "100") ?? 100
                }
                goal.weightEnabled = weightEnabledSwitch.isOn
            }
        }
    }
    
    private func setTextFieldWidth(textField: UITextField, width: CGFloat) {
        // Set the width constraint
        let widthConstraint = textField.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.isActive = true
    }
    
    @IBAction func switchToggled(_ sender: UISwitch) {
        weightenabledLabel.text = sender.isOn ? "Weights On" : "Weights Off"
    }
    
    
    @objc private func textFieldEditingDidBegin(_ textField: UITextField) {
        // Store the current text temporarily and clear the field for editing
        if let currentText = textField.text, !currentText.isEmpty {
            textField.placeholder = currentText
            textField.text = ""
        }
    }
    
    @objc private func textFieldEditingDidEnd(_ textField: UITextField) {
        if let textfieldText = textField.text {
            
            let noWhitespaceString = textfieldText.replacingOccurrences(of: " ", with: "")

            if let value = Double(noWhitespaceString) {
                // If it's a valid Double, update the text field with the integer representation
                guard let setsAmount = Int(textfieldText) else{ textField.text = textField.placeholder
                    return }
                textField.text = String(setsAmount)// or use String(format: "%.1f", value) for one decimal
            } else {
                // If no input was provided, set the text field to the placeholder
                textField.text = textField.placeholder
            }

        }
    }
    
    
    @IBAction func changeTitle(_ sender: UIButton) {
        onButtonTap?() // Trigger the alert in the view controller
    }
    
    


 
}
