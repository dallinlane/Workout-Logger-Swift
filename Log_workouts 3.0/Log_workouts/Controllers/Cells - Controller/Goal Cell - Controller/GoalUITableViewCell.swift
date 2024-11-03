import UIKit
import RealmSwift

class GoalUITableViewCell: UITableViewCell {
    @IBOutlet weak var repsLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var weightTextField: UITextField!
    @IBOutlet weak var repsTextField: UITextField!
    
    
    var realm: Realm!
    var goal = Goal()
    
    private var stackView: UIStackView!
    private var repsStackView: UIStackView!
    private var weightStackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        do {
            realm = try Realm()
        } catch {
            fatalError("Unable to initialize Realm: \(error)")
        }
        repsLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
        weightLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        setTextFieldWidth(textField: repsTextField, width: 90)
        setTextFieldWidth(textField: weightTextField, width: 90)

        
        repsTextField.keyboardType = .numberPad // For reps input
        weightTextField.keyboardType = .decimalPad // For weight input
        
        repsTextField.addTarget(self, action: #selector(textFieldEditingDidBegin(_:)), for: .editingDidBegin)
        repsTextField.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)
        weightTextField.addTarget(self, action: #selector(textFieldEditingDidBegin(_:)), for: .editingDidBegin)
        weightTextField.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)
        
        setupStackView() // Call the setup method

    }
    
    private func setupStackView() {
        // Create stack views for reps and weights
        repsStackView = UIStackView(arrangedSubviews: [repsLabel, repsTextField])
        weightStackView = UIStackView(arrangedSubviews: [weightLabel, weightTextField])
        
        // Configure stack views
        repsStackView.axis = .horizontal
        weightStackView.axis = .horizontal
        
        // Create main stack view
        stackView = UIStackView(arrangedSubviews: [repsStackView, weightStackView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 16 // Adjust spacing as needed
        
        // Set distribution to fill equally
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Add the main stack view to the content view
        contentView.addSubview(stackView)

        // Set constraints for the stack view
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    
    @IBAction func repsTextFieldChanged(_ sender: UITextField) {
        repsTextField.resignFirstResponder()
        
        if let reps = sender.text{
            try? self.realm.write{
                self.goal.currentReps = Int(reps) ?? 10
            }
        }
    }
    
    @IBAction func weightTextFieldChanged(_ sender: UITextField) {
        weightTextField.resignFirstResponder()

        if let weight = sender.text{
            guard let weightDouble = Double(weight) else { return}
            
            try? self.realm.write{
                self.goal.currentWeight = weightDouble
            }
        }
    }
    
    @objc private func textFieldEditingDidBegin(_ textField: UITextField) {
        // Store the current text temporarily and clear the field for editing
        if let currentText = textField.text, !currentText.isEmpty {
            textField.placeholder = currentText
            textField.text = ""
        }
        
        textField.attributedPlaceholder = NSAttributedString(
            string: textField.placeholder ?? "" ,
             attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray] // Change to your desired color
         )
    }

    @objc private func textFieldEditingDidEnd(_ textField: UITextField) {
        let metric = (textField == repsTextField) ? "" : " lb"
        if let textfieldText = textField.text {
            let noWhitespaceString = textfieldText.replacingOccurrences(of: " ", with: "")
            
            if metric == ""{
                guard let textInt = Int(textfieldText) else{
                    textField.text = textField.placeholder!
                    
                    return
                }
                
                textField.text = textfieldText + metric
            } else{
                textField.text = Double(noWhitespaceString) == nil ? textField.placeholder : noWhitespaceString + metric
            }
            
         }
    }
    
    private func setTextFieldWidth(textField: UITextField, width: CGFloat) {
        // Set the width constraint
        let widthConstraint = textField.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.isActive = true
    }
    
    
    
}
