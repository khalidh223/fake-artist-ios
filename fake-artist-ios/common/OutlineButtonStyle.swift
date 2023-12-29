import SwiftUI

struct OutlineButtonStyle: ButtonStyle {
    var borderColor: Color
    var textColor: Color
    var borderWidth: CGFloat

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(minWidth: 0, maxWidth: .infinity)
            .foregroundColor(textColor)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .fontWeight(.bold)
            .padding(.horizontal)
    }
}
