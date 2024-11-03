import UIKit
import RealmSwift


class TrainingViewController: ExerciseList {
    var numberOfCells = 0
    var nextCell = 1
    var index = 0
    var template = Template()
    var orginSupersetValue = false
    var isDarkMode = false
    
    var workoutList: [Exercise] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        isDarkMode = traitCollection.userInterfaceStyle == .dark
        trainingScreen = true
        segueIdentifier = K.toHomeScreen
        self.navigationItem.title = "Train"
        
        workoutList = generateWorkout()
        
        tableView.reloadData()

    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfCells
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        
        let isLastRow = numberOfCells - 1 == indexPath.row
        
        if superSetEnabled{
            if isLastRow {
                return configureNextButton(for: indexPath)
            } else {
                if indexPath.row == 0{
                    let cell = super.configureExerciseCell(for: indexPath, exercise: workoutList[indexPath.row], identifier: K.superSetHeadingCell)
                    return cell
                }else{
                    return super.configureExerciseCell(for: indexPath, exercise: workoutList[indexPath.row - 1], identifier: K.superSetExerciseCell)
                }
            }
        }else{
            if isLastRow {
                return configureDoneWorkoutButtonCell(for: indexPath)

            }else {
                var currentCellIndex = 0
                
                let exercise = workoutList[indexPath.row / 2]

                if indexPath.row % 2 == 0 {
                    // Even index for exercise heading
                    return super.configureExerciseCell(for: indexPath, exercise: exercise, identifier: K.previewHeadingCell)
                } else {
                    // Odd index for exercise set details
                    return configureSetCell(for: indexPath, exercise: exercise)
                }

            }
        }
        return UITableViewCell()
    }
    
    func configureSetCell(for indexPath: IndexPath, exercise: Exercise) -> UITableViewCell {
        guard let setCell = tableView.dequeueReusableCell(withIdentifier: K.standardExerciseCell, for: indexPath) as? StandardExerciseCell else {
            return UITableViewCell() // Fallback if cell dequeuing fails
        }
        setCell.exerciseLabel.text = exercise.title
        setCell.totalSets = exercise.currentSets
        setCell.repsTextField.text = "\(exercise.currentReps)"
        if exercise.weights{
            setCell.weightTextField.text = "\(exercise.currentWeight + returnIncrementAmount(exercise)) lb"
        }else{
            setCell.weightTextField.isHidden = true
            setCell.weightLabel.isHidden = true
        }
        
        setCell.selectionStyle = .none
        
        setCell.exerciseLabel.textColor = textColor
        setCell.repsLabel.textColor = textColor
        setCell.repsTextField.textColor = backgroundColor
        setCell.repsTextField.backgroundColor = brightenColor(textColor, by: 0.2)
        setCell.weightLabel.textColor = textColor
        setCell.weightTextField.textColor = backgroundColor
        setCell.weightTextField.backgroundColor = brightenColor(textColor, by: 0.2)
        setCell.setsLabel.textColor = textColor
        setCell.backgroundColor = backgroundColor
        setCell.nextSetButton.setTitleColor(textColor, for: .normal)


        
        return setCell
    }
    
    
    func generateWorkout() -> [Exercise]{
        
        if defaultsValue.templateInitialize{
            generateTemplate()
            defaultsValue.templateInitialize = false
        }
        
        if listOfSupersetTypes.isEmpty{
            generatelistOfSupersetTypes()
            
            if let superSetName = defaultsValue.setCounter.keys.sorted().first{
                currentSet = superSetName
            }
        }
        
        if superSetEnabled{
            var orderedExercises: [Exercise] = []
            for exercise in exerciseList{
                if returnString(exercise.supersetValue) == currentSet{
                    orderedExercises.append(exercise)
                }
            }
            headingCellsAmount = 1
            numberOfCells = headingCellsAmount + orderedExercises.count + 1
            return sort(exercises: orderedExercises)
        }else {
            numberOfCells = (exerciseList.count * 2) + 1
            
            return sort(exercises: exerciseList)
        }
    }
    
    func generatelistOfSupersetTypes(){
        for exercise in exerciseList{
            if exercise.supersetValue < 4{
                var superSetName = self.returnString(exercise.supersetValue)
                if !listOfSupersetTypes.contains(superSetName){
                    listOfSupersetTypes.append(superSetName)
                }
            }
        }
    }
    
    
    func configureNextButton(for indexPath: IndexPath) -> UITableViewCell {
        guard let doneButtonCell = tableView.dequeueReusableCell(withIdentifier: K.buttonCell, for: indexPath) as? ButtonCell else {
            return UITableViewCell() // Fallback if cell dequeuing fails
        }
        
        doneButtonCell.button.setTitle("Next", for: .normal)

        
        doneButtonCell.button.addTarget(self, action: #selector(nextSuperSet), for: .touchUpInside)
        doneButtonCell.selectionStyle = .none
        doneButtonCell.button.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .white : .blue, for: .normal)

        return doneButtonCell
        
    }
    
    
    @objc func nextSuperSet() {
        tableView.endEditing(true)

        for exercise in workoutList{
                
            try? realm.write {
                exercise.repsList.append(exercise.currentReps)
                exercise.weightList.append(exercise.currentWeight)
            }

                
        }
        

        if defaultsValue.setCounter[currentSet] == 1 {

            // Remove the current set and fetch the next available set
            defaultsValue.removeValue(forKey: currentSet)
            
            if defaultsValue.setCounter.isEmpty{
                
                doneButtonPressed()
                
                return
            }
            
            if let nextSet = defaultsValue.setCounter.keys.sorted().first {
                currentSet = nextSet
            } else {
                // If no more supersets are available, reset or handle appropriately
                currentSet = ""
                listOfSupersetTypes.removeAll()
            }
        } else {
            // Decrement the set counter
            defaultsValue.setCounter[currentSet]! -= 1
        }


        // Reset heading cell amount and other counters if necessary
        headingCellsAmount = 0
        extraCells = 0
        numberOfCells = 0
        workoutList.removeAll()  // Clear the list and regenerate it

        // Reload the superset list and update the table view
        workoutList = generateWorkout()

        tableView.reloadData()
    }
    
    func returnNextCell(_ title: String) -> Int {
        for exercise in exerciseList {
            if exercise.title == title {
                nextCell += exercise.currentSets + 1
            }
        }
        return nextCell
    }
    
    func save() {
        
        for exercise in exerciseList {
            if shouldSkipExercise(exercise: exercise) {
                continue
            }
    
            let currentDate = Date()
        
            var totalWeight = 0.0
            var averageWeightPerRep = 0.0
            var averageWeightPerSet = 0.0
            var repsAverage = 0.0
            var reptotal = 0
            
            if superSetEnabled{
                for index in 0..<exercise.repsList.count {
                    totalWeight += Double(exercise.repsList[index]) * exercise.weightList[index]
                }
                
                averageWeightPerRep = 0.0
                reptotal = exercise.repsList.reduce(0, +)
                repsAverage = exercise.repsList.map { return Double($0); print($0)}.reduce(0, +) / Double(exercise.repsList.count)

                averageWeightPerRep = totalWeight / (Double(exercise.repsList.count) * repsAverage)
                
                averageWeightPerRep = Double(String(format: "%.2f", averageWeightPerRep)) ?? 0.0
                
                averageWeightPerSet = averageWeightPerRep * repsAverage

                
                
            }else{
                for cell in tableView.visibleCells {
                    if let cell = cell as? StandardExerciseCell {
                        cell.save()
                        repsAverage = cell.repsList.map { return Double($0); print($0)}.reduce(0, +) / Double(exercise.repsList.count)
                        totalWeight = cell.totalWeight
                        averageWeightPerRep = cell.averageWeightPerRep
                        averageWeightPerSet = cell.averageWeightPerSet
                        reptotal = cell.repsList.reduce(0, +)
                    }
                }

            }
            
            
            if defaultsValue.deloadEnabled{
                let weightsForExercise = realm.objects(ExerciseTotalWeight.self).filter("title == %@", exercise.title)
                let sortedWeightsForExercise = weightsForExercise.sorted(by: { $0.date < $1.date })
                let mostRecentWeights = Array(sortedWeightsForExercise.prefix(3))

                
                var totalWeightList : [Double] = []
                var repHistory : [Int] = []

                for exercise in mostRecentWeights{
                    totalWeightList.append(exercise.totalWeight)
                    repHistory.append(exercise.totalReps)
                }
                
                let totalWeightHistorySum = totalWeightList.reduce(0, +)
                let repHistorySum = repHistory.reduce(0, +)
                let averageWeightHistory = totalWeightList.isEmpty ? 0 : totalWeightHistorySum / Double(totalWeightList.count)
                let averageRepHistory = repHistory.isEmpty ? 0 : repHistorySum / repHistory.count
                
                if exercise.deloadOn == false{
                    
                    var turnOnDeload = false
                    
                    if exercise.weights{
                        if totalWeight < averageWeightHistory * 0.10{
                            turnOnDeload = true
                        }
                    }else{
                        if reptotal < Int(Double(averageRepHistory) * 0.10){
                            turnOnDeload = true
                        }
                    }
                    
                    
                    
                    if turnOnDeload {
                        
                        let weight = exercise.currentWeight / 2
                        let reps = exercise.currentReps / 2
                        try? realm.write{
                            exercise.deloadOn = true
                            
                            exercise.currentReps = reps
                            exercise.deloadReps = reps
                            
                            exercise.currentWeight = weight
                            exercise.deloadWeight = weight
                            
                            
                            exercise.deloadDate = Date()
                        }
                    }

                }

            }
            if !exercise.weights{
                totalWeight = 0
                averageWeightPerRep = 0
                averageWeightPerSet = 0
            }
       

            try? realm.write {
                
                if defaultsValue.incrementingWeightEnabled{
                    if !exercise.deloadOn{
                        if exercise.weights{
                            if !exercise.IncrementAdded{
                                exercise.currentWeight += defaultsValue.incrementWeightAmount
                            }
                        }
                    }
                }
                let exerciseTotalWeight = ExerciseTotalWeight()
                exerciseTotalWeight.title = exercise.title
                exerciseTotalWeight.date = currentDate
                exerciseTotalWeight.totalWeight = totalWeight
                exerciseTotalWeight.averageWeightPerRep = averageWeightPerRep
                exerciseTotalWeight.averageWeightPerSet = averageWeightPerSet
                exerciseTotalWeight.totalReps = reptotal
                
                exercise.totalWeight.append(exerciseTotalWeight)
                
            }
            
        }
    }

    func shouldSkipExercise(exercise: Exercise) -> Bool {
        if superSetEnabled && exercise.supersetValue == 4 {
            return true
        } else if !superSetEnabled && exercise.order == 0 {
            return true
        }
        return false
    }
    
    override func configureDoneWorkoutButtonCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let doneButtonCell = tableView.dequeueReusableCell(withIdentifier: K.buttonCell, for: indexPath) as? ButtonCell else {
            return UITableViewCell() // Fallback if cell dequeuing fails
        }
        
        doneButtonCell.button.setTitle("Done", for: .normal)
        

        doneButtonCell.button.setTitleColor( isDarkMode ? .white : .blue, for: .normal)

        doneButtonCell.button.addTarget(self, action: #selector(doneButtonPressed), for: .touchUpInside)
        doneButtonCell.selectionStyle = .none

        return doneButtonCell
        
    }
    
    func resetOrder(){
        
        let bodyParts = realm.objects(BodyPart.self)
        for bodyPart in bodyParts {
            for exercise in bodyPart.exercise {
                try? realm.write {
                    exercise.superSetOrder = 0
                    exercise.supersetValue = 4
                    exercise.order = 0
                    exercise.sortedorder = 9999
                    exercise.done = false
                    defaultsValue.order = 0
                    defaultsValue.superSetOrder = 0
                }
            }
        }
    }
    
    @objc override func doneButtonPressed() {
        save()
        resetOrder()
        
        defaultsValue.superSetEnabled = defaultsValue.templateOn ? orginSupersetValue : defaultsValue.superSetEnabled
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }
    
    func generateTemplate(){
        defaultsValue.resetSetCounter()
        tableView.endEditing(true)
        
        resetOrder()
        let bodyParts = realm.objects(BodyPart.self)
        let templateExerciseList = defaultsValue.setTemplate[template.name] ?? [] // Safely unwrap

        for bodyPart in bodyParts {
            for exercise in bodyPart.exercise {
                for tempExercise in templateExerciseList {
                    if tempExercise.name == exercise.title {

                        try? realm.write {
                            exercise.order = tempExercise.order
                            exercise.superSetOrder = tempExercise.superSetOrder
                            exercise.sortedorder = tempExercise.sortOrder
                            exercise.supersetValue = tempExercise.supersetValue
                            exercise.currentSets = tempExercise.sets
                            exercise.currentReps = tempExercise.reps
                            exercise.IncrementAdded = false

                        }
    
                    }
                }

            }
        }
        
        superSetEnabled = defaultsValue.superSetEnabled
        super.resetCounter()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if defaultsValue.templateOn{
            resetOrder()
        }
    }

    
    func sort(exercises: [Exercise]) -> [Exercise] {
        if superSetEnabled{
            return exercises.sorted {
                if $0.supersetValue != $1.supersetValue {
                    return $0.supersetValue < $1.supersetValue // First sort by sortedorder
                } else {
                    return $0.superSetOrder < $1.superSetOrder // Then sort by title
                }
            }
        } else {
            return exercises.sorted {
                if $0.sortedorder != $1.sortedorder {
                    return $0.sortedorder < $1.sortedorder // First sort by sortedorder
                } else {
                    return $0.title < $1.title // Then sort by title
                }
            }
        }
      
    }
    


    

}
