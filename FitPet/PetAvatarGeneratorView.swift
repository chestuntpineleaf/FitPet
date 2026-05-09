import SwiftUI
import PhotosUI

struct PetAvatarGeneratorView: View {
    @EnvironmentObject var petManager: PetManager
    @StateObject private var generator = PetAvatarGenerator()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var sourceImage: UIImage?
    @State private var selectedStyle: AvatarStyle = .flatCartoon
    @State private var avatarName = ""
    @State private var showCamera = false
    @State private var showSaveDialog = false
    @AppStorage("openai_api_key") private var apiKey = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    apiKeySection
                    photoPickerSection
                    stylePickerSection
                    generateButton
                    resultSection
                    savedAvatarsSection
                }
                .padding()
            }
            .navigationTitle("生成专属宠物")
            .navigationBarTitleDisplayMode(.inline)
            .alert("保存宠物形象", isPresented: $showSaveDialog) {
                TextField("给它起个名字", text: $avatarName)
                Button("保存") { saveAvatar() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("给生成的宠物形象起个名字吧")
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $sourceImage)
            }
        }
    }
    
    private var apiKeySection: some View {
        Group {
            if apiKey.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("需要 OpenAI API Key", systemImage: "key.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                        
                        Text("照片生成功能需要调用 AI 图像服务。在下方填入你的 API Key：")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        SecureField("sk-...", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                        
                        Text("Key 仅存储在你的设备上，不会上传到任何服务器")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
    
    private var photoPickerSection: some View {
        GlassCard {
            VStack(spacing: 12) {
                if let image = sourceImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Text("已选择照片")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.gray.opacity(0.1))
                        .frame(height: 180)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                Text("上传你宠物的照片")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
                
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("相册", systemImage: "photo.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    Button {
                        showCamera = true
                    } label: {
                        Label("拍照", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    sourceImage = image
                }
            }
        }
    }
    
    private var stylePickerSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("选择画风")
                    .font(.subheadline.bold())
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(AvatarStyle.allCases, id: \.self) { style in
                        Button {
                            selectedStyle = style
                        } label: {
                            VStack(spacing: 4) {
                                Text(styleEmoji(style))
                                    .font(.title2)
                                Text(style.displayName)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedStyle == style ? Color.orange.opacity(0.15) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedStyle == style ? Color.orange : Color.gray.opacity(0.2), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var generateButton: some View {
        Button {
            guard let image = sourceImage else { return }
            Task {
                await generator.generateCartoonAvatar(from: image, apiKey: apiKey, style: selectedStyle)
            }
        } label: {
            HStack {
                if generator.isGenerating {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(generator.isGenerating ? "正在生成..." : "生成卡通形象")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                (sourceImage != nil && !apiKey.isEmpty) ? AppTheme.primaryGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .foregroundStyle(.white)
        }
        .disabled(sourceImage == nil || apiKey.isEmpty || generator.isGenerating)
        
    }
    
    private var resultSection: some View {
        Group {
            if let error = generator.errorMessage {
                GlassCard {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            
            if let generated = generator.generatedImage {
                GlassCard {
                    VStack(spacing: 12) {
                        Text("生成完成！")
                            .font(.headline)
                            .foregroundStyle(.green)
                        
                        Image(uiImage: generated)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 240, maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        
                        HStack(spacing: 12) {
                            Button {
                                showSaveDialog = true
                            } label: {
                                Label("保存为宠物", systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            
                            Button {
                                setAsActivePet()
                            } label: {
                                Label("立即使用", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }
                }
            }
        }
    }
    
    private var savedAvatarsSection: some View {
        Group {
            if !generator.savedAvatars.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("我的宠物形象")
                            .font(.subheadline.bold())
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(generator.savedAvatars) { avatar in
                                VStack(spacing: 4) {
                                    if let image = generator.loadImage(for: avatar) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 70, height: 70)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    Text(avatar.name)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                                .onTapGesture {
                                    petManager.setCustomAvatar(avatarId: avatar.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveAvatar() {
        let name = avatarName.isEmpty ? "宠物\(generator.savedAvatars.count + 1)" : avatarName
        generator.saveGeneratedAvatar(name: name)
        avatarName = ""
    }
    
    private func setAsActivePet() {
        avatarName = "我的宠物"
        generator.saveGeneratedAvatar(name: avatarName)
        if let latest = generator.savedAvatars.last {
            petManager.setCustomAvatar(avatarId: latest.id)
        }
        avatarName = ""
    }
    
    private func styleEmoji(_ style: AvatarStyle) -> String {
        switch style {
        case .flatCartoon: return "🎨"
        case .pixelArt: return "👾"
        case .watercolor: return "🖌️"
        case .chibi: return "🥺"
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
