import Foundation

@Observable
final class RestTimerManager {
    static let shared = RestTimerManager()
    
    var isRunning = false
    var elapsedSeconds: Int = 0
    var activeSetId: UUID?
    
    private var timer: Timer?
    private var startDate: Date?
    
    private init() {}
    
    func start(for setId: UUID) {
        stop()
        activeSetId = setId
        isRunning = true
        elapsedSeconds = 0
        startDate = Date()
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
}
