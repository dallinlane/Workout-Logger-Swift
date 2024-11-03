import Foundation

class Defaults{
    
    let defaults =  UserDefaults.standard
    
    var superSetEnabled: Bool {
        set(value) {
            defaults.setValue(value, forKey: K.switchValueKey)
        }
        get {
            return defaults.bool(forKey: K.switchValueKey)
        }
    }
    
    var deloadEnabled: Bool {
        set(value) {
            defaults.setValue(value, forKey: K.deloadKey)
        }
        get {
            return defaults.bool(forKey: K.deloadKey)
        }
    }
    
    var incrementingWeightEnabled: Bool {
        set(value) {
            defaults.setValue(value, forKey: K.incrementWeightEnabledKey)
        }
        get {
            return defaults.bool(forKey: K.incrementWeightEnabledKey)
        }
    }
    
    var incrementWeightAmount: Double {
        set(value) {
            defaults.setValue(value, forKey: K.incrementWeightKey)
        }
        get {
            return defaults.double(forKey: K.incrementWeightKey)
        }
    }

    
    var templateOn:Bool {
        set(value) {
            defaults.setValue(value, forKey: K.templateOnKey)
        }
        get {
            return defaults.bool(forKey: K.templateOnKey)
        }

    }
    
    var templateInitialize:Bool {
        set(value) {
            defaults.setValue(value, forKey: K.templateinitializeKey)
        }
        get {
            return defaults.bool(forKey: K.templateinitializeKey)
        }

    }
    
    var order: Int {
        set(value) {
            defaults.setValue(value, forKey: K.orderValueKey)
        }
        get {
            return defaults.integer(forKey: K.orderValueKey)
        }
    }
    
    var superSetOrder: Int {
        set(value) {
            defaults.setValue(value, forKey: K.superSetOrder)
        }
        get {
            return defaults.integer(forKey: K.superSetOrder)
        }
    }
    
    var setCounter: [String: Int] {
        set {
            defaults.setValue(newValue, forKey: K.setCounter)
        }
        get {
            return defaults.dictionary(forKey: K.setCounter) as? [String: Int] ?? [:]
        }
    }
    
    var setTemplate: [String: [TemplateExercise]] {
        set {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(newValue) {
                defaults.set(encoded, forKey: K.templateKey)
            }
        }
        get {
            if let data = defaults.data(forKey: K.templateKey) {
                let decoder = JSONDecoder()
                return (try? decoder.decode([String: [TemplateExercise]].self, from: data)) ?? [:]
            }
            return [:]
        }
    }
    
    func removeTemplate(named name: String) {
        var templates = setTemplate // Get the current templates
        templates.removeValue(forKey: name) // Remove the template with the specified name
        setTemplate = templates // Update the setTemplate property
    }

    
    func removeValue(forKey key: String) {
        var currentDict = setCounter // Retrieve the current dictionary
        currentDict.removeValue(forKey: key) // Remove the value for the specified key
        setCounter = currentDict // Save the updated dictionary back to UserDefaults
    }
    
    func resetSetCounter() {
        setCounter = [:]  // Set the dictionary to an empty dictionary
        defaults.removeObject(forKey: K.setCounter)  // Optionally, remove the stored value entirely from UserDefaults
    }

    
    

}

