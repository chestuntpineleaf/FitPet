import Foundation

class AIAdvisorService: ObservableObject {
    @Published var lastResponse: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func getAdvice(context: AIContext) async -> String {
        let token = UserDefaults.standard.string(forKey: "llm_api_token") ?? ""
        let endpoint = UserDefaults.standard.string(forKey: "llm_api_endpoint") ?? ""
        
        guard !token.isEmpty, !endpoint.isEmpty else {
            return buildLocalAdvice(context: context)
        }
        
        await MainActor.run { isLoading = true; errorMessage = nil }
        
        do {
            let result = try await callLLM(token: token, endpoint: endpoint, context: context)
            await MainActor.run { lastResponse = result; isLoading = false }
            return result
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription; isLoading = false }
            return buildLocalAdvice(context: context)
        }
    }
    
    private func callLLM(token: String, endpoint: String, context: AIContext) async throws -> String {
        let systemPrompt = """
        你是一个温暖贴心的健身伙伴，像朋友一样关心用户。根据用户的健康数据、天气、地理位置和时间，给出自然、有温度的建议。
        
        要求：
        - 说话像朋友，不要像AI助手
        - 结合当地特色推荐活动（海边可以推荐潜水/冲浪、山区推荐徒步/越野）
        - 关注用户的疲劳程度，该休息就建议休息
        - 晚上要提醒休息，不要推荐运动
        - 如果用户今天已经运动很多了，要夸奖并建议放松
        - 控制在80字以内，自然口语化
        """
        
        let userPrompt = context.buildPrompt()
        
        let requestBody: [String: Any] = [
            "model": UserDefaults.standard.string(forKey: "llm_model_name") ?? "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": 200,
            "temperature": 0.8
        ]
        
        guard let url = URL(string: endpoint) else {
            throw LLMError.invalidEndpoint
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LLMError.requestFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String
        
        return content ?? buildLocalAdvice(context: context)
    }
    
    private func buildLocalAdvice(context: AIContext) -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        
        if hour >= 22 || hour < 6 {
            if context.todayWorkoutMinutes > 30 {
                return "今天练得够狠的！\(context.todayWorkoutMinutes)分钟的付出身体都记住了。现在好好睡一觉，肌肉在睡眠中生长 💪🌙"
            }
            return "夜深了，该让身体休息了。明天又是元气满满的一天 🌙"
        }
        
        if context.todayWorkoutMinutes > 60 {
            return "今天运动了\(context.todayWorkoutMinutes)分钟，真的辛苦了！接下来放松一下吧，喝杯水、拉拉伸 ☕"
        }
        
        if let weather = context.weather {
            if !weather.isGoodForOutdoor {
                return "外面天气不太适合户外运动（\(weather.summary)），去室内健身房或者在家做瑜伽也不错 🏠"
            }
            
            if weather.temperature > 28 {
                return "今天\(weather.summary)有点热，如果要运动建议选早晚凉爽时段，或者去游泳池 🏊"
            }
        }
        
        let activities = context.locationFeature.suggestedActivities
        let suggestion = activities.randomElement() ?? "运动"
        
        if context.recoveryScore >= 80 {
            return "状态不错！今天可以试试\(suggestion)。\(context.cityName.isEmpty ? "" : "在\(context.cityName)，")天气也配合 🌟"
        } else if context.recoveryScore >= 50 {
            return "身体还在恢复中，轻度活动就好。散步或者拉伸，不要逞强哦 🍃"
        } else {
            return "恢复评分有点低，今天就好好休息吧。听听音乐、看看书，明天再来 📖"
        }
    }
}

struct AIContext {
    let steps: Int
    let heartRate: Double
    let sleepHours: Double
    let recoveryScore: Int
    let todayWorkoutMinutes: Int
    let todayWorkoutTypes: [String]
    let weather: WeatherSnapshot?
    let cityName: String
    let locationFeature: LocationFeature
    let currentHour: Int
    let streak: Int
    
    func buildPrompt() -> String {
        var parts: [String] = []
        
        let hour = currentHour
        let timeDesc: String
        if hour < 6 { timeDesc = "凌晨" }
        else if hour < 9 { timeDesc = "早上" }
        else if hour < 12 { timeDesc = "上午" }
        else if hour < 14 { timeDesc = "中午" }
        else if hour < 18 { timeDesc = "下午" }
        else if hour < 22 { timeDesc = "晚上" }
        else { timeDesc = "深夜" }
        
        parts.append("现在是\(timeDesc)\(hour)点")
        
        if !cityName.isEmpty { parts.append("我在\(cityName)（\(locationFeature.displayName)环境）") }
        
        if let w = weather {
            parts.append("天气：\(w.summary)，体感\(String(format: "%.0f°C", w.feelsLike))，湿度\(String(format: "%.0f%%", w.humidity))")
        }
        
        parts.append("今日数据：步数\(steps)，睡眠\(String(format: "%.1f", sleepHours))h，恢复评分\(recoveryScore)/100")
        
        if todayWorkoutMinutes > 0 {
            let typesStr = todayWorkoutTypes.joined(separator: "、")
            parts.append("今天已运动\(todayWorkoutMinutes)分钟（\(typesStr)）")
        }
        
        if streak > 0 { parts.append("连续运动\(streak)天") }
        
        parts.append("当地特色活动：\(locationFeature.suggestedActivities.joined(separator: "、"))")
        parts.append("请给我一句贴心的建议")
        
        return parts.joined(separator: "。")
    }
}

enum LLMError: Error, LocalizedError {
    case invalidEndpoint
    case requestFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidEndpoint: return "API地址无效"
        case .requestFailed: return "请求失败"
        }
    }
}
