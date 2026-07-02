import SwiftUI

struct HapticPressButtonStyle: ButtonStyle {
    var dimBackground: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // 만약 배경색을 어둡게 하고 싶다면 overlay 사용
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(configuration.isPressed && dimBackground ? 0.05 : 0.0))
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

extension ButtonStyle where Self == HapticPressButtonStyle {
    static var hapticPress: HapticPressButtonStyle { .init() }
    static func hapticPress(dimBackground: Bool) -> HapticPressButtonStyle { .init(dimBackground: dimBackground) }
}
