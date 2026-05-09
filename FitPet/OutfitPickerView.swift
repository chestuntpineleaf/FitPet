import SwiftUI

struct OutfitPickerView: View {
    @EnvironmentObject var petManager: PetManager
    @Environment(\.dismiss) private var dismiss
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("宠物会根据你的运动自动换装")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("也可以手动预览各套装扮:")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            outfitCard(for: type)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("装扮图鉴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func outfitCard(for type: WorkoutType) -> some View {
        let isActive = petManager.state.currentOutfit == type
        let appearance = PetAppearance(outfit: type)
        
        return VStack(spacing: 8) {
            PetAvatarView(
                appearance: appearance,
                mood: isActive ? petManager.mood : .content,
                size: 80
            )
            
            Text(type.emoji)
                .font(.title3)
            Text(type.displayName)
                .font(.caption2)
            Text(appearance.accessoryName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.orange.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.orange : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            petManager.updateAppearance(for: type)
        }
    }
}
