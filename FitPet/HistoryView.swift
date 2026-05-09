import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @StateObject private var historyLoader = HistoryDataLoader()
    @State private var selectedPeriod: TimePeriod = .twoWeeks
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    periodPicker
                    
                    if historyLoader.isLoading {
                        ProgressView("加载中...")
                            .padding(.top, 40)
                    } else if historyLoader.weeklyData.isEmpty {
                        emptyState
                    } else {
                        stepsChart
                        sleepChart
                        recoveryChart
                        workoutTypeBreakdown
                    }
                }
                .padding()
                .padding(.bottom, 100)
            }
            .navigationTitle("历史趋势")
            .task {
                await historyLoader.loadData(for: selectedPeriod)
            }
            .onChange(of: selectedPeriod) { _, newValue in
                Task { await historyLoader.loadData(for: newValue) }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("暂无历史数据")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("开始运动后这里会显示趋势")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 60)
    }
    
    private var periodPicker: some View {
        Picker("时间段", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var stepsChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("步数趋势", systemImage: "figure.walk")
                    .font(.headline)
                    .foregroundStyle(.green)
                
                Chart(historyLoader.weeklyData) { record in
                    BarMark(
                        x: .value("日期", record.date, unit: .day),
                        y: .value("步数", record.steps)
                    )
                    .foregroundStyle(.green.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 150)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                
                let avgSteps = historyLoader.weeklyData.map(\.steps).reduce(0, +) / max(historyLoader.weeklyData.count, 1)
                HStack {
                    Text("平均: \(avgSteps) 步/天")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("最高: \(historyLoader.weeklyData.map(\.steps).max() ?? 0)")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
    }
    
    private var sleepChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("睡眠趋势", systemImage: "moon.fill")
                    .font(.headline)
                    .foregroundStyle(.indigo)
                
                Chart(historyLoader.weeklyData) { record in
                    AreaMark(
                        x: .value("日期", record.date, unit: .day),
                        y: .value("小时", record.sleepHours)
                    )
                    .foregroundStyle(.indigo.opacity(0.3).gradient)
                    
                    LineMark(
                        x: .value("日期", record.date, unit: .day),
                        y: .value("小时", record.sleepHours)
                    )
                    .foregroundStyle(.indigo)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    RuleMark(y: .value("推荐", 7))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }
                .frame(height: 120)
                .chartYScale(domain: 0...12)
            }
        }
    }
    
    private var recoveryChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("恢复评分", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundStyle(.purple)
                
                Chart(historyLoader.weeklyData) { record in
                    LineMark(
                        x: .value("日期", record.date, unit: .day),
                        y: .value("评分", record.recoveryScore)
                    )
                    .foregroundStyle(.purple)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    
                    PointMark(
                        x: .value("日期", record.date, unit: .day),
                        y: .value("评分", record.recoveryScore)
                    )
                    .foregroundStyle(record.recoveryScore >= 70 ? .green : record.recoveryScore >= 50 ? .yellow : .red)
                }
                .frame(height: 120)
                .chartYScale(domain: 0...100)
            }
        }
    }
    
    private var workoutTypeBreakdown: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("运动类型分布", systemImage: "chart.pie.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                
                let workoutCounts = Dictionary(
                    grouping: historyLoader.weeklyData.flatMap(\.workoutTypes),
                    by: { $0 }
                ).mapValues(\.count).sorted { $0.value > $1.value }
                
                if workoutCounts.isEmpty {
                    Text("本周暂无运动记录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(workoutCounts, id: \.key) { type, count in
                        HStack(spacing: 12) {
                            Text(type.emoji)
                                .font(.title3)
                            Text(type.displayName)
                                .font(.subheadline)
                            Spacer()
                            Text("\(count)次")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.orange.gradient)
                                .frame(width: CGFloat(count) / CGFloat(workoutCounts.first?.value ?? 1) * 60, height: 8)
                        }
                    }
                }
            }
        }
    }
}

enum TimePeriod: String, CaseIterable {
    case week = "week"
    case twoWeeks = "twoWeeks"
    case month = "month"
    case quarter = "quarter"
    
    var displayName: String {
        switch self {
        case .week: return "本周"
        case .twoWeeks: return "两周"
        case .month: return "本月"
        case .quarter: return "季度"
        }
    }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        case .quarter: return 90
        }
    }
}

struct DailyRecord: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
    let sleepHours: Double
    let recoveryScore: Int
    let workoutTypes: [WorkoutType]
}
