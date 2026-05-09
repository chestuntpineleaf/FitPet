import Foundation

@MainActor
class FitnessAdvisorEngine: ObservableObject {
    @Published var todayAdvice: FitnessAdvice?
    @Published var detailReasons: [String] = []
    
    func analyze(healthData: TodayHealthData) {
        let recovery = healthData.recoveryScore
        let sleep = healthData.sleepHours
        let hrv = healthData.hrv
        let recentWorkoutLoad = calculateRecentLoad(workouts: healthData.workouts)
        
        let advice: FitnessAdvice
        var reasons: [String] = []
        
        if recovery >= 80 && sleep >= 7 {
            reasons.append("恢复评分 \(recovery)/100，状态极佳")
            reasons.append("睡眠 \(String(format: "%.1f", sleep)) 小时，充分恢复")
            if hrv > 50 { reasons.append("HRV \(Int(hrv))ms，自主神经平衡良好") }
            
            advice = FitnessAdvice(
                category: .readyToGo,
                title: "今天状态很好，适合运动！",
                detail: "你的身体恢复充分，可以进行中高强度训练",
                intensity: recentWorkoutLoad > 3 ? .moderate : .high,
                suggestedWorkouts: suggestWorkouts(intensity: .high, recent: healthData.workouts)
            )
        } else if recovery >= 60 {
            reasons.append("恢复评分 \(recovery)/100，状态尚可")
            if sleep < 7 { reasons.append("睡眠 \(String(format: "%.1f", sleep)) 小时，略有不足") }
            if hrv > 0 && hrv < 40 { reasons.append("HRV 偏低，压力可能较大") }
            
            advice = FitnessAdvice(
                category: .lightOnly,
                title: "适合轻中度活动",
                detail: "身体还在恢复中，建议选择轻松的运动方式",
                intensity: .moderate,
                suggestedWorkouts: suggestWorkouts(intensity: .moderate, recent: healthData.workouts)
            )
        } else if recovery >= 40 {
            reasons.append("恢复评分 \(recovery)/100，身体需要恢复")
            if sleep < 6 { reasons.append("睡眠不足 6 小时，请多休息") }
            if hrv > 0 && hrv < 25 { reasons.append("HRV 较低，身体压力较大") }
            
            advice = FitnessAdvice(
                category: .recovery,
                title: "今天以恢复为主",
                detail: "建议做些拉伸或散步，不要高强度训练",
                intensity: .light,
                suggestedWorkouts: [.yoga, .hiking]
            )
        } else {
            reasons.append("恢复评分 \(recovery)/100，身体亮红灯")
            if sleep < 5 { reasons.append("严重睡眠不足") }
            reasons.append("建议今天完全休息")
            
            advice = FitnessAdvice(
                category: .restDay,
                title: "今天休息一下吧",
                detail: "你的身体需要恢复，好好休息明天会更好",
                intensity: .rest,
                suggestedWorkouts: []
            )
        }
        
        self.todayAdvice = advice
        self.detailReasons = reasons
    }
    
    private func calculateRecentLoad(workouts: [WorkoutRecord]) -> Int {
        let totalMinutes = workouts.reduce(0) { $0 + $1.durationMinutes }
        let intensityWeightedLoad = workouts.reduce(0) { result, record in
            result + record.durationMinutes * record.type.intensityLevel
        }
        if totalMinutes > 120 { return 5 }
        if intensityWeightedLoad > 200 { return 4 }
        if totalMinutes > 60 { return 3 }
        if totalMinutes > 30 { return 2 }
        return workouts.count
    }
    
    private func suggestWorkouts(intensity: RecommendedIntensity, recent: [WorkoutRecord]) -> [WorkoutType] {
        let recentTypes = Set(recent.map(\.type))
        
        switch intensity {
        case .high, .intense:
            let options: [WorkoutType] = [.running, .cycling, .swimming, .badminton, .gym, .basketball, .soccer, .tennis]
            return options.filter { !recentTypes.contains($0) }.shuffled().prefix(3).map { $0 }
        case .moderate:
            let options: [WorkoutType] = [.yoga, .cycling, .hiking, .dancing, .swimming]
            return options.filter { !recentTypes.contains($0) }.shuffled().prefix(3).map { $0 }
        case .light:
            return [.yoga, .hiking]
        case .rest:
            return []
        }
    }
    
    func weeklyInsight(weekData: [DailyRecord]) -> String {
        let avgSteps = weekData.map(\.steps).reduce(0, +) / max(weekData.count, 1)
        let avgSleep = weekData.map(\.sleepHours).reduce(0, +) / Double(max(weekData.count, 1))
        let totalWorkouts = weekData.flatMap(\.workoutTypes).count
        
        var insights: [String] = []
        
        if avgSteps < 5000 {
            insights.append("本周平均步数偏低，试着每天多走2000步")
        } else if avgSteps > 10000 {
            insights.append("本周步数非常棒！保持住！")
        }
        
        if avgSleep < 6.5 {
            insights.append("睡眠不足会影响恢复，建议提前30分钟上床")
        }
        
        if totalWorkouts == 0 {
            insights.append("本周还没有运动记录，选一个喜欢的运动开始吧")
        } else if totalWorkouts >= 5 {
            insights.append("本周运动\(totalWorkouts)次，注意安排休息日")
        }
        
        return insights.joined(separator: "；")
    }
}
