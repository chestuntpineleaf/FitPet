import Foundation
import HealthKit

// MARK: - Today's Health Summary

struct TodayHealthData {
    var steps: Int = 0
    var heartRate: Double = 0          // bpm (latest)
    var restingHeartRate: Double = 0   // bpm
    var hrv: Double = 0                // ms (SDNN)
    var sleepHours: Double = 0         // last night
    var activeCalories: Double = 0
    var latestWorkoutType: WorkoutType = .none
    var workouts: [WorkoutRecord] = []
    var date: Date = .now
    
    /// Recovery score (0-100) based on HRV, sleep, resting HR
    var recoveryScore: Int {
        var score = 50
        
        // HRV contribution (higher = better recovery)
        if hrv > 60 { score += 20 }
        else if hrv > 40 { score += 10 }
        else if hrv < 20 { score -= 10 }
        
        // Sleep contribution
        if sleepHours >= 7 && sleepHours <= 9 { score += 20 }
        else if sleepHours >= 6 { score += 10 }
        else { score -= 15 }
        
        // Resting HR contribution (lower = better)
        if restingHeartRate > 0 {
            if restingHeartRate < 60 { score += 10 }
            else if restingHeartRate > 80 { score -= 10 }
        }
        
        return max(0, min(100, score))
    }
}

// MARK: - Workout Types (mapped from HKWorkoutActivityType)

enum WorkoutType: String, CaseIterable, Codable {
    case none = "none"
    case running = "running"
    case cycling = "cycling"
    case swimming = "swimming"
    case badminton = "badminton"
    case skiing = "skiing"
    case gym = "gym"              // strength training
    case yoga = "yoga"
    case hiking = "hiking"
    case basketball = "basketball"
    case soccer = "soccer"
    case tennis = "tennis"
    case dancing = "dancing"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .none: return "休息中"
        case .running: return "跑步"
        case .cycling: return "骑行"
        case .swimming: return "游泳"
        case .badminton: return "羽毛球"
        case .skiing: return "滑雪"
        case .gym: return "健身"
        case .yoga: return "瑜伽"
        case .hiking: return "徒步"
        case .basketball: return "篮球"
        case .soccer: return "足球"
        case .tennis: return "网球"
        case .dancing: return "舞蹈"
        case .other: return "其他运动"
        }
    }
    
    var emoji: String {
        switch self {
        case .none: return "😴"
        case .running: return "🏃"
        case .cycling: return "🚴"
        case .swimming: return "🏊"
        case .badminton: return "🏸"
        case .skiing: return "⛷️"
        case .gym: return "🏋️"
        case .yoga: return "🧘"
        case .hiking: return "🥾"
        case .basketball: return "🏀"
        case .soccer: return "⚽"
        case .tennis: return "🎾"
        case .dancing: return "💃"
        case .other: return "🏅"
        }
    }
    
    /// Map from HealthKit workout activity type
    static func from(hkType: HKWorkoutActivityType) -> WorkoutType {
        switch hkType {
        case .running, .walking: return .running
        case .cycling: return .cycling
        case .swimming: return .swimming
        case .badminton: return .badminton
        case .downhillSkiing, .crossCountrySkiing, .snowboarding: return .skiing
        case .traditionalStrengthTraining, .functionalStrengthTraining: return .gym
        case .yoga, .pilates: return .yoga
        case .hiking: return .hiking
        case .basketball: return .basketball
        case .soccer: return .soccer
        case .tennis: return .tennis
        case .dance: return .dancing
        default: return .other
        }
    }
}

// MARK: - Workout Record

struct WorkoutRecord: Identifiable {
    let id = UUID()
    let type: WorkoutType
    let duration: TimeInterval   // seconds
    let calories: Double
    let date: Date
    
    var durationMinutes: Int {
        Int(duration / 60)
    }
}
