import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var petManager: PetManager
    @State private var petName: String = ""
    @State private var showRenameAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("宠物") {
                    HStack {
                        Text("名字")
                        Spacer()
                        Text(petManager.state.name)
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture {
                        petName = petManager.state.name
                        showRenameAlert = true
                    }
                    
                    HStack {
                        Text("等级")
                        Spacer()
                        Text("Lv.\(petManager.state.level)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("总运动天数")
                        Spacer()
                        Text("\(petManager.state.totalWorkoutDays) 天")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("数据来源") {
                    Label("Apple Health", systemImage: "heart.fill")
                    Label("Apple Watch (自动同步)", systemImage: "applewatch")
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0 (MVP)")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://developer.apple.com/health-fitness/")!) {
                        Label("HealthKit 文档", systemImage: "link")
                    }
                }
                
                Section("未来功能") {
                    Label("AI 智能建议 (大模型)", systemImage: "brain")
                    Label("社交系统", systemImage: "person.2")
                    Label("更多宠物形态", systemImage: "star")
                    Label("Apple Watch 独立 App", systemImage: "applewatch.side.right")
                }
                .foregroundStyle(.secondary)
            }
            .navigationTitle("设置")
            .alert("重命名宠物", isPresented: $showRenameAlert) {
                TextField("宠物名字", text: $petName)
                Button("确定") {
                    if !petName.isEmpty {
                        petManager.state.name = petName
                    }
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
}
