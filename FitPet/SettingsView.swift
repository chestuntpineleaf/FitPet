import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var petManager: PetManager
    @AppStorage("llm_api_token") private var apiToken = ""
    @AppStorage("llm_api_endpoint") private var apiEndpoint = "https://api.openai.com/v1/chat/completions"
    @AppStorage("llm_model_name") private var modelName = "gpt-4o-mini"
    @AppStorage("openai_api_key") private var openaiKey = ""
    @State private var petName: String = ""
    @State private var showRenameAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("AI 大模型配置") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("API 地址")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("https://api.openai.com/v1/chat/completions", text: $apiEndpoint)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Token / API Key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        SecureField("sk-...", text: $apiToken)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("模型名称")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("gpt-4o-mini", text: $modelName)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    
                    if !apiToken.isEmpty {
                        Label("已配置", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    } else {
                        Label("未配置（使用本地规则引擎）", systemImage: "info.circle")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                
                Section("宠物图像生成 (DALL-E)") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("OpenAI Key (用于生成宠物头像)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        SecureField("sk-...", text: $openaiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                    }
                }
                
                Section("宠物") {
                    HStack {
                        Text("名字")
                        Spacer()
                        Text(petManager.state.name)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
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
                        Text("连续运动")
                        Spacer()
                        Text("\(petManager.state.streak) 天")
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
                    Label("Apple Health (HealthKit)", systemImage: "heart.fill")
                    Label("Apple Watch (自动同步)", systemImage: "applewatch")
                    Label("WeatherKit (天气)", systemImage: "cloud.sun.fill")
                    Label("CoreLocation (位置)", systemImage: "location.fill")
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("2.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("数据仅存储在本地，不会上传任何服务器")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .navigationTitle("设置")
            .alert("重命名宠物", isPresented: $showRenameAlert) {
                TextField("宠物名字", text: $petName)
                Button("确定") {
                    if !petName.isEmpty { petManager.state.name = petName }
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
}
