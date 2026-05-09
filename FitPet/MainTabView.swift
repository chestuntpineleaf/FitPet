import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var petManager: PetManager
    @State private var selectedTab = 0
    @State private var isTabBarVisible = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0: HomeView(isTabBarVisible: $isTabBarVisible)
                case 1: PetView(isTabBarVisible: $isTabBarVisible)
                case 2: HistoryView()
                case 3: HealthDetailView()
                case 4: SettingsView()
                default: HomeView(isTabBarVisible: $isTabBarVisible)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if isTabBarVisible {
                floatingTabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isTabBarVisible)
        .ignoresSafeArea(.keyboard)
        .overlay(achievementToast)
    }
    
    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "house.fill", label: "首页", isSelected: selectedTab == 0) { selectedTab = 0 }
            TabBarButton(icon: "pawprint.fill", label: "宠物", isSelected: selectedTab == 1) { selectedTab = 1 }
            TabBarButton(icon: "chart.line.uptrend.xyaxis", label: "趋势", isSelected: selectedTab == 2) { selectedTab = 2 }
            TabBarButton(icon: "heart.fill", label: "健康", isSelected: selectedTab == 3) { selectedTab = 3 }
            TabBarButton(icon: "gearshape.fill", label: "设置", isSelected: selectedTab == 4) { selectedTab = 4 }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.clear)
                .background(.ultraThinMaterial, in: Capsule())
                .opacity(0.92)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
    
    @ViewBuilder
    private var achievementToast: some View {
        if let achievement = petManager.recentAchievement {
            VStack {
                AchievementToast(achievement: achievement)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { petManager.recentAchievement = nil }
                        }
                    }
                Spacer()
            }
            .padding(.top, 50)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: petManager.recentAchievement?.id)
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .orange : .secondary.opacity(0.7))
                
                Text(label)
                    .font(.system(size: 9, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? .orange : .secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct AchievementToast: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline.bold())
                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
