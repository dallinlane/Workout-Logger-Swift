import UIKit
import RealmSwift


class SwitchCell: UITableViewCell {
    
    var exerciseName: String = ""

    @IBOutlet weak var switchName: UISwitch!
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var textField: UITextField!
    var realm: Realm!
    var updatedText = ""
    
    var defaultsValue = Defaults()
    var textArray: [String] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        
        textField.keyboardType = .decimalPad

        
        switchName.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        label.numberOfLines = 1 // Only one line
        label.lineBreakMode = .byTruncatingTail // Truncate text if it's too long

        do {
            realm = try Realm()
        } catch {
            fatalError("Unable to initialize Realm: \(error)")
        }
        setTextFieldWidth(textField: textField, width: 80) // Set width to 10 points

        setupStackView()


        
        textField.addTarget(self, action: #selector(textFieldEditingDidBegin(_:)), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)
        updatedText = String(defaultsValue.incrementWeightAmount)
    }
    
    private func setupStackView() {
            // Create the horizontal stack view
            let stackView = UIStackView(arrangedSubviews: [switchName, label, textField])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.spacing = 8 // Set spacing to zero to eliminate gaps
            stackView.translatesAutoresizingMaskIntoConstraints = false

            // Add the stack view to the content view
            contentView.addSubview(stackView)

            // Set constraints for the stack view
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

                // Optionally, you can keep the width for the textField
                textField.widthAnchor.constraint(equalToConstant: 80) // Adjust as needed
            ])
        }


    @IBAction func switchToggled(_ sender: UISwitch) {
        guard let text = label.text else {return}
        
        if text.contains("Increment"){
            textField.isEnabled = sender.isOn
        }
        
        if text.contains("Mode"){
            toggleAppearance()
        }
        
        label.text = textArray[sender.isOn ? 1: 0 ]
        
        textField.text = sender.isOn ? updatedText : nil
        textField.placeholder = sender.isOn ? nil : updatedText
        textField.isEnabled = sender.isOn ? true : false
        
        if let text = textField.placeholder{
            textField.attributedPlaceholder = NSAttributedString(
                string: text,
                attributes: [NSAttributedString.Key.foregroundColor: darkenColor(UIColor(red: 1.0, green: 1.0, blue: 0.6, alpha: 1.0), by: 0.2) ] // Replace with desired color
            )
        }
    }
    
    
    func toggleAppearance() {
        // Check the current appearance mode
        let currentStyle = UserDefaults.standard.bool(forKey: "isDarkMode")
        let newStyle = !currentStyle
        
        // Save the new style preference
        UserDefaults.standard.set(newStyle, forKey: "isDarkMode")
        
        // Update the appearance for all windows in the current scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = newStyle ? .dark : .light
            }
        }
        
        NotificationCenter.default.post(name: .appearanceDidChange, object: nil)

    }
    
    
    func update(){
        textField.resignFirstResponder()
        guard let text = label.text else {return}
        
        if text.contains("Auto Deload"){
            defaultsValue.deloadEnabled = switchName.isOn

        }
        else if text.contains("SuperSet"){
            defaultsValue.superSetEnabled = switchName.isOn
            
        }else if text.contains("Increment"){
            textField.isEnabled = true
            defaultsValue.incrementingWeightEnabled = switchName.isOn
            guard let amount = Double(updatedText) else {return}
        
            defaultsValue.incrementWeightAmount = amount
        }
        
    }
    
    
    func updateExercice(_ exercise: Exercise){
        
        guard let text = label.text else{return}
        
        if text.contains("Increment"){
            try? realm.write(){
                exercise.incrementWeights = switchName.isOn
            }
        }else{
            try? realm?.write{
                exercise.weights = switchName.isOn
            }
            
        }
    }
    
    
    @objc private func textFieldEditingDidBegin(_ textField: UITextField) {
        // Store the current text temporarily and clear the field for editing
        
        textField.keyboardType = switchName.isHidden ? .alphabet : .decimalPad

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
        if let textfieldText = textField.text {
            let noWhitespaceString = textfieldText.replacingOccurrences(of: " ", with: "")
            
            if !switchName.isHidden {
                guard let textFieldAsNumber = Double(noWhitespaceString)else {textField.text = textField.placeholder
                    updatedText = textfieldText

                    return
                }
            }
         
            
            textField.text = textfieldText
            updatedText = textfieldText
        }
        
        // Optionally, reset the placeholder color to default if needed
        textField.attributedPlaceholder = nil // Reset or set to another desired color
    }
    
    private func setTextFieldWidth(textField: UITextField, width: CGFloat) {
        // Set the width constraint
        let widthConstraint = textField.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.isActive = true
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

}
