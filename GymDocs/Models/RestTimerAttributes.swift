import Foundation
import ActivityKit

public struct RestTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var startDate: Date
        
        public init(startDate: Date) {
            self.startDate = startDate
        }
    }

    public init() {}
}
