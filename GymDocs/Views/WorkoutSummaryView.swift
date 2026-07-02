import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let records: [WorkoutRecord]
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var shareImage: UIImage? = nil
    @State private var showShareSheet = false
    
    private var totalVolume: Double {
        records.reduce(0) { $0 + $1.totalVolume }
    }
    
    private var totalIntensity: Double {
        records.reduce(0) { $0 + $1.intensityScore }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color(hex: "FFD52E"))
                            .padding(.top, 40)
                        
                        Text("운동 완료!")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(.primary)
                        
                        Text(getEncouragingMessage())
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Stats Box
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("총 볼륨")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(String(format: "%.1f", totalVolume)) kg")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider().frame(height: 40)
                        
                        VStack(spacing: 4) {
                            Text("운동 강도")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(String(format: "%.1f", totalIntensity))")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 20)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 24)
                    
                    // Exercise List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("오늘 한 운동")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        
                        VStack(spacing: 0) {
                            ForEach(records) { record in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(record.exercise?.localizedName ?? "알 수 없음")
                                            .font(.body)
                                            .bold()
                                        Text("\(record.sets.filter{ $0.isCompleted }.count)세트")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(String(format: "%.1f", record.totalVolume)) kg")
                                            .font(.subheadline)
                                            .bold()
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                
                                if record.id != records.last?.id {
                                    Divider()
                                        .padding(.leading, 24)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 100) // Space for button
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                // 진입 시 애니메이션 및 강한 햅틱 피드백
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
            
            // Buttons
            HStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Text("확인")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.hapticPress)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())
                
                Button {
                    generateAndShareImage()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("자랑하기")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.hapticPress)
                .background(Color(hex: "FFD52E"))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheet(activityItems: [img])
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    @MainActor
    private func generateAndShareImage() {
        let viewToRender = ShareWorkoutView(records: records)
        let renderer = ImageRenderer(content: viewToRender)
        renderer.scale = 3.0 // High quality
        
        if let uiImage = renderer.uiImage {
            self.shareImage = uiImage
            self.showShareSheet = true
        }
    
    private func getEncouragingMessage() -> String {
        let messages = [
            "오늘도 해냈네요! 정말 대단합니다. 👏",
            "점점 더 강해지고 있어요. 꾸준함이 정답입니다! 💪",
            "포기하지 않고 끝까지 해낸 자신을 칭찬해주세요. 🔥",
            "어제보다 한 걸음 더 나아간 멋진 하루입니다. ✨",
            "당신의 노력이 땀방울이 되어 근육에 새겨졌습니다! 🏋️‍♂️"
        ]
        return messages.randomElement() ?? messages[0]
    }
}

// MARK: - Share Image View
struct ShareWorkoutView: View {
    let records: [WorkoutRecord]
    
    private var totalVolume: Double { records.reduce(0) { $0 + $1.totalVolume } }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("GymDocs 🏆")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "FFD52E"))
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY's VOLUME")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(String(format: "%.1f", totalVolume)) kg")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(records.prefix(5)) { record in
                    HStack {
                        Text(record.exercise?.localizedName ?? "")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.white)
                        Spacer(minLength: 16)
                        Text("\(record.sets.filter{ $0.isCompleted }.count) Sets")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                if records.count > 5 {
                    Text("+ \(records.count - 5) more exercises")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 4)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
        .padding(32)
        .background(
            LinearGradient(colors: [Color(hex: "1C1C1E"), Color(hex: "2C2C2E")], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(24)
        .frame(width: 350)
    }
}
