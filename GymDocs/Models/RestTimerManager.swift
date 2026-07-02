import Foundation
import ActivityKit

@Observable
final class RestTimerManager {
    static let shared = RestTimerManager()
    
    var isRunning = false
    var elapsedSeconds: Int = 0
    var activeSetId: UUID?
    
    private var timer: Timer?
    private var startDate: Date?
    private var activity: Activity<RestTimerAttributes>?
    
    private let runningKey = "RestTimerManager_isRunning"
    private let startDateKey = "RestTimerManager_startDate"
    private let activeSetIdKey = "RestTimerManager_activeSetId"
    
    private init() {
        if UserDefaults.standard.bool(forKey: runningKey),
           let start = UserDefaults.standard.object(forKey: startDateKey) as? Date,
           let idString = UserDefaults.standard.string(forKey: activeSetIdKey),
           let setId = UUID(uuidString: idString) {
            
            self.isRunning = true
            self.startDate = start
            self.activeSetId = setId
            self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self, let st = self.startDate else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(st))
            }
        }
    }
    
    func start(for setId: UUID) {
        stop()
        activeSetId = setId
        isRunning = true
        elapsedSeconds = 0
        startDate = Date()
        
        UserDefaults.standard.set(true, forKey: runningKey)
        UserDefaults.standard.set(startDate, forKey: startDateKey)
        UserDefaults.standard.set(setId.uuidString, forKey: activeSetIdKey)
        
        if let st = startDate {
            startLiveActivity(startDate: st)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let start = self.startDate else { return }
            self.elapsedSeconds = Int(Date().timeIntervalSince(start))
        }
    }
    
    func stop() -> Int {
        timer?.invalidate()
        timer = nil
        let elapsed = elapsedSeconds
        isRunning = false
        elapsedSeconds = 0
        activeSetId = nil
        startDate = nil
        
        UserDefaults.standard.removeObject(forKey: runningKey)
        UserDefaults.standard.removeObject(forKey: startDateKey)
        UserDefaults.standard.removeObject(forKey: activeSetIdKey)
        
        stopLiveActivity()
        
        return elapsed
    }
    
    func toggle(for setId: UUID, onStop: (Int) -> Void) {
        if isRunning && activeSetId == setId {
            let elapsed = stop()
            onStop(elapsed)
        } else {
            start(for: setId)
        }
    }
    
    private func startLiveActivity(startDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = RestTimerAttributes()
        let state = RestTimerAttributes.ContentState(startDate: startDate)
        let content = ActivityContent(state: state, staleDate: nil)
        
        do {
            self.activity = try Activity.request(attributes: attributes, content: content)
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    private func stopLiveActivity() {
        guard let activity = self.activity else { return }
        let state = RestTimerAttributes.ContentState(startDate: startDate ?? Date())
        let content = ActivityContent(state: state, staleDate: nil)
        
        Task {
            await activity.end(content, dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}
