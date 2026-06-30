import Foundation

struct CSVExporter {
    static func generateCSVURLs(routines: [Routine], records: [WorkoutRecord]) -> [URL]? {
        let fileManager = FileManager.default
        var generatedURLs: [URL] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let header = "Date,Exercise,Type,Completed Sets,Total Volume,Intensity Score\n"
        
        // Routine -> [WorkoutRecord]
        var routineRecords: [Routine: [WorkoutRecord]] = [:]
        for routine in routines {
            let exerciseIds = Set(routine.exercises.compactMap { $0.exercise?.id })
            let matchingRecords = records.filter { record in
                guard let exId = record.exercise?.id else { return false }
                return exerciseIds.contains(exId)
            }.sorted { $0.date > $1.date }
            
            routineRecords[routine] = matchingRecords
        }
        
        // Identify records not in ANY routine
        let allRoutineExerciseIds = Set(routines.flatMap { $0.exercises.compactMap { $0.exercise?.id } })
        let otherRecords = records.filter { record in
            guard let exId = record.exercise?.id else { return true }
            return !allRoutineExerciseIds.contains(exId)
        }.sorted { $0.date > $1.date }
        
        func writeCSV(name: String, records: [WorkoutRecord]) {
            if records.isEmpty { return }
            var csvString = header
            for record in records {
                let dateStr = dateFormatter.string(from: record.date)
                // escape commas just in case
                let exName = "\"\(record.exercise?.localizedName.replacingOccurrences(of: "\"", with: "\"\"") ?? "Unknown")\""
                let typeName = record.exercise?.type.displayName ?? ""
                let setCount = record.sets.filter { $0.isCompleted }.count
                let volume = String(format: "%.1f", record.totalVolume)
                let intensity = String(format: "%.1f", record.intensityScore)
                
                csvString += "\(dateStr),\(exName),\(typeName),\(setCount),\(volume),\(intensity)\n"
            }
            
            let safeName = name.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "-")
            let fileName = "\(safeName)_Data.csv"
            let tempURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                // write with BOM for Excel to open UTF-8 correctly
                var data = Data([0xEF, 0xBB, 0xBF]) 
                if let strData = csvString.data(using: .utf8) {
                    data.append(strData)
                    try data.write(to: tempURL, options: .atomic)
                    generatedURLs.append(tempURL)
                }
            } catch {
                print("Failed to write CSV: \(error)")
            }
        }
        
        for (routine, matchedRecords) in routineRecords {
            writeCSV(name: routine.name, records: matchedRecords)
        }
        
        writeCSV(name: "Other_Exercises", records: otherRecords)
        
        return generatedURLs.isEmpty ? nil : generatedURLs
    }
}
