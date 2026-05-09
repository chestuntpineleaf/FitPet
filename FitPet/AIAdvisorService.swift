import Foundation

protocol AIAdvisorProtocol {
    func getAdvice(for healthData: TodayHealthData) async throws -> String
}

class AIAdvisorService: AIAdvisorProtocol {
    private let apiKey: String
    private let baseURL: String
    
    init(apiKey: String, baseURL: String = "https://api.openai.com/v1/chat/completions") {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }
    
    func getAdvice(for healthData: TodayHealthData) async throws -> String {
        let prompt = buildPrompt(from: healthData)
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "你是一个专业的健身教练和健康顾问。根据用户的健康数据，给出简短、有用的运动建议。回答要温暖友善，像朋友一样鼓励用户。限制在100字以内。"],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 200,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: baseURL) else {
            throw AIAdvisorError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIAdvisorError.requestFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String
        
        return content ?? "今天也要好好照顾自己哦！"
    }
    
    private func buildPrompt(from data: TodayHealthData) -> String {
        var parts: [String] = []
        parts.append("今日健康数据:")
        parts.append("- 步数: \(data.steps)")
        if data.heartRate > 0 { parts.append("- 当前心率: \(Int(data.heartRate)) bpm") }
        if data.restingHeartRate > 0 { parts.append("- 静息心率: \(Int(data.restingHeartRate)) bpm") }
        if data.hrv > 0 { parts.append("- HRV: \(Int(data.hrv)) ms") }
        parts.append("- 昨晚睡眠: \(String(format: "%.1f", data.sleepHours)) 小时")
        parts.append("- 活动消耗: \(Int(data.activeCalories)) kcal")
        parts.append("- 恢复评分: \(data.recoveryScore)/100")
        
        if !data.workouts.isEmpty {
            let workoutDesc = data.workouts.map { "\($0.type.displayName) \($0.durationMinutes)分钟" }.joined(separator: ", ")
            parts.append("- 今日已运动: \(workoutDesc)")
        }
        
        parts.append("\n请根据以上数据，告诉我今天适合什么运动，或者是否应该休息。")
        return parts.joined(separator: "\n")
    }
}

enum AIAdvisorError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的API地址"
        case .requestFailed: return "请求失败"
        case .invalidResponse: return "响应格式错误"
        }
    }
}
