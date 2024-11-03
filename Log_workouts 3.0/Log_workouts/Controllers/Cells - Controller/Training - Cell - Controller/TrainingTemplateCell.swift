import UIKit
import RealmSwift

class TrainingTemplateCell: UITableViewCell {
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
    
    func updateWeight(_ weight: Double, for title: String){
        for exercise in generateExercises(){
            if exercise.title == title{

                try? realm.write {
                    exercise.currentWeight = weight
                }
            }
        }
    }
    
    func updateReps(_ reps: Int, for title: String){
        for exercise in generateExercises(){
            if exercise.title == title{
                try? realm.write {
                    exercise.currentReps = reps
                }
            }
        }
    }
    
    
}
