import Foundation

// MARK: - Fitness Advice

struct FitnessAdvice: Identifiable {
    let id = UUID()
    let category: AdviceCategory
    let title: String
    let detail: String
    let intensity: RecommendedIntensity
    let suggestedWorkouts: [WorkoutType]
}

enum AdviceCategory: String {
    case readyToGo = "适合运动"
    case lightOnly = "适合轻度活动"
    case restDay = "建议休息"
    case recovery = "恢复中"
    
    var icon: String {
        switch self {
        case .readyToGo: return "flame.fill"
        case .lightOnly: return "leaf.fill"
        case .restDay: return "moon.fill"
        case .recovery: return "heart.fill"
        }
    }
    
    var colorName: String {
        switch self {
        case .readyToGo: return "green"
        case .lightOnly: return "yellow"
        case .restDay: return "blue"
        case .recovery: return "purple"
        }
    }
}

enum RecommendedIntensity: Int, Comparable {
    case rest = 0
    case light = 1      // 散步、拉伸
    case moderate = 2   // 慢跑、瑜伽
    case high = 3       // HIIT、球类、重训
    case intense = 4    // 竞技、长距离
    
    static func < (lhs: RecommendedIntensity, rhs: RecommendedIntensity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var displayName: String {
        switch self {
        case .rest: return "完全休息"
        case .light: return "轻度"
        case .moderate: return "中等"
        case .high: return "高强度"
        case .intense: return "高强度竞技"
        }
    }
}
