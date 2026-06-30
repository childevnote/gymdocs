import Foundation
import SwiftData

@Model
final class DailySummary {
    @Attribute(.unique) var date: Date
    var isFinished: Bool
    
    init(date: Date, isFinished: Bool = false) {
        self.date = Calendar.current.startOfDay(for: date)
        self.isFinished = isFinished
    }
}
