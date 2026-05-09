import Foundation
import SwiftUI

// MARK: - Pet State

struct PetState: Codable {
    var name: String = "小元"
    var level: Int = 1
    var experience: Int = 0
    var happiness: Int = 80        // 0-100
    var currentOutfit: WorkoutType = .none
    var totalWorkoutDays: Int = 0
    var streak: Int = 0
    var lastActiveDate: Date?
    var species: PetSpecies = .cat
    var evolutionStage: EvolutionStage = .baby
    var unlockedOutfits: [WorkoutType] = [.none]
    var achievements: [Achievement] = []
    
    var expForNextLevel: Int {
        level * 100
    }
    
    var levelProgress: Double {
        Double(experience) / Double(expForNextLevel)
    }
    
    var canEvolve: Bool {
        switch evolutionStage {
        case .baby: return level >= 5
        case .teen: return level >= 15
        case .adult: return level >= 30
        case .legendary: return false
        }
    }
}

enum PetSpecies: String, Codable, CaseIterable {
    case cat = "cat"
    case dog = "dog"
    case rabbit = "rabbit"
    case fox = "fox"
    case dragon = "dragon"
    
    var displayName: String {
        switch self {
        case .cat: return "元气猫"
        case .dog: return "活力犬"
        case .rabbit: return "跳跳兔"
        case .fox: return "灵动狐"
        case .dragon: return "小飞龙"
        }
    }
    
    var baseEmoji: String {
        switch self {
        case .cat: return "🐱"
        case .dog: return "🐶"
        case .rabbit: return "🐰"
        case .fox: return "🦊"
        case .dragon: return "🐲"
        }
    }
    
    var unlockCondition: String {
        switch self {
        case .cat: return "默认解锁"
        case .dog: return "累计运动7天"
        case .rabbit: return "连续打卡5天"
        case .fox: return "尝试5种不同运动"
        case .dragon: return "达到30级"
        }
    }
}

enum EvolutionStage: String, Codable, CaseIterable {
    case baby = "baby"
    case teen = "teen"
    case adult = "adult"
    case legendary = "legendary"
    
    var displayName: String {
        switch self {
        case .baby: return "幼年期"
        case .teen: return "成长期"
        case .adult: return "成熟期"
        case .legendary: return "传说期"
        }
    }
    
    var sizeMultiplier: CGFloat {
        switch self {
        case .baby: return 0.7
        case .teen: return 0.85
        case .adult: return 1.0
        case .legendary: return 1.15
        }
    }
    
    var next: EvolutionStage? {
        switch self {
        case .baby: return .teen
        case .teen: return .adult
        case .adult: return .legendary
        case .legendary: return nil
        }
    }
}

struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let unlockedDate: Date
    let icon: String
}

// MARK: - Pet Appearance Configuration

struct PetAppearance {
    let outfit: WorkoutType
    
    /// Base body color
    var bodyColor: Color {
        .orange.opacity(0.8)
    }
    
    /// Outfit-specific accent color
    var accentColor: Color {
        switch outfit {
        case .none: return .blue.opacity(0.3)
        case .running: return .green
        case .cycling: return .yellow
        case .swimming: return .cyan
        case .badminton: return .mint
        case .skiing: return .white
        case .gym: return .red
        case .yoga: return .purple
        case .hiking: return .brown
        case .basketball: return .orange
        case .soccer: return .green
        case .tennis: return .yellow
        case .dancing: return .pink
        case .other: return .gray
        }
    }
    
    /// Outfit accessory description (for future asset system)
    var accessoryName: String {
        switch outfit {
        case .none: return "睡帽"
        case .running: return "运动头带"
        case .cycling: return "骑行头盔"
        case .swimming: return "泳镜"
        case .badminton: return "球拍"
        case .skiing: return "滑雪镜+雪板"
        case .gym: return "哑铃+运动背心"
        case .yoga: return "瑜伽垫"
        case .hiking: return "登山包+登山杖"
        case .basketball: return "篮球"
        case .soccer: return "足球鞋"
        case .tennis: return "网球拍"
        case .dancing: return "舞鞋"
        case .other: return "奖牌"
        }
    }
    
    /// Pet's motivational message based on outfit
    var motivationMessage: String {
        switch outfit {
        case .none: return "今天好好休息，明天一起加油! 💤"
        case .running: return "跑起来啦！风一样的你！🌬️"
        case .cycling: return "骑行真棒！沿途风景一定很美！🌄"
        case .swimming: return "在水里的你像条鱼！太酷了！🐟"
        case .badminton: return "杀球！得分！你太厉害了！🏆"
        case .skiing: return "雪山上的英姿！注意安全哦！❄️"
        case .gym: return "举铁的你太帅了！肌肉在生长！💪"
        case .yoga: return "身心合一，宁静致远 🕊️"
        case .hiking: return "一步一步，山顶在等你！⛰️"
        case .basketball: return "灌篮高手就是你！🏀"
        case .soccer: return "绿茵场上最闪亮的星！⭐"
        case .tennis: return "ACE球！你的发球太强了！🎯"
        case .dancing: return "舞动人生，你是最美的！✨"
        case .other: return "运动真棒！今天也辛苦了！🎉"
        }
    }
}

// MARK: - Pet Mood

enum PetMood: String {
    case ecstatic    // happiness > 90
    case happy       // happiness > 70
    case content     // happiness > 50
    case tired       // happiness > 30
    case sad         // happiness <= 30
    
    static func from(happiness: Int) -> PetMood {
        switch happiness {
        case 91...100: return .ecstatic
        case 71...90: return .happy
        case 51...70: return .content
        case 31...50: return .tired
        default: return .sad
        }
    }
    
    var expression: String {
        switch self {
        case .ecstatic: return "🤩"
        case .happy: return "😊"
        case .content: return "🙂"
        case .tired: return "😪"
        case .sad: return "😢"
        }
    }
}
