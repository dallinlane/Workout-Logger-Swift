import UIKit
import SwipeCellKit


class SuperSetCell: SwipeTableViewCell {
    
    @IBOutlet weak var superSetSegmentPicker: UISegmentedControl!
    var segmentPressed: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        superSetSegmentPicker.apportionsSegmentWidthsByContent = true
        
        guard let textLabel = self.textLabel else { return }
        
        

         // Disable autoresizing masks for both views to use Auto Layout
         textLabel.translatesAutoresizingMaskIntoConstraints = false
         superSetSegmentPicker.translatesAutoresizingMaskIntoConstraints = false

         // Add constraints
         NSLayoutConstraint.activate([
             textLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
             textLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
             textLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.40),

             superSetSegmentPicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
             superSetSegmentPicker.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
             superSetSegmentPicker.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),
             superSetSegmentPicker.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
         ])
        
    }

    @IBAction func pickerSelected(_ sender: UISegmentedControl) {
        segmentPressed?()
    }
    
    
}



