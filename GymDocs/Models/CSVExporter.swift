import Foundation

struct ExcelExporter {
    static func generateExcelXML(routines: [Routine], records: [WorkoutRecord]) -> URL? {
        let fileManager = FileManager.default
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var xmlString = """
        <?xml version="1.0"?>
        <?mso-application progid="Excel.Sheet"?>
        <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
         xmlns:o="urn:schemas-microsoft-com:office:office"
         xmlns:x="urn:schemas-microsoft-com:office:excel"
         xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
         xmlns:html="http://www.w3.org/TR/REC-html40">
        """
        
        // Helper func to escape XML characters
        func escapeXML(_ string: String) -> String {
            return string.replacingOccurrences(of: "&", with: "&amp;")
                         .replacingOccurrences(of: "<", with: "&lt;")
                         .replacingOccurrences(of: ">", with: "&gt;")
                         .replacingOccurrences(of: "\"", with: "&quot;")
                         .replacingOccurrences(of: "'", with: "&apos;")
        }
        
        // Helper func to append a worksheet
        func appendWorksheet(name: String, records: [WorkoutRecord]) {
            if records.isEmpty { return }
            let safeName = escapeXML(name)
            xmlString += "\n <Worksheet ss:Name=\"\(safeName)\">"
            xmlString += "\n  <Table>"
            
            // Header
            xmlString += """
            
               <Row>
                <Cell><Data ss:Type="String">Date</Data></Cell>
                <Cell><Data ss:Type="String">Exercise</Data></Cell>
                <Cell><Data ss:Type="String">Type</Data></Cell>
                <Cell><Data ss:Type="String">Completed Sets</Data></Cell>
                <Cell><Data ss:Type="String">Total Volume(kg)</Data></Cell>
                <Cell><Data ss:Type="String">Intensity Score</Data></Cell>
               </Row>
            """
            
            for record in records {
                let dateStr = dateFormatter.string(from: record.date)
                let exName = escapeXML(record.exercise?.localizedName ?? "Unknown")
                let typeName = escapeXML(record.exercise?.type.displayName ?? "")
                let setCount = record.sets.filter { $0.isCompleted }.count
                let volume = String(format: "%.1f", record.totalVolume)
                let intensity = String(format: "%.1f", record.intensityScore)
                
                xmlString += """
                
                   <Row>
                    <Cell><Data ss:Type="String">\(dateStr)</Data></Cell>
                    <Cell><Data ss:Type="String">\(exName)</Data></Cell>
                    <Cell><Data ss:Type="String">\(typeName)</Data></Cell>
                    <Cell><Data ss:Type="Number">\(setCount)</Data></Cell>
                    <Cell><Data ss:Type="Number">\(volume)</Data></Cell>
                    <Cell><Data ss:Type="Number">\(intensity)</Data></Cell>
                   </Row>
                """
            }
            
            xmlString += "\n  </Table>"
            xmlString += "\n </Worksheet>"
        }
        
        // 1. Routine -> [WorkoutRecord]
        var routineRecords: [Routine: [WorkoutRecord]] = [:]
        for routine in routines {
            let exerciseIds = Set(routine.exercises.compactMap { $0.exercise?.id })
            let matchingRecords = records.filter { record in
                guard let exId = record.exercise?.id else { return false }
                return exerciseIds.contains(exId)
            }.sorted { $0.date > $1.date }
            
            routineRecords[routine] = matchingRecords
        }
        
        // 2. Identify records not in ANY routine
        let allRoutineExerciseIds = Set(routines.flatMap { $0.exercises.compactMap { $0.exercise?.id } })
        let otherRecords = records.filter { record in
            guard let exId = record.exercise?.id else { return true }
            return !allRoutineExerciseIds.contains(exId)
        }.sorted { $0.date > $1.date }
        
        // Build worksheets
        for (routine, matchedRecords) in routineRecords {
            // Excel sheet names max length is 31 and shouldn't contain certain chars, but we keep it simple here.
            let sheetName = String(routine.name.prefix(31)).replacingOccurrences(of: "/", with: "-")
            appendWorksheet(name: sheetName, records: matchedRecords)
        }
        appendWorksheet(name: "Other_Exercises", records: otherRecords)
        
        xmlString += "\n</Workbook>"
        
        if routineRecords.values.allSatisfy({ $0.isEmpty }) && otherRecords.isEmpty {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let fileName = "GymDocs_Export_\(formatter.string(from: Date())).xml"
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try xmlString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to write Excel XML: \(error)")
            return nil
        }
    }
}
