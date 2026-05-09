import SwiftUI

struct HomeView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var petManager: PetManager
    @EnvironmentObject var advisor: FitnessAdvisorEngine
    @Binding var isTabBarVisible: Bool
    @State private var lastScrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        petHeroSection
                        adviceCard
                        statsSection
                        workoutSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { offset in
                    let delta = offset - lastScrollOffset
                    if delta < -8 {
                        isTabBarVisible = false
                    } else if delta > 8 {
                        isTabBarVisible = true
                    }
                    lastScrollOffset = offset
                }
            }
            .navigationTitle("FitPet")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await healthManager.fetchTodayData()
                advisor.analyze(healthData: healthManager.todayData)
                petManager.updateAppearance(for: healthManager.todayData.latestWorkoutType)
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.97, blue: 1.0),
                Color(red: 1.0, green: 0.97, blue: 0.98),
                Color(red: 0.98, green: 0.98, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var petHeroSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(petManager.appearance.accentColor.opacity(0.08))
                        .frame(width: 150, height: 150)
                    
                    PetAvatarView(appearance: petManager.appearance, mood: petManager.mood, size: 130, customImage: petManager.customAvatarImage)
                        .bounceOnTap()
                }
                
                VStack(spacing: 6) {
                    Text("\(petManager.state.name)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    
                    Text(petManager.appearance.motivationMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 16) {
                    MiniTag(icon: "star.fill", text: "Lv.\(petManager.state.level)", color: .orange)
                    MiniTag(icon: "flame.fill", text: "\(petManager.state.streak)天", color: .red)
                    MiniTag(icon: "heart.fill", text: "\(petManager.state.happiness)%", color: .pink)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                            .frame(height: 6)
                        Capsule()
                            .fill(Color.orange)
                            .frame(width: geo.size.width * petManager.state.levelProgress, height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 30)
            }
        }
    }
    
    private var adviceCard: some View {
        Group {
            if let advice = advisor.todayAdvice {
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(adviceColor(advice.category).opacity(0.12))
                                    .frame(width: 48, height: 48)
                                Image(systemName: advice.category.icon)
                                    .font(.title3)
                                    .foregroundStyle(adviceColor(advice.category))
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(advice.title)
                                    .font(.system(.headline, design: .rounded))
                                Text("建议强度: \(advice.intensity.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            
                            Spacer()
                            
                            RecoveryRing(score: healthManager.todayData.recoveryScore)
                                .frame(width: 46, height: 46)
                        }
                        
                        if !advice.suggestedWorkouts.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(advice.suggestedWorkouts, id: \.self) { workout in
                                        WorkoutChip(workout: workout)
                                    }
                                }
                            }
                        }
                        
                        if !advisor.detailReasons.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(advisor.detailReasons, id: \.self) { reason in
                                    HStack(spacing: 6) {
                                        Circle().fill(.green).frame(width: 4, height: 4)
                                        Text(reason)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var statsSection: some View {
        let data = healthManager.todayData
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(icon: "figure.walk", value: "\(data.steps)", label: "步数", color: .green)
                StatTile(icon: "flame.fill", value: "\(Int(data.activeCalories))", label: "千卡", color: .orange)
                StatTile(icon: "moon.fill", value: String(format: "%.1f", data.sleepHours), label: "睡眠/h", color: .indigo)
            }
            
            HStack(spacing: 12) {
                StatTile(icon: "heart.fill", value: "\(Int(data.heartRate))", label: "心率", color: .red)
                StatTile(icon: "waveform.path.ecg", value: "\(Int(data.hrv))", label: "HRV/ms", color: .purple)
                StatTile(icon: "gauge.medium", value: "\(data.recoveryScore)", label: "恢复", color: .blue)
            }
        }
    }
    
    private var workoutSection: some View {
        Group {
            if !healthManager.todayData.workouts.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "figure.run")
                                .foregroundStyle(.orange)
                            Text("今日运动")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        }
                        
                        ForEach(healthManager.todayData.workouts) { workout in
                            HStack(spacing: 12) {
                                Text(workout.type.emoji)
                                    .font(.title3)
                                    .frame(width: 36, height: 36)
                                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(workout.type.displayName)
                                        .font(.subheadline.weight(.medium))
                                    Text("\(workout.durationMinutes)分钟 · \(Int(workout.calories))kcal")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func adviceColor(_ category: AdviceCategory) -> Color {
        switch category {
        case .readyToGo: return .green
        case .lightOnly: return .orange
        case .restDay: return .blue
        case .recovery: return .purple
        }
    }
}

struct MiniTag: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.08), in: Capsule())
    }
}

struct RecoveryRing: View {
    let score: Int
    
    private var color: Color {
        score >= 80 ? .green : score >= 60 ? .orange : score >= 40 ? .orange : .red
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 4)
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
    }
}

struct StatTile: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(.headline, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
    }
}

struct WorkoutChip: View {
    let workout: WorkoutType
    
    var body: some View {
        HStack(spacing: 4) {
            Text(workout.emoji).font(.caption)
            Text(workout.displayName).font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.08), in: Capsule())
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon).font(.caption).foregroundStyle(color)
                Spacer()
            }
            HStack { Text(value).font(.headline); Spacer() }
            HStack { Text(title).font(.caption).foregroundStyle(.secondary); Spacer() }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius))
    }
}

struct QuickStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        StatTile(icon: icon, value: value, label: label, color: color)
    }
}

struct PetStatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        MiniTag(icon: icon, text: value, color: color)
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
