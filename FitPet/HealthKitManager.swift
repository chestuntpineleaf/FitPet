import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()
    
    @Published var todayData = TodayHealthData()
    @Published var isAuthorized = false
    
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
    
    @Published var authorizationError: String?
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationError = "此设备不支持 HealthKit"
            return
        }
        
        do {
            try await store.requestAuthorization(toShare: Set<HKSampleType>(), read: readTypes)
            isAuthorized = true
            authorizationError = nil
        } catch {
            authorizationError = "授权失败: \(error.localizedDescription)"
            print("HealthKit authorization failed: \(error)")
        }
    }
    
    func checkAndRequestIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = store.authorizationStatus(for: stepType)
        
        if status == .notDetermined {
            await requestAuthorization()
        } else {
            isAuthorized = true
        }
    }
    
    func fetchTodayData() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        async let steps = fetchSteps(predicate: predicate)
        async let heartRate = fetchLatestHeartRate()
        async let restingHR = fetchRestingHeartRate()
        async let hrv = fetchHRV()
        async let sleep = fetchSleepHours()
        async let calories = fetchActiveCalories(predicate: predicate)
        async let workouts = fetchTodayWorkouts(predicate: predicate)
        
        let (s, hr, rhr, h, sl, cal, w) = await (steps, heartRate, restingHR, hrv, sleep, calories, workouts)
        
        todayData = TodayHealthData(
            steps: s,
            heartRate: hr,
            restingHeartRate: rhr,
            hrv: h,
            sleepHours: sl,
            activeCalories: cal,
            latestWorkoutType: w.last?.type ?? .none,
            workouts: w,
            date: now
        )
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
    
    private func fetchLatestHeartRate() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return 0 }
        return await fetchLatestQuantity(type: type, unit: HKUnit.count().unitDivided(by: .minute()))
    }
    
    private func fetchRestingHeartRate() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return 0 }
        return await fetchLatestQuantity(type: type, unit: HKUnit.count().unitDivided(by: .minute()))
    }
    
    private func fetchHRV() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return 0 }
        return await fetchLatestQuantity(type: type, unit: .secondUnit(with: .milli))
    }
    
    private func fetchLatestQuantity(type: HKQuantityType, unit: HKUnit) async -> Double {
        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
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
        let yesterdayEvening = calendar.date(byAdding: .hour, value: -12, to: calendar.startOfDay(for: now))!
        let predicate = HKQuery.predicateForSamples(withStart: yesterdayEvening, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let totalSeconds = (samples as? [HKCategorySample])?.reduce(0.0) { result, sample in
                    guard sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                          sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    else { return result }
                    return result + sample.endDate.timeIntervalSince(sample.startDate)
                } ?? 0
                continuation.resume(returning: totalSeconds / 3600.0)
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
    
    private func fetchTodayWorkouts(predicate: NSPredicate) async -> [WorkoutRecord] {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let records = (samples as? [HKWorkout])?.map { workout in
                    WorkoutRecord(
                        type: WorkoutType.from(hkType: workout.workoutActivityType),
                        duration: workout.duration,
                        calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        date: workout.startDate
                    )
                } ?? []
                continuation.resume(returning: records)
            }
            store.execute(query)
        }
    }
}
