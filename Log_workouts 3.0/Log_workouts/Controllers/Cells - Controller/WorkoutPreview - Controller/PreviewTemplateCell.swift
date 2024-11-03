import UIKit
import RealmSwift

class PreviewTemplateCell: UITableViewCell {
    var realm: Realm!
    var defaultsValue = Defaults()
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        do {
            realm = try Realm()
        } catch {
            fatalError("Unable to initialize Realm: \(error)")
        }
    }
    func generateExercises() -> List<Exercise> {
        let exercises = List<Exercise>() // Initialize the list
        let bodyParts = realm.objects(BodyPart.self)
        for bodyPart in bodyParts {
            for exercise in bodyPart.exercise {
                exercises.append(exercise)
            }
        }
        return exercises
    }
    
    func returnString(_ index: Int) -> String{
        var text = ""
        switch index{
        case 0:
            text = "A"
        case 1:
            text = "B"
        case 2:
            text = "C"
        default:
            text = "D"
        }
        
        return text
    }
    
    func returnTextLabel() -> String {
        var matches: [Double] = [] // Array to hold unique superset values
        
        for exercise in generateExercises() {
            guard let identifier = self.textLabel?.text else{ return "1"}
            if returnString(exercise.supersetValue) == identifier{
                matches.append(Double(exercise.currentSets))
            }
        }
        
        // Check if matches is not empty to avoid division by zero
        if matches.isEmpty {
            return "0"
        } else {
            let average = matches.reduce(0, +) / Double(matches.count)
            return String(Int(round(average))) // Safely convert average to an Int
        }
    }
    
    func updateSets(_ setsAmount: Int){
        for exercise in generateExercises(){
            guard let identifier = self.textLabel?.text else{return}
            
            if returnString(exercise.supersetValue) == identifier{
                
                try? realm.write {
                        exercise.currentSets = setsAmount
                }
            }
        }
    }
    
    func updateSets(amount: Int, title: String){
        
        for exercise in generateExercises(){
            
            if title == exercise.title{
                try? realm.write {
                        exercise.currentSets = amount
                }
            }
        }
    }
}
