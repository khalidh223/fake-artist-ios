import SwiftUI

struct FakeArtistSayingTitleView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared
    @State private var appear = false
    @State private var showPointsDistributionView = false
    @State private var displayedTitle = "..."
    
    let bubbleColor = Color(red: 137/255, green: 207/255, blue: 240/255)

    var body: some View {
        ZStack {
            Color(.clear)
                .ignoresSafeArea(.all)
            if !showPointsDistributionView {
                ZStack(alignment: .topTrailing) {
                    Image("\(displayedTitle == "..." ? "fakeArtistThinking" : "fakeArtist")")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)

                    if appear {
                        Text("The title is \(displayedTitle)")
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
                }
                .onChange(of: globalStateManager.titleGuessedByFakeArtist) { _ in
                    if globalStateManager.titleGuessedByFakeArtist != "" {
                        updateDisplayedTitle()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.showPointsDistributionView = true
                        }
                    }
                }
            } else {
                PointsDistributionView()
                    .background(VisualEffectView(effect: UIBlurEffect(style: .regular)))
                    .transition(.scale.combined(with: .opacity))
                    .ignoresSafeArea(.all)
            }
        }
    }

    private func updateDisplayedTitle() {
        let newTitle = getDisplayedTitle()
        if displayedTitle != newTitle {
            displayedTitle = newTitle
        }
    }

    private func getDisplayedTitle() -> String {
        if globalStateManager.actualTitleForFakeArtist != globalStateManager.titleGuessedByFakeArtist {
            return "\(globalStateManager.titleGuessedByFakeArtist) ❌"
        }

        globalStateManager.fakeArtistGuessedTitleCorrectly = true
        return "\(globalStateManager.titleGuessedByFakeArtist) ✅"
    }
}

#Preview {
    FakeArtistSayingTitleView()
}
