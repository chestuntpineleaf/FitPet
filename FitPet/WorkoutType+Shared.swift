import Foundation

extension WorkoutType {
    var intensityLevel: Int {
        switch self {
        case .none: return 0
        case .yoga, .hiking: return 1
        case .cycling, .swimming, .dancing: return 2
        case .running, .badminton, .tennis, .gym: return 3
        case .basketball, .soccer, .skiing: return 4
        case .other: return 2
        }
    }
    
    var estimatedCaloriesPerMinute: Double {
        switch self {
        case .none: return 0
        case .yoga: return 3
        case .hiking: return 5
        case .cycling: return 7
        case .swimming: return 8
        case .dancing: return 6
        case .running: return 10
        case .badminton: return 7
        case .tennis: return 8
        case .gym: return 6
        case .basketball: return 8
        case .soccer: return 9
        case .skiing: return 9
        case .other: return 5
        }
    }
}
