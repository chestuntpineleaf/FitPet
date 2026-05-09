import SwiftUI
import PhotosUI
import Foundation

class PetAvatarGenerator: ObservableObject {
    @Published var generatedImage: UIImage?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var savedAvatars: [PetAvatar] = []
    
    private let storageKey = "pet_avatars"
    private let avatarDirectory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("PetAvatars", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    init() {
        loadSavedAvatars()
    }
    
    func generateCartoonAvatar(from photo: UIImage, apiKey: String, style: AvatarStyle = .flatCartoon) async {
        guard !apiKey.isEmpty else {
            errorMessage = "请先在设置中填入 API Key"
            return
        }
        
        await MainActor.run { isGenerating = true; errorMessage = nil }
        
        do {
            let result = try await callImageGenerationAPI(photo: photo, apiKey: apiKey, style: style)
            await MainActor.run {
                generatedImage = result
                isGenerating = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }
    
    func saveGeneratedAvatar(name: String) {
        guard let image = generatedImage else { return }
        let id = UUID().uuidString
        let filename = "\(id).png"
        let fileURL = avatarDirectory.appendingPathComponent(filename)
        
        if let data = image.pngData() {
            try? data.write(to: fileURL)
            let avatar = PetAvatar(id: id, name: name, filename: filename, createdAt: .now)
            savedAvatars.append(avatar)
            persistAvatarList()
        }
    }
    
    func loadImage(for avatar: PetAvatar) -> UIImage? {
        let fileURL = avatarDirectory.appendingPathComponent(avatar.filename)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    func deleteAvatar(_ avatar: PetAvatar) {
        let fileURL = avatarDirectory.appendingPathComponent(avatar.filename)
        try? FileManager.default.removeItem(at: fileURL)
        savedAvatars.removeAll { $0.id == avatar.id }
        persistAvatarList()
    }
    
    private func callImageGenerationAPI(photo: UIImage, apiKey: String, style: AvatarStyle) async throws -> UIImage {
        guard let imageData = photo.jpegData(compressionQuality: 0.7) else {
            throw AvatarError.imageEncodingFailed
        }
        let base64Image = imageData.base64EncodedString()
        
        let prompt = style.prompt
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 1000
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AvatarError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 60
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AvatarError.apiFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String
        
        let generatedImageResult = try await generateWithDALLE(description: content ?? "cute cartoon pet", apiKey: apiKey)
        return generatedImageResult
    }
    
    private func generateWithDALLE(description: String, apiKey: String) async throws -> UIImage {
        let prompt = """
        Flat cartoon style pet avatar, cute character design, simple clean lines, \
        soft pastel colors, round friendly face, suitable for mobile app icon. \
        Based on: \(description.prefix(500)). \
        Style: flat design, minimal shading, bold outlines, kawaii aesthetic, white background.
        """
        
        let requestBody: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "quality": "standard",
            "style": "natural"
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/images/generations") else {
            throw AvatarError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 90
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMsg = (errorJson?["error"] as? [String: Any])?["message"] as? String
            throw AvatarError.dalleError(errorMsg ?? "生成失败")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let dataArray = json?["data"] as? [[String: Any]]
        guard let imageURLString = dataArray?.first?["url"] as? String,
              let imageURL = URL(string: imageURLString) else {
            throw AvatarError.noImageInResponse
        }
        
        let (imageData, _) = try await URLSession.shared.data(from: imageURL)
        guard let image = UIImage(data: imageData) else {
            throw AvatarError.imageDecodingFailed
        }
        
        return image
    }
    
    private func loadSavedAvatars() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let avatars = try? JSONDecoder().decode([PetAvatar].self, from: data) else { return }
        savedAvatars = avatars
    }
    
    private func persistAvatarList() {
        if let data = try? JSONEncoder().encode(savedAvatars) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

struct PetAvatar: Codable, Identifiable {
    let id: String
    let name: String
    let filename: String
    let createdAt: Date
}

enum AvatarStyle: String, CaseIterable {
    case flatCartoon = "flat_cartoon"
    case pixelArt = "pixel_art"
    case watercolor = "watercolor"
    case chibi = "chibi"
    
    var displayName: String {
        switch self {
        case .flatCartoon: return "扁平卡通"
        case .pixelArt: return "像素风"
        case .watercolor: return "水彩风"
        case .chibi: return "Q版"
        }
    }
    
    var prompt: String {
        switch self {
        case .flatCartoon:
            return "Look at this pet photo and describe it for an artist to draw a flat cartoon avatar: species, color, markings, expression, any distinctive features. Be concise."
        case .pixelArt:
            return "Look at this pet photo and describe it for pixel art: species, main colors, simple distinguishing features. Be very concise."
        case .watercolor:
            return "Look at this pet photo and describe it for a watercolor illustration: species, coloring, pose, mood. Be concise."
        case .chibi:
            return "Look at this pet photo and describe it for a chibi/kawaii style drawing: species, color, cute features, expression. Be concise."
        }
    }
}

enum AvatarError: Error, LocalizedError {
    case imageEncodingFailed
    case invalidURL
    case apiFailed
    case dalleError(String)
    case noImageInResponse
    case imageDecodingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed: return "照片处理失败"
        case .invalidURL: return "API地址错误"
        case .apiFailed: return "API请求失败，请检查Key是否有效"
        case .dalleError(let msg): return "生成失败: \(msg)"
        case .noImageInResponse: return "未返回图片"
        case .imageDecodingFailed: return "图片解码失败"
        }
    }
}
