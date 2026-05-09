import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var viewModel: WatchViewModel
    @State private var isPetBouncing = false
    
    var body: some View {
        TabView {
            petTab
            statsTab
            adviceTab
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
            Task { await viewModel.fetchAllData() }
        }
    }
    
    private var petTab: some View {
        VStack(spacing: 8) {
            Text(viewModel.petMoodEmoji)
                .font(.system(size: 44))
                .scaleEffect(isPetBouncing ? 1.15 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: isPetBouncing)
                .onTapGesture {
                    isPetBouncing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isPetBouncing = false
                    }
                }
            
            Text(viewModel.petName)
                .font(.headline)
            
            HStack(spacing: 8) {
                Text("Lv.\(viewModel.petLevel)")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
                
                if !viewModel.latestWorkoutEmoji.isEmpty {
                    Text(viewModel.latestWorkoutEmoji)
                        .font(.caption)
                }
            }
            
            Text(viewModel.motivationMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .containerBackground(.orange.gradient.opacity(0.2), for: .tabView)
    }
    
    private var statsTab: some View {
        VStack(spacing: 8) {
            WatchStatRow(icon: "figure.walk", value: "\(viewModel.steps)", unit: "步", color: .green)
            WatchStatRow(icon: "heart.fill", value: "\(viewModel.heartRate)", unit: "bpm", color: .red)
            WatchStatRow(icon: "moon.fill", value: String(format: "%.1f", viewModel.sleepHours), unit: "h", color: .indigo)
            WatchStatRow(icon: "flame.fill", value: "\(viewModel.activeCalories)", unit: "kcal", color: .orange)
            
            Divider().opacity(0.3)
            
            HStack(spacing: 4) {
                WatchRecoveryRing(score: viewModel.recoveryScore)
                    .frame(width: 28, height: 28)
                Text("恢复 \(viewModel.recoveryScore)")
                    .font(.caption2)
            }
        }
        .containerBackground(.blue.gradient.opacity(0.2), for: .tabView)
    }
    
    private var adviceTab: some View {
        VStack(spacing: 10) {
            Image(systemName: viewModel.adviceIcon)
                .font(.title2)
                .foregroundStyle(viewModel.adviceColor)
            
            Text(viewModel.adviceTitle)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(viewModel.adviceDetail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            Button {
                Task { await viewModel.fetchAllData() }
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
                    .font(.caption2)
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
        .padding(.horizontal, 4)
        .containerBackground(.green.gradient.opacity(0.2), for: .tabView)
    }
}

struct WatchStatRow: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
                .frame(width: 16)
            Text(value)
                .font(.system(.headline, design: .rounded))
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

struct WatchRecoveryRing: View {
    let score: Int
    
    private var color: Color {
        score >= 80 ? .green : score >= 60 ? .yellow : score >= 40 ? .orange : .red
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
