import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var isRequestingPermission = false
    @State private var permissionGranted = false
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                featurePage.tag(1)
                permissionPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            pageIndicator
            bottomButton
        }
        .background(
            LinearGradient(colors: [.orange.opacity(0.05), .pink.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🐱")
                .font(.system(size: 80))
            Text("欢迎来到 FitPet")
                .font(.largeTitle.bold())
            Text("你的健身伙伴 + 虚拟宠物")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("它会根据你每天的运动类型换装打扮，\n为你加油打气！")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
    
    private var featurePage: some View {
        VStack(spacing: 20) {
            Spacer()
            
            FeatureRow(icon: "heart.fill", color: .red, title: "健康监控", detail: "实时追踪步数、心率、HRV、睡眠等数据")
            FeatureRow(icon: "brain.fill", color: .purple, title: "智能建议", detail: "根据恢复状态告诉你今天适合什么运动")
            FeatureRow(icon: "pawprint.fill", color: .orange, title: "宠物换装", detail: "打羽毛球？宠物穿上球拍装！去滑雪？它戴上雪镜！")
            FeatureRow(icon: "chart.line.uptrend.xyaxis", color: .blue, title: "趋势追踪", detail: "查看每周运动和恢复趋势")
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var permissionPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text("需要健康数据权限")
                .font(.title2.bold())
            
            Text("FitPet 需要读取你的 Apple Health 数据来：")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                PermissionItem(text: "分析你的运动恢复状态")
                PermissionItem(text: "识别今日运动类型为宠物换装")
                PermissionItem(text: "提供个性化运动建议")
            }
            .padding(.horizontal, 40)
            
            if permissionGranted {
                Label("权限已授予 ✓", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            }
            
            Text("数据仅在本地使用，不会上传任何服务器")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
            
            Spacer()
        }
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.orange : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 16)
    }
    
    private var bottomButton: some View {
        Button {
            handleButtonTap()
        } label: {
            HStack {
                if isRequestingPermission {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Text(buttonTitle)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private var buttonTitle: String {
        switch currentPage {
        case 0, 1: return "下一步"
        case 2:
            if permissionGranted { return "开始使用" }
            return "授权健康数据"
        default: return "下一步"
        }
    }
    
    private func handleButtonTap() {
        switch currentPage {
        case 0, 1:
            withAnimation { currentPage += 1 }
        case 2:
            if permissionGranted {
                hasCompletedOnboarding = true
            } else {
                requestHealthPermission()
            }
        default:
            break
        }
    }
    
    private func requestHealthPermission() {
        isRequestingPermission = true
        Task {
            await healthManager.requestAuthorization()
            await MainActor.run {
                isRequestingPermission = false
                permissionGranted = healthManager.isAuthorized
                if permissionGranted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

struct PermissionItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.orange)
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
        }
    }
}
