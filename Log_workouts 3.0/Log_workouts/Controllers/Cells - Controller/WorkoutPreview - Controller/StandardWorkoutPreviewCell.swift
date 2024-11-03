import UIKit

class StandardWorkoutPreviewCell: PreviewTemplateCell {

    @IBOutlet weak var exerciseLabel: UILabel!
    
    @IBOutlet weak var setsLabel: UILabel!
    @IBOutlet weak var setsTextField: UITextField!
    
    override func awakeFromNib() {
            super.awakeFromNib()

            // Disable autoresizing masks to use Auto Layout
            exerciseLabel.translatesAutoresizingMaskIntoConstraints = false
            setsLabel.translatesAutoresizingMaskIntoConstraints = false
            setsTextField.translatesAutoresizingMaskIntoConstraints = false

            // Configure setsLabel
            setsLabel.numberOfLines = 1 // Only one line
            setsLabel.lineBreakMode = .byTruncatingTail // Truncate text if it's too long

            // Create stack view for setsLabel and setsTextField with no spacing
            let setsStackView = UIStackView(arrangedSubviews: [setsLabel, setsTextField])
            setsStackView.axis = .horizontal
            setsStackView.alignment = .center
            setsStackView.spacing = 10
            setsStackView.translatesAutoresizingMaskIntoConstraints = false

            // Add exerciseLabel and setsStackView to content view
            contentView.addSubview(exerciseLabel)
            contentView.addSubview(setsStackView)

            // Layout Constraints
            NSLayoutConstraint.activate([
                // Align exerciseLabel to the leading edge with padding and set it to 50% width
                exerciseLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                exerciseLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                exerciseLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.4),

                // Position setsStackView immediately to the right of exerciseLabel
                setsStackView.leadingAnchor.constraint(equalTo: exerciseLabel.trailingAnchor), // No padding here
                setsStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

                // Constrain the trailing edge of setsStackView to the content view (if necessary)
                setsStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

                // Set a fixed width for setsTextField for consistency
                setsTextField.widthAnchor.constraint(equalToConstant: 60)
            ])

            // Configure setsTextField properties
            setsTextField.keyboardType = .numberPad
            setsTextField.addTarget(self, action: #selector(textFieldEditingDidBegin(_:)), for: .editingDidBegin)
            setsTextField.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)
        }
    
    @IBAction func setSetsAmount(_ sender: UITextField) {
        guard let setsAmount = Int(setsTextField.text!) else{ return}
        guard let exerciseName = exerciseLabel.text else{ return}
        
        super.updateSets(amount: setsAmount, title: exerciseName)
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
    
}
