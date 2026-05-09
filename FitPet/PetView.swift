import SwiftUI

struct PetView: View {
    @EnvironmentObject var petManager: PetManager
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var advisor: FitnessAdvisorEngine
    @Binding var isTabBarVisible: Bool
    @StateObject private var aiService = AIAdvisorService()
    @StateObject private var locationWeather = LocationWeatherManager()
    @State private var showOutfitPicker = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var companionMessage: String = ""
    @State private var isThinking = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    petDisplay
                    companionBubble
                    contextCards
                    outfitShowcase
                }
                .padding()
                .padding(.bottom, 100)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("petScroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "petScroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                let delta = offset - lastScrollOffset
                if delta < -8 { isTabBarVisible = false }
                else if delta > 8 { isTabBarVisible = true }
                lastScrollOffset = offset
            }
            .navigationTitle("我的伙伴")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        PetAvatarGeneratorView()
                    } label: {
                        Image(systemName: "camera.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("换装", systemImage: "tshirt.fill") {
                        showOutfitPicker = true
                    }
                }
            }
            .sheet(isPresented: $showOutfitPicker) {
                OutfitPickerView()
            }
            .task {
                locationWeather.requestPermission()
                locationWeather.fetchLocationAndWeather()
                await generateCompanionMessage()
            }
        }
    }
    
    private var petDisplay: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [petManager.appearance.accentColor.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
            
            PetAvatarView(appearance: petManager.appearance, mood: petManager.mood, size: 160, customImage: petManager.customAvatarImage)
                .bounceOnTap()
        }
    }
    
    private var companionBubble: some View {
        VStack(spacing: 12) {
            if isThinking {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(.orange.opacity(0.6))
                            .frame(width: 8, height: 8)
                            .offset(y: isThinking ? -4 : 4)
                            .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: isThinking)
                    }
                }
                .padding()
            } else {
                Text(companionMessage.isEmpty ? petManager.appearance.motivationMessage : companionMessage)
                    .font(.system(.body, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
            }
            
            Button {
                Task { await generateCompanionMessage() }
            } label: {
                Label("换一句", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    private var contextCards: some View {
        VStack(spacing: 12) {
            if let weather = locationWeather.weather {
                GlassCard {
                    HStack(spacing: 12) {
                        Image(systemName: weather.isDaylight ? "sun.max.fill" : "moon.stars.fill")
                            .font(.title2)
                            .foregroundStyle(weather.isDaylight ? .orange : .indigo)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(weather.summary)
                                .font(.subheadline.weight(.medium))
                            Text(locationWeather.cityName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.0f°C", weather.temperature))
                                .font(.title3.weight(.semibold))
                            Text("体感 \(String(format: "%.0f°", weather.feelsLike))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.blue)
                        Text("当地推荐")
                            .font(.subheadline.weight(.medium))
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(locationWeather.locationFeature.suggestedActivities, id: \.self) { activity in
                                Text(activity)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.08), in: Capsule())
                            }
                        }
                    }
                }
            }
            
            HStack(spacing: 12) {
                MiniInfoCard(icon: "star.fill", value: "Lv.\(petManager.state.level)", color: .orange)
                MiniInfoCard(icon: "flame.fill", value: "\(petManager.state.streak)天", color: .red)
                MiniInfoCard(icon: "figure.run", value: "\(petManager.state.totalWorkoutDays)次", color: .green)
            }
        }
    }
    
    private var outfitShowcase: some View {
        GlassCard {
            HStack {
                Image(systemName: "tshirt.fill")
                    .foregroundStyle(petManager.appearance.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("当前装扮: \(petManager.appearance.accessoryName)")
                        .font(.subheadline)
                    if petManager.state.currentOutfit != .none {
                        Text("来自今日\(petManager.state.currentOutfit.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
    }
    
    private func generateCompanionMessage() async {
        isThinking = true
        
        let context = AIContext(
            steps: healthManager.todayData.steps,
            heartRate: healthManager.todayData.heartRate,
            sleepHours: healthManager.todayData.sleepHours,
            recoveryScore: healthManager.todayData.recoveryScore,
            todayWorkoutMinutes: healthManager.todayData.workouts.reduce(0) { $0 + $1.durationMinutes },
            todayWorkoutTypes: healthManager.todayData.workouts.map(\.type.displayName),
            weather: locationWeather.weather,
            cityName: locationWeather.cityName,
            locationFeature: locationWeather.locationFeature,
            currentHour: Calendar.current.component(.hour, from: .now),
            streak: petManager.state.streak
        )
        
        let message = await aiService.getAdvice(context: context)
        
        await MainActor.run {
            companionMessage = message
            isThinking = false
        }
    }
}

struct MiniInfoCard: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
