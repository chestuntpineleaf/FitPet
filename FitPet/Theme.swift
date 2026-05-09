import SwiftUI

enum AppTheme {
    static let cornerRadius: CGFloat = 24
    static let smallCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 18
    static let spacing: CGFloat = 16
    
    static let pastelBlue = Color(red: 0.92, green: 0.95, blue: 1.0)
    static let pastelPink = Color(red: 1.0, green: 0.94, blue: 0.96)
    static let pastelGreen = Color(red: 0.93, green: 0.99, blue: 0.95)
    static let pastelPurple = Color(red: 0.95, green: 0.93, blue: 1.0)
    
    static let primaryGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.6, blue: 0.4), Color(red: 1.0, green: 0.4, blue: 0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(AppTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(scheme == .dark ? 0.2 : 0.04), radius: 12, y: 6)
            )
    }
}

struct AnimatedGradientBackground: View {
    let colors: [Color]
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

extension View {
    func bounceOnTap() -> some View {
        self.modifier(BounceModifier())
    }
}

struct BounceModifier: ViewModifier {
    @State private var pressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { _ in pressed = false }
            )
    }
}
