import SwiftUI

struct QuestionMasterSayingThemeView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared
    @State private var appear = false
    let onThemeDisplayed: () -> Void

    let bubbleColor = Color(red: 137/255, green: 207/255, blue: 240/255)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image("\(globalStateManager.themeChosenByQuestionMaster.isEmpty ? "qmThinking" : "questionMaster")")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)

            if appear {
                Text("The theme is \(globalStateManager.themeChosenByQuestionMaster.isEmpty ? "..." : globalStateManager.themeChosenByQuestionMaster)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding()
                    .foregroundColor(.black)
                    .background(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .scaleEffect(1)
                    .overlay(
                        SpeechBubbleTriangle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(80))
                            .offset(x: 0, y: 10),
                        alignment: .bottom
                    )
                    .offset(x: 50, y: -70)
            }
        }
        .onAppear {
            withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 50, damping: 5, initialVelocity: 5)) {
                appear = true
            }
            if !globalStateManager.themeChosenByQuestionMaster.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    onThemeDisplayed()
                }
            }
        }
        .onChange(of: globalStateManager.themeChosenByQuestionMaster) { theme in
            if !theme.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    onThemeDisplayed()
                }
            }
        }
    }
}

struct QuestionMasterSayingThemeView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionMasterSayingThemeView(onThemeDisplayed: {})
    }
}
