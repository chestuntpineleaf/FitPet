import SwiftUI

struct HealthDetailView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @EnvironmentObject var advisor: FitnessAdvisorEngine
    
    var body: some View {
        NavigationStack {
            List {
                Section("恢复评估") {
                    recoveryGauge
                }
                
                Section("今日数据") {
                    healthRow(icon: "figure.walk", title: "步数", value: "\(healthManager.todayData.steps)", color: .green)
                    healthRow(icon: "heart.fill", title: "心率", value: "\(Int(healthManager.todayData.heartRate)) bpm", color: .red)
                    healthRow(icon: "heart.text.square", title: "静息心率", value: "\(Int(healthManager.todayData.restingHeartRate)) bpm", color: .pink)
                    healthRow(icon: "waveform.path.ecg", title: "HRV (SDNN)", value: "\(Int(healthManager.todayData.hrv)) ms", color: .purple)
                    healthRow(icon: "moon.fill", title: "昨晚睡眠", value: String(format: "%.1f 小时", healthManager.todayData.sleepHours), color: .indigo)
                    healthRow(icon: "flame.fill", title: "活动消耗", value: "\(Int(healthManager.todayData.activeCalories)) kcal", color: .orange)
                }
                
                Section("分析依据") {
                    ForEach(advisor.detailReasons, id: \.self) { reason in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(reason)
                                .font(.subheadline)
                        }
                    }
                }
                
                Section("今日运动记录") {
                    if healthManager.todayData.workouts.isEmpty {
                        Text("暂无运动记录")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(healthManager.todayData.workouts) { workout in
                            HStack {
                                Text(workout.type.emoji)
                                VStack(alignment: .leading) {
                                    Text(workout.type.displayName)
                                        .font(.subheadline)
                                    Text("\(workout.durationMinutes)分钟 · \(Int(workout.calories))kcal")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(workout.date, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("健康数据")
        }
    }
    
    private var recoveryGauge: some View {
        let score = healthManager.todayData.recoveryScore
        let color: Color = score >= 80 ? .green : score >= 60 ? .yellow : score >= 40 ? .orange : .red
        
        return HStack {
            Gauge(value: Double(score), in: 0...100) {
                Text("恢复")
            } currentValueLabel: {
                Text("\(score)")
                    .font(.title2.bold())
            }
            .gaugeStyle(.accessoryCircular)
            .tint(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("恢复评分")
                    .font(.headline)
                Text(advisor.todayAdvice?.title ?? "加载中...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading)
        }
        .padding(.vertical, 8)
    }
    
    private func healthRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
