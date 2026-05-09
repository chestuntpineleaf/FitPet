import SwiftUI

struct PetView: View {
    @EnvironmentObject var petManager: PetManager
    @EnvironmentObject var healthManager: HealthKitManager
    @Binding var isTabBarVisible: Bool
    @State private var isAnimating = false
    @State private var showOutfitPicker = false
    @State private var lastScrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    petDisplay
                    petInfo
                    outfitShowcase
                    interactionButtons
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
            .navigationTitle("我的宠物")
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
        }
    }
    
    private var petDisplay: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [petManager.appearance.accentColor.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
            
            PetAvatarView(appearance: petManager.appearance, mood: petManager.mood, size: 160, customImage: petManager.customAvatarImage)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
        }
        .onAppear { isAnimating = true }
    }
    
    private var petInfo: some View {
        VStack(spacing: 8) {
            Text(petManager.state.name)
                .font(.title2.bold())
            
            Text(petManager.appearance.motivationMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                VStack {
                    Text("等级")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(petManager.state.level)")
                        .font(.title3.bold())
                }
                
                VStack {
                    Text("心情")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(petManager.mood.expression)
                        .font(.title3)
                }
                
                VStack {
                    Text("连续")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(petManager.state.streak)天")
                        .font(.title3.bold())
                }
                
                VStack {
                    Text("运动日")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(petManager.state.totalWorkoutDays)")
                        .font(.title3.bold())
                }
            }
            
            ProgressView(value: petManager.state.levelProgress)
                .tint(.orange)
                .padding(.horizontal, 40)
            Text("经验值 \(petManager.state.experience)/\(petManager.state.expForNextLevel)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var outfitShowcase: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "tshirt.fill")
                    .foregroundStyle(petManager.appearance.accentColor)
                Text("当前装扮: \(petManager.appearance.accessoryName)")
                    .font(.subheadline)
            }
            
            if petManager.state.currentOutfit != .none {
                Text("来自今日 \(petManager.state.currentOutfit.displayName) 运动")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var interactionButtons: some View {
        HStack(spacing: 12) {
            InteractionButton(icon: "hand.wave.fill", label: "摸摸", color: .orange) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    petManager.interact(action: .pet)
                }
            }
            
            InteractionButton(icon: "carrot.fill", label: "喂食", color: .green) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    petManager.interact(action: .feed)
                }
            }
            
            InteractionButton(icon: "gamecontroller.fill", label: "玩耍", color: .purple) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    petManager.interact(action: .play)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct InteractionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    @State private var tapped = false
    
    var body: some View {
        Button {
            tapped = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { tapped = false }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .scaleEffect(tapped ? 1.3 : 1.0)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(tapped ? 0.25 : 0.1), in: RoundedRectangle(cornerRadius: 14))
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: tapped)
        .sensoryFeedback(.impact(weight: .light), trigger: tapped)
    }
}
