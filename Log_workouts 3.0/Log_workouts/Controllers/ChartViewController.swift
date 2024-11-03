import UIKit
import SwiftUI
import RealmSwift

class ChartViewController: UIViewController {
    var realm: Realm!
    var chartView: UIHostingController<ChartView>?
    var currentExercise: Exercise?
    var currentGoal: Goal?
    var currentLineColor = UIColor.black
    var currentBackgroundColor = UIColor.blue
    
    private var previousSelectedType: SelectionType = .none
    private var previousExerciseTitle: String = "Exercise"
    
    enum SelectionType {
        case exercise
        case goal
        case none
    }
    
    var selectedType: SelectionType = .none


    @IBOutlet weak var bodyTypeDropDown: UIButton!
    
    @IBOutlet weak var exerciseDropDown: UIButton!
    
    @IBOutlet weak var chartDatePicker: UISegmentedControl!
    
    @IBOutlet weak var weightPicker: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))

        setupView()
        
        do {
            realm = try Realm()
        } catch {
            fatalError("Unable to initialize Realm: \(error)")
        }
        setupBodyTypeDropDown()
        setupExerciseDropDown()

        for exercise in realm.objects(GoalTotalWeight.self){
        } // Fetch body parts from realm
        
        
        previousSelectedType = selectedType
        previousExerciseTitle = exerciseDropDown.title(for: .normal) ?? "Exercise"
        self.navigationItem.title = "Progress"

    }
    
    func setupView() {
        let initialData: [ExerciseData] = [] // Set an empty array for initial chart data
        chartView = UIHostingController(rootView: ChartView(maxWeight: 300 * 2, lineColor: .black , backgroundColor: .blue, totalProgress: "", index: chartDatePicker.selectedSegmentIndex, header: "", bodyPartProgress: initialData))

        if let chartView = chartView?.view {
            chartView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(chartView)
            
            NSLayoutConstraint.activate([
                chartView.topAnchor.constraint(equalTo: view.topAnchor),
                chartView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                chartView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                chartView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        }
        let stackView = UIStackView(arrangedSubviews: [bodyTypeDropDown, exerciseDropDown, chartDatePicker, weightPicker])
            stackView.axis = .vertical
            stackView.spacing = 16 // Adjust spacing as needed
            stackView.translatesAutoresizingMaskIntoConstraints = false

            // Add the stack view to the main view
            view.addSubview(stackView)

            // Set up constraints for the stack view
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
                stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ])

    }
    

    func setupBodyTypeDropDown() {
            let bodyParts = realm.objects(BodyPart.self)
        
            
            var actions: [UIAction] = bodyParts.map { bodyPart in
                UIAction(title: bodyPart.name) { [weak self] _ in
                    // Update the text of the bodyTypeDropDown button
                    self?.bodyTypeDropDown.setTitle(bodyPart.name, for: .normal)
                    self?.exerciseDropDown.setTitle("Exercise", for: .normal)

                    // Update the exercise dropdown based on the selected body part
                    self?.updateExerciseDropDown(for: bodyPart)
                    self?.conditionallyResetChartView() // Reset chart when a new body type is selected

                }
            }
        
        // Add "Goals" option
          let goalsAction = UIAction(title: "Goals") { [weak self] _ in
              self?.bodyTypeDropDown.setTitle("Goals", for: .normal)
              self?.exerciseDropDown.setTitle("Goal", for: .normal)

              self?.updateGoalsDropDown() // Call a new function to update goals
              self?.conditionallyResetChartView() // Reset chart when a new body type is selected

          }
          
          actions.append(goalsAction)
            
            bodyTypeDropDown.menu = UIMenu(title: "Select Body Part", children: actions)
            bodyTypeDropDown.showsMenuAsPrimaryAction = true
        }
    
    func updateGoalsDropDown() {
        let goals = realm.objects(Goal.self) // Assuming Goal is the class for goals
        
        let actions: [UIAction] = goals.map { goal in
            UIAction(title: goal.name) { [weak self] _ in
                self?.exerciseDropDown.setTitle(goal.name, for: .normal)
                self?.selectedType = .goal
                self?.updateChartData(for: goal) // Assuming you have a method to update chart data for goals
            }
        }
        
        exerciseDropDown.menu = UIMenu(title: "Select Goal", children: actions)
        exerciseDropDown.showsMenuAsPrimaryAction = true
    }

    func updateChartData(for goal: Goal) {
        currentGoal = goal
        // Sort the totalWeight data by date
        let totalWeight = realm.objects(GoalTotalWeight.self).filter("title == %@", currentGoal?.name)

        let sortedWeights = totalWeight.sorted(by: { $0.date < $1.date })
        
        var weightChange = "Progress: "
        if let firstWeight = totalWeight.first?.totalWeight, let lastWeight = totalWeight.last?.totalWeight{
            weightChange += String(lastWeight - firstWeight) + " Pounds!"
        }

         // Extract the weight and date values for charting
         let dates = sortedWeights.map { $0.date }
        
        let weights: [Double] = {
            switch weightPicker.selectedSegmentIndex {
            case 0:
                return sortedWeights.map { $0.totalWeight }
            case 1:
                return sortedWeights.map { $0.averageWeightPerSet }
            case 2:
                return sortedWeights.map { $0.averageWeightPerRep }
            default:
                return sortedWeights.map { Double($0.totalReps) }
            }
        }()
        
   

         // Call your chart rendering function here
        updateChart(with: dates, weights: weights, lineColor: pullColor(goal.textColor), backgroundColor:  pullColor(goal.backgroundColor), progress: weightChange)

    }
    
    func updateChartData(for exercise: Exercise) {
        currentExercise = exercise
        // Sort the totalWeight data by date
         let totalWeight = realm.objects(ExerciseTotalWeight.self).filter("title == %@", exercise.title)

         let sortedWeights = totalWeight.sorted(by: { $0.date < $1.date })
        
        var weightChange = "Progress: "
        if let firstWeight = totalWeight.first?.totalWeight, let lastWeight = totalWeight.last?.totalWeight{
            weightChange += String(lastWeight - firstWeight) + " Pounds!"
        }

         // Extract the weight and date values for charting
         let dates = sortedWeights.map { $0.date }
        
        let weights: [Double] = {
            switch weightPicker.selectedSegmentIndex {
            case 0:
                return sortedWeights.map { $0.totalWeight }
            case 1:
                return sortedWeights.map { $0.averageWeightPerSet }
            case 2:
                return sortedWeights.map { $0.averageWeightPerRep }
            default:
                return sortedWeights.map { Double($0.totalReps) }
            }
        }()
        
   

         // Call your chart rendering function here
        updateChart(with: dates, weights: weights, lineColor: pullColor(exercise.textColor), backgroundColor:  pullColor(exercise.backgroundColor), progress: weightChange)
    }

        
    func updateExerciseDropDown(for bodyPart: BodyPart) {
        let exercises = bodyPart.exercise
        
        let actions: [UIAction] = exercises.map { exercise in
            UIAction(title: exercise.title) { [weak self] _ in
                self?.exerciseDropDown.setTitle(exercise.title, for: .normal)
                self?.selectedType = .exercise
                self?.updateChartData(for: exercise) // Update chart data when exercise is selected
            }
        }
        
        exerciseDropDown.menu = UIMenu(title: "Select Exercise", children: actions)
        exerciseDropDown.showsMenuAsPrimaryAction = true
    }

    func setupExerciseDropDown() {
        // Set initial empty menu, or you can load default exercises if necessary
        exerciseDropDown.menu = UIMenu(title: "Select Exercise", children: [])
        exerciseDropDown.showsMenuAsPrimaryAction = true
    }
    


    func updateChart(with dates: [Date], weights: [Double], lineColor: UIColor, backgroundColor: UIColor, progress: String) {
        // Create an array of ExerciseData from the dates and weights
           let bodyPartProgress: [ExerciseData] = zip(weights, dates).map { ExerciseData(amount: $0, createAt: $1) }
        
        currentLineColor = lineColor
        currentBackgroundColor = backgroundColor

        let maxWeight = bodyPartProgress.map { $0.amount }.max() ?? 300
        
        let headerText: String = {
            switch weightPicker.selectedSegmentIndex {
            case 0:
                return "Overall Weight Progress"
            case 1:
                return "Overall Set Weight Progress"
            case 2:
                return "Overall Rep Weight Progress"
            default:
                return "Overall Reps Progress"
            }
        }()

        
        if let chartView = chartView {
            chartView.rootView = ChartView(maxWeight: maxWeight * 1.5, lineColor: Color(lineColor), backgroundColor: Color(backgroundColor) , totalProgress: progress, index: chartDatePicker.selectedSegmentIndex, header: headerText, bodyPartProgress: bodyPartProgress)
            chartView.view.setNeedsLayout()
        }
    }

    
    
    
    @IBAction func segmentControlValueChanged(_ sender: UISegmentedControl) {
        switch selectedType {
        case .exercise:
            if let exercise = currentExercise {
                updateChartData(for: exercise)
            }
        case .goal:
            if let goal = currentGoal {
                updateChartData(for: goal)
            }
        case .none:
            break // No action needed
        }
    }
    
    @IBAction func weightSegmentValueChanged(_ sender: UISegmentedControl) {
        switch selectedType {
           case .exercise:
               if let exercise = currentExercise {
                   updateChartData(for: exercise)
               }
           case .goal:
               if let goal = currentGoal {
                   updateChartData(for: goal)
               }
           case .none:
               break // No action needed
           }
    }
    
    
    
    func pullColor(_ colorString: String) -> UIColor {
        let components = colorString.components(separatedBy: "-").compactMap { Float($0) }
        
        guard components.count == 3 else {
            // Return a default color if conversion fails
            return UIColor.black
        }

        return UIColor(red: CGFloat(components[0]), green: CGFloat(components[1]), blue: CGFloat(components[2]), alpha: 1)
    }
    
    func conditionallyResetChartView() {
           // Only reset if the selection type changes or the exercise dropdown isn't at default
           if selectedType != previousSelectedType || exerciseDropDown.title(for: .normal) != previousExerciseTitle {
               resetChartView()
           }
           
           // Update previous states after conditional check
           previousSelectedType = selectedType
           previousExerciseTitle = exerciseDropDown.title(for: .normal) ?? "Exercise"
       }
    
    func resetChartView() {
        let emptyData: [ExerciseData] = []
        let defaultProgressText = ""
        
        updateChart(
            with: [],
            weights: [],
            lineColor: currentLineColor,
            backgroundColor: currentBackgroundColor,
            progress: defaultProgressText
        )
    }
    @objc func backButtonTapped() {
        // Handle back button tap action
        navigationController?.popViewController(animated: true)
    }
    



}
