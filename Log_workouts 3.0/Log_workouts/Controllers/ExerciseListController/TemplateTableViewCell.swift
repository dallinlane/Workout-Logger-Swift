import UIKit
import SwipeCellKit
import RealmSwift

class TemplateTableViewController: SwipeCellViewController {


    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "StandardCell", bundle: nil), forCellReuseIdentifier: K.standardCell)

        segueIdentifier = K.toTrainingScreen
        self.navigationItem.title = "Templates"


    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Number of rows in section: \(templateList.count)")
        return templateList.count
    }

    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellIdentifier = K.standardCell
        let cell = super.tableView(tableView, cellForRowAt: indexPath) as! StandardCell
        

        for template in realm.objects(Template.self){
            if templateList[indexPath.row] == template.name{
                let currentTemplate = template
                
                let isDarkMode = traitCollection.userInterfaceStyle == .dark
                let color =  pullColor(currentTemplate.backgroundColor)
                let backgroundColor = isDarkMode ?  darkenColor(oppositeColor(of: color), by: 0.4) : color
                
                cell.backgroundColor = backgroundColor
                cell.textLabel?.textColor = getColor(from: backgroundColor)
            }
        }
        
        cell.textLabel?.text = templateList[indexPath.row]

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        templateName = templateList[indexPath.row]

        performSegue(withIdentifier: K.toTrainingScreen, sender: self)
    }

    
    // MARK: - Delete Data from Swipe
    // MARK: - Delete Data from Swipe
    override func updateModel(at indexPath: IndexPath) {

        defaultsValue.removeTemplate(named: templateList[indexPath.row])

        templateList.remove(at: indexPath.row)
        
        // Now update the table view
        DispatchQueue.main.async {
            try?{
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == K.toTrainingScreen {
            defaultsValue.templateOn = true
            defaultsValue.templateInitialize = true
                        
            if let destinationVC = segue.destination as? TrainingViewController {
                destinationVC.orginSupersetValue = defaultsValue.superSetEnabled
                let templates = realm.objects(Template.self)
                if let template = templates.first(where: { $0.name == templateName }) {
                    defaultsValue.superSetEnabled = template.superSetEnabled
                    destinationVC.template = template
                }
            }
        }
    }
    

}
