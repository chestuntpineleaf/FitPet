import SwiftUI

@main
struct FitPetApp: App {
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var petManager = PetManager()
    @StateObject private var advisorEngine = FitnessAdvisorEngine()
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(healthManager)
                    .environmentObject(petManager)
                    .environmentObject(advisorEngine)
                    .task {
                        await healthManager.checkAndRequestIfNeeded()
                        await healthManager.fetchTodayData()
                        advisorEngine.analyze(healthData: healthManager.todayData)
                        petManager.updateAppearance(for: healthManager.todayData.latestWorkoutType)
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(healthManager)
            }
        }
    }
}
