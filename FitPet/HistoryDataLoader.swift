import Foundation
import HealthKit

@MainActor
class HistoryDataLoader: ObservableObject {
    private let store = HKHealthStore()
    
    @Published var weeklyData: [DailyRecord] = []
    @Published var isLoading = false
    
    func loadData(for period: TimePeriod) async {
        isLoading = true
        let calendar = Calendar.current
        let now = Date()
        let daysBack = period.days
        
        var records: [DailyRecord] = []
        
        for dayOffset in 0..<daysBack {
            let date = calendar.date(byAdding: .day, value: -(daysBack - 1 - dayOffset), to: now)!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
            
            async let steps = fetchDaySteps(predicate: predicate)
            async let sleep = fetchDaySleep(startOfDay: startOfDay)
            async let workouts = fetchDayWorkouts(predicate: predicate)
            
            let (s, sl, w) = await (steps, sleep, workouts)
            
            let recovery = calculateRecovery(sleep: sl)
            
            records.append(DailyRecord(
                date: date,
                steps: s,
                sleepHours: sl,
                recoveryScore: recovery,
                workoutTypes: w
            ))
        }
        
        weeklyData = records
        isLoading = false
    }
    
    private func calculateRecovery(sleep: Double) -> Int {
        var score = 50
        if sleep >= 7 && sleep <= 9 { score += 30 }
        else if sleep >= 6 { score += 15 }
        else if sleep < 5 { score -= 15 }
        return max(0, min(100, score))
    }
    
    private func fetchDaySteps(predicate: NSPredicate) async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(value))
            }
            store.execute(query)
        }
    }
    
    private func fetchDaySleep(startOfDay: Date) async -> Double {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let previousEvening = Calendar.current.date(byAdding: .hour, value: -6, to: startOfDay)!
        let nextMorning = Calendar.current.date(byAdding: .hour, value: 12, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: previousEvening, end: nextMorning, options: .strictStartDate)
        
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
    
    private func fetchDayWorkouts(predicate: NSPredicate) async -> [WorkoutType] {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let types = (samples as? [HKWorkout])?.map { workout in
                    WorkoutType.from(hkType: workout.workoutActivityType)
                } ?? []
                continuation.resume(returning: types)
            }
            store.execute(query)
        }
    }
}
