import SwiftUI
import HealthKit
import Foundation

@MainActor
class WatchViewModel: ObservableObject {
    private let store = HKHealthStore()
    
    @Published var petName = "小元"
    @Published var petLevel = 1
    @Published var petMoodEmoji = "😊"
    @Published var outfitEmoji = "😴"
    @Published var motivationMessage = "今天也一起加油吧！"
    
    @Published var steps = 0
    @Published var heartRate = 0
    @Published var sleepHours: Double = 0
    @Published var recoveryScore = 50
    @Published var activeCalories = 0
    @Published var latestWorkoutEmoji = ""
    
    @Published var adviceIcon = "leaf.fill"
    @Published var adviceTitle = "加载中..."
    @Published var adviceDetail = ""
    @Published var adviceColor: Color = .green
    
    private let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        if let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) { types.insert(stepCount) }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) { types.insert(heartRate) }
        if let restingHR = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) { types.insert(restingHR) }
        if let hrv = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(energy) }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        types.insert(HKObjectType.workoutType())
        return types
    }()
    
    init() {
        Task { await requestAuthAndFetch() }
    }
    
    func requestAuthAndFetch() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            await fetchAllData()
        } catch {
            print("Watch HealthKit auth failed: \(error)")
        }
    }
    
    func fetchAllData() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        async let s = fetchSteps(predicate: predicate)
        async let hr = fetchLatestQuantity(identifier: .heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let rhr = fetchLatestQuantity(identifier: .restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let h = fetchLatestQuantity(identifier: .heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
        async let sl = fetchSleepHours()
        async let cal = fetchActiveCalories(predicate: predicate)
        async let w = fetchLatestWorkoutEmoji(predicate: predicate)
        
        let (stepsVal, hrVal, rhrVal, hrvVal, sleepVal, calVal, workoutEmoji) = await (s, hr, rhr, h, sl, cal, w)
        
        steps = stepsVal
        heartRate = Int(hrVal)
        sleepHours = sleepVal
        activeCalories = Int(calVal)
        latestWorkoutEmoji = workoutEmoji
        recoveryScore = calculateRecovery(hrv: hrvVal, sleep: sleepVal, restingHR: rhrVal)
        updateAdvice()
    }
    
    private func calculateRecovery(hrv: Double, sleep: Double, restingHR: Double) -> Int {
        var score = 50
        if hrv > 60 { score += 20 }
        else if hrv > 40 { score += 10 }
        else if hrv < 20 { score -= 10 }
        
        if sleep >= 7 && sleep <= 9 { score += 20 }
        else if sleep >= 6 { score += 10 }
        else { score -= 15 }
        
        if restingHR > 0 {
            if restingHR < 60 { score += 10 }
            else if restingHR > 80 { score -= 10 }
        }
        return max(0, min(100, score))
    }
    
    private func updateAdvice() {
        if recoveryScore >= 80 {
            adviceIcon = "flame.fill"
            adviceTitle = "状态很好，适合运动！"
            adviceDetail = "可以进行中高强度训练"
            adviceColor = .green
        } else if recoveryScore >= 60 {
            adviceIcon = "leaf.fill"
            adviceTitle = "适合轻中度活动"
            adviceDetail = "建议瑜伽、骑行或散步"
            adviceColor = .yellow
        } else if recoveryScore >= 40 {
            adviceIcon = "heart.fill"
            adviceTitle = "以恢复为主"
            adviceDetail = "拉伸或轻度散步即可"
            adviceColor = .purple
        } else {
            adviceIcon = "moon.fill"
            adviceTitle = "今天休息一下吧"
            adviceDetail = "好好休息明天会更好"
            adviceColor = .blue
        }
    }
    
    private func fetchSteps(predicate: NSPredicate) async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(value))
            }
            store.execute(query)
        }
    }
    
    private func fetchLatestQuantity(identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
    
    private func fetchSleepHours() async -> Double {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(byAdding: .hour, value: -12, to: calendar.startOfDay(for: now))!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let total = (samples as? [HKCategorySample])?.reduce(0.0) { result, sample in
                    guard sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    else { return result }
                    return result + sample.endDate.timeIntervalSince(sample.startDate)
                } ?? 0
                continuation.resume(returning: total / 3600.0)
            }
            store.execute(query)
        }
    }
    
    private func fetchActiveCalories(predicate: NSPredicate) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
    
    private func fetchLatestWorkoutEmoji(predicate: NSPredicate) async -> String {
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                if let workout = samples?.first as? HKWorkout {
                    let emoji: String
                    switch workout.workoutActivityType {
                    case .running, .walking: emoji = "🏃"
                    case .cycling: emoji = "🚴"
                    case .swimming: emoji = "🏊"
                    case .badminton: emoji = "🏸"
                    case .downhillSkiing, .crossCountrySkiing, .snowboarding: emoji = "⛷️"
                    case .traditionalStrengthTraining, .functionalStrengthTraining: emoji = "🏋️"
                    case .yoga, .pilates: emoji = "🧘"
                    case .hiking: emoji = "🥾"
                    case .basketball: emoji = "🏀"
                    case .soccer: emoji = "⚽"
                    case .tennis: emoji = "🎾"
                    case .dance: emoji = "💃"
                    default: emoji = "🏅"
                    }
                    continuation.resume(returning: emoji)
                } else {
                    continuation.resume(returning: "")
                }
            }
            store.execute(query)
        }
    }
}
