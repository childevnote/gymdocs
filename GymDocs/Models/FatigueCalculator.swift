import Foundation
import SwiftData

struct FatigueResult: Identifiable {
    let id = UUID()
    let bodyPart: BodyPart
    let currentFatigue: Double // 0 to 100
    let hoursToRecover: Double
}

struct FatigueCalculator {
    static func calculate(records: [WorkoutRecord], userWeight: Double) -> [FatigueResult] {
        let now = Date()
        let calendar = Calendar.current
        
        let twentyEightDaysAgo = calendar.date(byAdding: .day, value: -28, to: now) ?? now
        let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: now) ?? now
        
        // Filter records
        let recent28Records = records.filter { $0.date >= twentyEightDaysAgo }
        let recent4Records = records.filter { $0.date >= fourDaysAgo }
        
        var results: [FatigueResult] = []
        
        let relevantParts: [BodyPart] = [.chest, .back, .legs, .shoulders, .biceps, .triceps, .forearms, .core, .fullBody]
        
        for part in relevantParts {
            let base = baseCapacity(for: part, userWeight: userWeight)
            
            // Calculate Max Capacity from past 28 days
            var dailyIntensities: [Date: Double] = [:]
            for record in recent28Records where record.exercise?.bodyPart == part {
                let day = calendar.startOfDay(for: record.date)
                dailyIntensities[day, default: 0] += record.intensityScore
            }
            let maxDaily = dailyIntensities.values.max() ?? 0
            let maxCapacity = max(base, maxDaily)
            
            if maxCapacity <= 0 { continue } // Avoid division by zero
            
            // Calculate Current Fatigue from past 4 days
            var totalFatigue = 0.0
            
            // Group recent 4 days records by exact day
            var recentDailyIntensities: [Date: Double] = [:]
            for record in recent4Records where record.exercise?.bodyPart == part {
                let day = calendar.startOfDay(for: record.date)
                recentDailyIntensities[day, default: 0] += record.intensityScore
            }
            
            for (day, intensity) in recentDailyIntensities {
                // Assume workout happened at 12:00 PM (noon) on that day
                let workoutTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
                let hoursPassed = max(0, now.timeIntervalSince(workoutTime) / 3600.0)
                
                let generatedFatigue = min(100.0, (intensity / maxCapacity) * 100.0)
                let decayRatePerHour = decayRate(for: part)
                
                let residualFatigue = max(0, generatedFatigue - (decayRatePerHour * hoursPassed))
                totalFatigue += residualFatigue
            }
            
            totalFatigue = min(100.0, totalFatigue)
            
            if totalFatigue > 0 {
                let hoursToRecover = totalFatigue / decayRate(for: part)
                results.append(FatigueResult(bodyPart: part, currentFatigue: totalFatigue, hoursToRecover: hoursToRecover))
            }
        }
        
        return results.sorted { $0.currentFatigue > $1.currentFatigue }
    }
    
    private static func baseCapacity(for part: BodyPart, userWeight: Double) -> Double {
        let w = userWeight > 0 ? userWeight : 70.0
        switch part {
        case .legs, .fullBody: return w * 60
        case .back: return w * 50
        case .chest, .shoulders: return w * 40
        case .core: return w * 30
        case .biceps, .triceps, .forearms: return w * 20
        default: return 0
        }
    }
    
    private static func decayRate(for part: BodyPart) -> Double {
        // Returns % decay per hour
        switch part {
        case .legs, .back, .fullBody: 
            return 25.0 / 24.0 // 1.04% per hour
        case .chest, .shoulders: 
            return 33.3 / 24.0 // 1.38% per hour
        case .biceps, .triceps, .forearms, .core: 
            return 50.0 / 24.0 // 2.08% per hour
        default: 
            return 100.0 // Instant recovery
        }
    }
}
