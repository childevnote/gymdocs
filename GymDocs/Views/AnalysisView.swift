import SwiftUI
import SwiftData
import Charts

struct AnalysisView: View {
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var allRecords: [WorkoutRecord]
    @AppStorage("userWeight") private var userWeight = 70.0
    
    @State private var displayLimit = 10
    
    var body: some View {
        NavigationStack {
            List {
                // 1. Weekly Chart Section
                Section {
                    weeklyChartView
                } header: {
                    Text("주간 볼륨 & 강도")
                }
                
                // 2. Fatigue & Recovery Section
                if !fatigueResults.isEmpty {
                    Section {
                        fatigueView
                    } header: {
                        Text("부위별 회복 상태")
                    }
                }
                
                // 3. History List Section (Toss Style)
                Section {
                    historyListView
                    
                    if displayLimit < allRecords.count {
                        Button {
                            displayLimit += 10
                        } label: {
                            Text("더보기")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.hapticPress)
                        .foregroundStyle(.blue)
                    }
                } header: {
                    Text("최근 운동 기록")
                }
            }
            .navigationTitle(String(localized: "tab.analysis", defaultValue: "분석"))
        }
    }
    
    // MARK: - Weekly Chart
    
    private var weeklyChartView: some View {
        // Group by week
        let calendar = Calendar.current
        var weeklyData: [Date: (volume: Double, intensity: Double)] = [:]
        
        // Take records from the past 12 weeks for the chart
        let twelveWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -12, to: Date()) ?? Date()
        
        for record in allRecords where record.date >= twelveWeeksAgo {
            // Find the start of the week for this record
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: record.date)
            if let weekStart = calendar.date(from: comps) {
                weeklyData[weekStart, default: (0, 0)].volume += record.totalVolume
                weeklyData[weekStart, default: (0, 0)].intensity += record.intensityScore
            }
        }
        
        let sortedWeeks = weeklyData.keys.sorted()
        
        return VStack(alignment: .leading, spacing: 16) {
            if sortedWeeks.isEmpty {
                Text("최근 12주간 기록이 없습니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(sortedWeeks, id: \.self) { week in
                        let data = weeklyData[week]!
                        
                        // Volume Line
                        LineMark(
                            x: .value("Week", week, unit: .weekOfYear),
                            y: .value("Volume", data.volume)
                        )
                        .foregroundStyle(.blue)
                        .symbol(Circle())
                        
                        // Intensity Line
                        LineMark(
                            x: .value("Week", week, unit: .weekOfYear),
                            y: .value("Intensity", data.intensity)
                        )
                        .foregroundStyle(.orange)
                        .symbol(Square())
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { value in
                        if let date = value.as(Date.self) {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "M/d"
                            AxisValueLabel(formatter.string(from: date))
                        }
                    }
                }
                .frame(height: 200)
                .padding(.top, 8)
                
                // Legend
                HStack {
                    Circle().fill(.blue).frame(width: 8, height: 8)
                    Text("볼륨 (Volume)").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Square().fill(.orange).frame(width: 8, height: 8)
                    Text("강도 (Intensity)").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
            }
        }
    }
    
    // MARK: - Fatigue View
    
    private var fatigueResults: [FatigueResult] {
        FatigueCalculator.calculate(records: allRecords, userWeight: userWeight)
    }
    
    private var fatigueView: some View {
        ForEach(fatigueResults) { result in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(result.bodyPart.displayName)
                        .font(.headline)
                    Spacer()
                    Text("회복까지 \(Int(ceil(result.hoursToRecover)))시간")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(fatigueColor(for: result.currentFatigue))
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(result.currentFatigue / 100))))
                    }
                }
                .frame(height: 8)
            }
            .padding(.vertical, 6)
        }
    }
    
    private func fatigueColor(for value: Double) -> Color {
        if value > 75 { return .red }
        if value > 40 { return .orange }
        return .green
    }
    
    // MARK: - History List
    
    private var historyListView: some View {
        let displayed = allRecords.prefix(displayLimit)
        
        // Group by Date
        let grouped = Dictionary(grouping: displayed) { Calendar.current.startOfDay(for: $0.date) }
        let sortedDates = grouped.keys.sorted(by: >)
        
        return ForEach(sortedDates, id: \.self) { date in
            VStack(alignment: .leading, spacing: 12) {
                Text(dateFormatter.string(from: date))
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                
                ForEach(grouped[date] ?? []) { record in
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.exercise?.localizedName ?? "알 수 없음")
                                .font(.body)
                                .fontWeight(.semibold)
                            
                            let setStr = record.sets.filter { $0.isCompleted }.count
                            Text("\(setStr)세트 완료")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Int(record.totalVolume)) kg")
                                .font(.subheadline)
                                .bold()
                            
                            Text("\(Int(record.intensityScore)) SR")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Divider()
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .listRowSeparator(.hidden)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }
}

// Simple Square shape for legend
struct Square: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        return path
    }
}
