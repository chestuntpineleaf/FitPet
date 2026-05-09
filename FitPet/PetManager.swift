import Foundation
import SwiftUI

@MainActor
class PetManager: ObservableObject {
    @Published var state: PetState
    @Published var appearance: PetAppearance
    @Published var customAvatarImage: UIImage?
    @Published var useCustomAvatar = false
    
    private let storageKey = "pet_state"
    
    init() {
        let loadedState: PetState
        if let data = UserDefaults.standard.data(forKey: "pet_state"),
           let saved = try? JSONDecoder().decode(PetState.self, from: data) {
            loadedState = saved
        } else {
            loadedState = PetState()
        }
        self.state = loadedState
        self.appearance = PetAppearance(outfit: loadedState.currentOutfit)
        self.customAvatarImage = nil
        self.useCustomAvatar = false
        self.showEvolutionAlert = false
        self.recentAchievement = nil
        loadCustomAvatar()
    }
    
    func setCustomAvatar(avatarId: String) {
        UserDefaults.standard.set(avatarId, forKey: "active_custom_avatar")
        useCustomAvatar = true
        loadCustomAvatar()
        save()
    }
    
    func clearCustomAvatar() {
        UserDefaults.standard.removeObject(forKey: "active_custom_avatar")
        useCustomAvatar = false
        customAvatarImage = nil
    }
    
    private func loadCustomAvatar() {
        guard let avatarId = UserDefaults.standard.string(forKey: "active_custom_avatar") else {
            useCustomAvatar = false
            return
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent("PetAvatars/\(avatarId).png")
        if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            customAvatarImage = image
            useCustomAvatar = true
        } else {
            useCustomAvatar = false
        }
    }
    
    @Published var showEvolutionAlert = false
    @Published var recentAchievement: Achievement?
    
    func updateAppearance(for workoutType: WorkoutType) {
        state.currentOutfit = workoutType
        appearance = PetAppearance(outfit: workoutType)
        unlockOutfit(workoutType)
        save()
    }
    
    func addExperience(points: Int) {
        state.experience += points
        while state.experience >= state.expForNextLevel {
            state.experience -= state.expForNextLevel
            state.level += 1
            checkLevelAchievements()
        }
        save()
    }
    
    func recordWorkoutCompleted(type: WorkoutType) {
        state.totalWorkoutDays += 1
        state.happiness = min(100, state.happiness + 10)
        
        let today = Calendar.current.startOfDay(for: .now)
        if let lastDate = state.lastActiveDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let dayDiff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if dayDiff == 1 {
                state.streak += 1
            } else if dayDiff > 1 {
                state.streak = 1
            }
        } else {
            state.streak = 1
        }
        state.lastActiveDate = today
        
        let streakBonus = min(state.streak, 10) * 2
        addExperience(points: 20 + streakBonus)
        checkStreakAchievements()
        checkEvolution()
        save()
    }
    
    func evolve() {
        guard state.canEvolve, let next = state.evolutionStage.next else { return }
        state.evolutionStage = next
        state.happiness = 100
        addExperience(points: 50)
        
        let achievement = Achievement(
            id: "evolution_\(next.rawValue)",
            title: "进化成功！",
            description: "\(state.name) 进化到了\(next.displayName)！",
            unlockedDate: .now,
            icon: "sparkles"
        )
        state.achievements.append(achievement)
        recentAchievement = achievement
        save()
    }
    
    func changeSpecies(to species: PetSpecies) {
        state.species = species
        save()
    }
    
    func dailyDecay() {
        state.happiness = max(0, state.happiness - 5)
        save()
    }
    
    func interact(action: PetInteraction) {
        switch action {
        case .pet:
            state.happiness = min(100, state.happiness + 5)
            addExperience(points: 2)
        case .feed:
            state.happiness = min(100, state.happiness + 3)
            addExperience(points: 1)
        case .play:
            state.happiness = min(100, state.happiness + 8)
            addExperience(points: 3)
        }
        save()
    }
    
    var mood: PetMood {
        PetMood.from(happiness: state.happiness)
    }
    
    private func unlockOutfit(_ type: WorkoutType) {
        if !state.unlockedOutfits.contains(type) {
            state.unlockedOutfits.append(type)
            
            if state.unlockedOutfits.count == 5 {
                let achievement = Achievement(
                    id: "outfits_5", title: "百变造型",
                    description: "解锁了5种运动装扮！",
                    unlockedDate: .now, icon: "tshirt.fill"
                )
                state.achievements.append(achievement)
                recentAchievement = achievement
            }
        }
    }
    
    private func checkEvolution() {
        if state.canEvolve {
            showEvolutionAlert = true
        }
    }
    
    private func checkLevelAchievements() {
        let milestones = [5, 10, 20, 30, 50]
        if milestones.contains(state.level) {
            let achievement = Achievement(
                id: "level_\(state.level)", title: "等级 \(state.level)！",
                description: "\(state.name) 到达了等级 \(state.level)！",
                unlockedDate: .now, icon: "arrow.up.circle.fill"
            )
            state.achievements.append(achievement)
            recentAchievement = achievement
        }
    }
    
    private func checkStreakAchievements() {
        let milestones = [3, 7, 14, 30, 60, 100]
        if milestones.contains(state.streak) {
            let achievement = Achievement(
                id: "streak_\(state.streak)", title: "\(state.streak)天连续！",
                description: "连续运动\(state.streak)天！太厉害了！",
                unlockedDate: .now, icon: "flame.fill"
            )
            state.achievements.append(achievement)
            recentAchievement = achievement
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

enum PetInteraction {
    case pet
    case feed
    case play
}
