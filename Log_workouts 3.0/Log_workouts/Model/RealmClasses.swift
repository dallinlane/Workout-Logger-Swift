import Foundation
import RealmSwift

class Exercise: Object{
    @objc dynamic var title: String = ""
    @objc dynamic var sortedorder: Int = 999999
    @objc dynamic var done: Bool = false
    @objc dynamic var supersetValue: Int = 4
    @objc dynamic var order = 0
    @objc dynamic var superSetOrder = 0
    @objc dynamic var dateFinished: Date?
    var parentBodyPart = LinkingObjects(fromType: BodyPart.self, property: "exercise")
    @objc dynamic var backgroundColor: String = ""
    @objc dynamic var textColor: String = ""
    @objc dynamic var currentWeight: Double = 0
    @objc dynamic var currentSets: Int = 1
    @objc dynamic var currentReps: Int = 10
    @objc dynamic var deloadOn: Bool = false
    @objc dynamic var deloadDate: Date?
    @objc dynamic var weights: Bool = true
    @objc dynamic var incrementWeights: Bool = true
    var totalWeight = List<ExerciseTotalWeight>()
    var repsList: [Int] = []
    var weightList: [Double] = []
    @objc dynamic var deloadWeight: Double = 0.0
    @objc dynamic var deloadReps: Int = 0
    @objc dynamic var IncrementAdded: Bool = false
}

class ExerciseTotalWeight: Object {
    @objc dynamic var date: Date = Date()
    @objc dynamic var totalWeight: Double = 0.0
    @objc dynamic var totalReps: Int = 0
    @objc dynamic var title: String = ""
    @objc dynamic var averageWeightPerRep: Double = 0.0
    @objc dynamic var averageWeightPerSet: Double = 0.0
}

class Template: Object{
    @objc dynamic var name: String = ""
    @objc dynamic var superSetEnabled: Bool = false
    @objc dynamic var backgroundColor: String = ""
    @objc dynamic var textColor: String = ""
}

struct TemplateExercise: Codable {
    let name: String
    let order: Int
    let superSetOrder: Int
    let sortOrder: Int
    let supersetValue: Int
    let sets: Int
    let reps: Int
}



class Goal: Object{
    @objc dynamic var name: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var backgroundColor: String = ""
    @objc dynamic var textColor: String = ""
    @objc dynamic var currentWeight: Double = 0
    @objc dynamic var goalReps: Int = 0
    @objc dynamic var currentReps: Int = 0
    @objc dynamic var repsDone: Int = 0
    @objc dynamic var weightEnabled: Bool = true
    
    @objc dynamic var totalWeight: Double = 0.0
    @objc dynamic var averageWeightPerRep: Double = 0.0
    @objc dynamic var averageWeightPerSet: Double = 0.0
    
    var repsList: [Int] = []
    var weightList: [Double] = []

}

class GoalTotalWeight: Object {
    @objc dynamic var date: Date = Date()
    @objc dynamic var title: String = ""
    @objc dynamic var totalWeight: Double = 0.0
    @objc dynamic var totalReps: Int = 0
    @objc dynamic var averageWeightPerRep: Double = 0.0
    @objc dynamic var averageWeightPerSet: Double = 0.0
    

}

class BodyPart: Object{
    @objc dynamic var name: String = ""
    let exercise = List<Exercise>()
    @objc dynamic var backgroundColor: String = ""
    @objc dynamic var textColor: String = ""
}

