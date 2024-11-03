import UIKit
import RealmSwift

class PreviewHeadingCell: PreviewTemplateCell {
    @IBOutlet weak var setsTextField: UITextField!
        
    @IBOutlet weak var setLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()

        setsTextField.keyboardType = .numberPad // For reps input
        setsTextField.addTarget(self, action: #selector(textFieldEditingDidBegin(_:)), for: .editingDidBegin)
        setsTextField.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)
        
    }
        
    @IBAction func setSetsAmount(_ sender: UITextField) {
        guard let setsText = setsTextField.text, let setsAmount = Int(setsText) else{ return }
        super.updateSets(setsAmount)

        
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
