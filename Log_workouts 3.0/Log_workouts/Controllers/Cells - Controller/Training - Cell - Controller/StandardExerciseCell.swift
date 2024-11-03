import UIKit

class StandardExerciseCell: TrainingTemplateCell {
    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var setsLabel: UILabel!
    @IBOutlet weak var repsLabel: UILabel!
    @IBOutlet weak var repsTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var nextSetButton: UIButton!
    var repsList: [Int] = []
    var weightList: [Double] = []
    
    var totalSets = 0
    var currentSet = 0
    var totalWeight = 0.0
    var averageWeightPerRep = 0.0
    var averageWeightPerSet = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setTextFieldWidth(textField: repsTextField, width: 80)  // Set width to 80 points
        setTextFieldWidth(textField: weightTextField, width: 80) // Set width to 80 points
        setLabelWidth(label: setsLabel, width: 70)

        
        repsTextField.keyboardType = .numberPad // For reps input
        weightTextField.keyboardType = .decimalPad // For weight input
        
        // Add target actions for editing
        repsTextField.addTarget(self, action: #selector(textFieldEditingDidBegin(_:)), for: .editingDidBegin)
        repsTextField.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)
        weightTextField.addTarget(self, action: #selector(textFieldEditingDidBegin(_:)), for: .editingDidBegin)
        weightTextField.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)
        
        
        exerciseLabel.isHidden = true
        setsLabel.text = "Set: \(currentSet + 1)"

        // Initialization code
        
        setupStackView()
        
    }
    
    private func setupStackView() {
        // Create the horizontal stack view
        let horizontalStackView = UIStackView(arrangedSubviews: [setsLabel, repsLabel, repsTextField, weightLabel, weightTextField, nextSetButton])
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = 8 // Adjust spacing between elements if needed
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the stack view to the content view
        contentView.addSubview(horizontalStackView)

        // Set constraints for the stack view
        NSLayoutConstraint.activate([
            horizontalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            horizontalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            horizontalStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }


    @IBAction func repTextFieldChanged(_ sender: UITextField) {
        guard let currentRepsString = repsTextField.text, let currentReps = Int(currentRepsString) else { return }
        guard let title = exerciseLabel.text else{return}

        super.updateReps(currentReps, for: title)
    }
    
    @IBAction func weightTextFieldChanged(_ sender: UITextField) {
        guard let currentWeightString = weightTextField.text, let currentWeight = Double(currentWeightString) else { return }
        guard let title = exerciseLabel.text else{return}

        super.updateWeight(currentWeight, for: title)
    }
    @IBAction func nextSetPressed(_ sender: UIButton) {
        totalSets -= 1
        currentSet += 1
        
        for exercise in generateExercises(){
            guard let title = exerciseLabel.text else{return}
            if title == exercise.title{
                
                let currentReps = Int(repsTextField.text ?? "\(exercise.currentReps)") ?? exercise.currentReps

                let currentWeight = Double(weightTextField.text ?? "\(exercise.currentWeight)") ?? exercise.currentWeight
                repsList.append(currentReps)
                weightList.append(currentWeight)

            }
            
            
            if totalSets == 0{
                setsLabel.isHidden = true
                repsTextField.isHidden = true
                weightTextField.isHidden = true
                nextSetButton.isHidden = true
                repsLabel.isHidden = true
                weightLabel.isHidden = true
            }
            setsLabel.text = "Set: \(currentSet + 1)"
            repsTextField.resignFirstResponder()
            weightTextField.resignFirstResponder()
        }
    }
    
    func save(){
        for index in 0..<repsList.count {
            totalWeight += Double(repsList[index]) * weightList[index]
        }
        
        let repsAverage = repsList.map {Double($0)}.reduce(0, +) / Double(repsList.count)
        
        averageWeightPerRep = totalWeight / (Double(repsList.count) * repsAverage)
        
        averageWeightPerRep = Double(String(format: "%.2f", averageWeightPerRep)) ?? 0.0
        
        averageWeightPerSet = averageWeightPerRep * repsAverage
        
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
    
    private func setLabelWidth(label: UILabel, width: CGFloat) {
        // Set the width constraint
        let widthConstraint = label.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.isActive = true
    }
}
