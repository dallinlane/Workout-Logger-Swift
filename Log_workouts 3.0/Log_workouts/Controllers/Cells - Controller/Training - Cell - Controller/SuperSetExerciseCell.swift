import UIKit

class SuperSetExerciseCell: TrainingTemplateCell {
    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var repsTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    var alignmentTextfield: UITextField!


    var textfieldText = ""

    private var stackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        alignmentTextfield = UITextField()
        alignmentTextfield.placeholder = ""
        alignmentTextfield.textAlignment = .center
        alignmentTextfield.borderStyle = .roundedRect
        

        alignmentTextfield.isHidden = false


        repsTextField.keyboardType = .numberPad // For reps input
        weightTextField.keyboardType = .decimalPad // For weight input
        
        

        
        // Add target actions for editing
        repsTextField.addTarget(self, action: #selector(textFieldEditingDidBegin(_:)), for: .editingDidBegin)
        repsTextField.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)
        weightTextField.addTarget(self, action: #selector(textFieldEditingDidBegin(_:)), for: .editingDidBegin)
        weightTextField.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)
        
        
        
        // Create and configure the stack view
        stackView = UIStackView(arrangedSubviews: [exerciseLabel, repsTextField, weightTextField, alignmentTextfield])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill

        // Add stack view to content view
        contentView.addSubview(stackView)

        // Set constraints for stack view
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Width constraints for exerciseLabel (50% of the stack)
            exerciseLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.4),

            // Width constraints for text fields (each will take 25% of the stack)
            repsTextField.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.25),
            alignmentTextfield.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.25),
            weightTextField.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.25),

        ])

    }
    
    @IBAction func repsTextFieldChanged(_ sender: UITextField) {
        guard let currentRepsString = sender.text, let currentReps = Int(currentRepsString) else { return }
        guard let title = exerciseLabel.text else{return}

        super.updateReps(currentReps, for: title)
    }
    @IBAction func weightTextFieldChanged(_ sender: UITextField) {
        guard let currentWeightString = sender.text, let currentWeight = Double(currentWeightString) else { return }
        guard let title = exerciseLabel.text else{return}
        
        for exercise in generateExercises(){
            if let title = exerciseLabel.text{
                if exercise.title == title{
                    try? realm.write{
                        exercise.IncrementAdded = true
                    }
                }
            }
        }
 
        super.updateWeight(currentWeight, for: title)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        // Set the minimum width for the text fields
        let minWidth: CGFloat = 60 // Set a minimum width

        // Calculate the required width based on the text
        let repsWidth = repsTextField.intrinsicContentSize.width
        let weightWidth = weightTextField.intrinsicContentSize.width

        // Update the frames of the text fields
        repsTextField.frame.size.width = max(minWidth, repsWidth + 16) // Add some padding
        weightTextField.frame.size.width = max(minWidth, weightWidth + 16) // Add some padding
    }
    
    
    @objc private func textFieldEditingDidBegin(_ textField: UITextField) {
         if let currentText = textField.text, !currentText.isEmpty {
             textField.placeholder = currentText
             textField.text = ""
         }
     }

    @objc private func textFieldEditingDidEnd(_ textField: UITextField) {
        let metric = (textField == repsTextField) ? " reps" : " lb"
        if let textfieldText = textField.text {
            let noWhitespaceString = textfieldText.replacingOccurrences(of: " ", with: "")
            
            if metric == " reps"{
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
    

    
}





import SwiftUI

struct SuperSetExerciseView: View {
    @State private var reps: String = ""
    @State private var weight: String = ""

    var body: some View {
        HStack(spacing: 8) {
            Text("Exercise Name") // Replace with your exercise label
                .font(.headline)
                .frame(maxWidth: .infinity) // Allow it to take 50% width

            VStack {
                TextField("Reps", text: $reps)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad) // Correct usage for number input
                    .frame(minWidth: 0, maxWidth: .infinity) // Allow text field to stretch
                
                TextField("Weight", text: $weight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad) // Correct usage for decimal input
                    .frame(minWidth: 0, maxWidth: .infinity) // Allow text field to stretch
            }
            .frame(maxWidth: .infinity) // Allow VStack to take the remaining width
        }
        .padding()
        .frame(maxWidth: .infinity) // Allow HStack to take full width
    }
}
