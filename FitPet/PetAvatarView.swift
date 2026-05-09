import SwiftUI

struct PetAvatarView: View {
    let appearance: PetAppearance
    let mood: PetMood
    let size: CGFloat
    var customImage: UIImage? = nil
    
    var body: some View {
        if let custom = customImage {
            ZStack {
                Image(uiImage: custom)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size * 0.85, height: size * 0.85)
                    .clipShape(Circle())
                otterAccessory
            }
            .frame(width: size, height: size)
        } else {
            ZStack {
                otterBody
                otterFace
                otterAccessory
            }
            .frame(width: size, height: size)
        }
    }
    
    private var otterBody: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.55, green: 0.38, blue: 0.26))
                .frame(width: size * 0.6, height: size * 0.7)
            
            Ellipse()
                .fill(Color(red: 0.9, green: 0.85, blue: 0.78))
                .frame(width: size * 0.4, height: size * 0.42)
                .offset(y: size * 0.08)
            
            Circle()
                .fill(Color(red: 0.55, green: 0.38, blue: 0.26))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: -size * 0.28, y: -size * 0.22)
            
            Circle()
                .fill(Color(red: 0.55, green: 0.38, blue: 0.26))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: size * 0.28, y: -size * 0.22)
        }
    }
    
    private var otterFace: some View {
        VStack(spacing: size * 0.01) {
            HStack(spacing: size * 0.1) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.11, height: size * 0.11)
                    Circle()
                        .fill(.black)
                        .frame(width: size * 0.07, height: size * 0.07)
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.025, height: size * 0.025)
                        .offset(x: -size * 0.01, y: -size * 0.01)
                }
                
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.11, height: size * 0.11)
                    Circle()
                        .fill(.black)
                        .frame(width: size * 0.07, height: size * 0.07)
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.025, height: size * 0.025)
                        .offset(x: -size * 0.01, y: -size * 0.01)
                }
            }
            
            Ellipse()
                .fill(Color(red: 0.3, green: 0.2, blue: 0.15))
                .frame(width: size * 0.06, height: size * 0.04)
                .offset(y: size * 0.01)
            
            mouthShape
                .offset(y: size * 0.005)
            
            HStack(spacing: size * 0.06) {
                Circle()
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: size * 0.06, height: size * 0.04)
                Circle()
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: size * 0.06, height: size * 0.04)
            }
            .offset(y: -size * 0.005)
        }
        .offset(y: -size * 0.06)
    }
    
    @ViewBuilder
    private var mouthShape: some View {
        switch mood {
        case .ecstatic, .happy:
            Capsule()
                .fill(Color(red: 0.85, green: 0.45, blue: 0.4))
                .frame(width: size * 0.08, height: size * 0.035)
        case .content:
            Capsule()
                .fill(Color(red: 0.4, green: 0.3, blue: 0.25))
                .frame(width: size * 0.06, height: size * 0.015)
        case .tired, .sad:
            Capsule()
                .fill(Color(red: 0.4, green: 0.3, blue: 0.25))
                .frame(width: size * 0.05, height: size * 0.015)
                .rotationEffect(.degrees(5))
        }
    }
    
    @ViewBuilder
    private var otterAccessory: some View {
        switch appearance.outfit {
        case .none:
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: size * 0.08)
                .overlay(Text("z").font(.system(size: size * 0.04)).foregroundStyle(.blue.opacity(0.5)))
                .offset(x: size * 0.25, y: -size * 0.3)
        case .running:
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.green)
                .frame(width: size * 0.4, height: size * 0.04)
                .offset(y: -size * 0.28)
        case .cycling:
            Capsule()
                .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                .frame(width: size * 0.35, height: size * 0.12)
                .offset(y: -size * 0.33)
        case .swimming:
            HStack(spacing: size * 0.03) {
                Circle().fill(Color.cyan.opacity(0.7)).frame(width: size * 0.1)
                Circle().fill(Color.cyan.opacity(0.7)).frame(width: size * 0.1)
            }
            .offset(y: -size * 0.1)
        case .badminton:
            Ellipse()
                .stroke(Color.mint, lineWidth: 2)
                .frame(width: size * 0.12, height: size * 0.17)
                .offset(x: size * 0.32, y: -size * 0.05)
        case .skiing:
            VStack(spacing: 0) {
                HStack(spacing: size * 0.05) {
                    Circle().fill(Color.orange).frame(width: size * 0.08)
                    Circle().fill(Color.orange).frame(width: size * 0.08)
                }
                .offset(y: -size * 0.1)
            }
        case .gym:
            HStack(spacing: size * 0.12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: size * 0.05, height: size * 0.12)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: size * 0.05, height: size * 0.12)
            }
            .overlay(
                Rectangle().fill(Color.gray.opacity(0.4))
                    .frame(width: size * 0.2, height: size * 0.025)
            )
            .offset(x: size * 0.25, y: size * 0.05)
        case .yoga:
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(Color.purple.opacity(0.3))
                .frame(width: size * 0.5, height: size * 0.035)
                .offset(y: size * 0.35)
        case .hiking:
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(Color.brown.opacity(0.5))
                .frame(width: size * 0.15, height: size * 0.2)
                .offset(x: -size * 0.28, y: size * 0.02)
        case .basketball:
            Circle()
                .fill(Color.orange)
                .frame(width: size * 0.1)
                .offset(x: size * 0.28, y: size * 0.18)
        case .soccer:
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.black, lineWidth: 1))
                .frame(width: size * 0.1)
                .offset(x: size * 0.22, y: size * 0.28)
        case .tennis:
            Ellipse()
                .stroke(Color.green, lineWidth: 2)
                .frame(width: size * 0.1, height: size * 0.14)
                .offset(x: size * 0.3, y: -size * 0.03)
        case .dancing:
            HStack(spacing: size * 0.06) {
                Capsule().fill(Color.pink).frame(width: size * 0.06, height: size * 0.03)
                Capsule().fill(Color.pink).frame(width: size * 0.06, height: size * 0.03)
            }
            .offset(y: size * 0.33)
        case .other:
            Circle()
                .fill(Color.yellow)
                .frame(width: size * 0.08)
                .overlay(Image(systemName: "star.fill").font(.system(size: size * 0.04)).foregroundStyle(.orange))
                .offset(y: size * 0.13)
        }
    }
}
