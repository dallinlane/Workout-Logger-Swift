import SwiftUI
import Charts

// Struct representing each exercise data point
struct ExerciseData: Identifiable {
    let amount: Double
    let createAt: Date
    let id = UUID()
}

// SwiftUI Chart View
struct ChartView: View {
//    let goal: Double
    let maxWeight : Double
    let lineColor: Color
    let backgroundColor: Color
    let totalProgress: String
    let index: Int
    let header: String
    
    private var startDate: Date {
         switch index {
         case 0:
             return bodyPartProgress.map { $0.createAt }.min() ?? Date()
         case 1:
             return Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date() // 1 year ago
         case 2:
             return Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date() // 6 months ago
         case 3:
             return Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date() // 3 months ago
         case 4:
             return Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date() // 1 month ago
         case 5:
             return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date() // 1 week ago
         default:
             return bodyPartProgress.map { $0.createAt }.min() ?? Date()
         }
     }
    
    private var gridIntervals: [Date] {
        
        // Calculate the total duration from startDate to now
         let totalDuration = Date().timeIntervalSince(startDate)

         // Calculate the step size to create 4 evenly spaced intervals
         let stepSize = totalDuration / 3 // Dividing by 3 gives us 4 intervals

         // Generate the 4 evenly spaced intervals
         let intervals = (0...4).map { i -> Date in
             return startDate.addingTimeInterval(stepSize * Double(i))
         }

         return intervals
    }
    


    let bodyPartProgress: [ExerciseData]  // Data to be plotted

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Assuming bodyPartProgress is a valid array
            let totalAmount = bodyPartProgress.reduce(0) { $0 + $1.amount }
            let formattedTotal = NumberFormatter.localizedString(from: NSNumber(value: totalAmount), number: .decimal)

            Text(formattedTotal == "0" ? "" : "\(header) \(formattedTotal)")
                .fontWeight(.semibold)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom, 12)

            Chart {
                ForEach(bodyPartProgress) { exercise in
                    LineMark(
                        x: .value("Date", exercise.createAt),
                        y: .value("Weight", exercise.amount)
                    )
                    .foregroundStyle(lineColor)
                }
            }
            .chartXAxis {
                AxisMarks(values: gridIntervals) { date in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated).year())
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartYScale(domain: 0...maxWeight) // Ensure maxWeight is defined
            .chartPlotStyle { plotContent in
                plotContent
                    .background(backgroundColor.opacity(0.3))
                    .border(lineColor, width: 3)
            }
            .frame(maxWidth: .infinity, maxHeight: 300)
            .padding([.leading, .trailing], 16)
        }
        .padding(.horizontal, 16)
    }
}
