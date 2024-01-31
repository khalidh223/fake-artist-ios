import SwiftUI

struct OkayButton: View {
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Rectangle()
                .foregroundColor(Color.black.opacity(0.001))
                .frame(height: 20)
                .overlay(
                    Text(text)
                )
        }.frame(width: 120)
        .buttonStyle(OutlineButtonStyle(borderColor: Color(red: 241.0 / 255.0, green: 10.0 / 255.0, blue: 126.0 / 255.0), textColor: Color(red: 241.0 / 255.0, green: 10.0 / 255.0, blue: 126.0 / 255.0), borderWidth: 1))
    }
}

struct CardView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared
    @State private var flipped = false
    @State private var appear = false
    @State private var selectedCardImage: String = ""
    var onOkayButtonTapped: (() -> Void)?

    var body: some View {
        let imageAspectRatio: CGFloat = 1344 / 602
        let screenWidth = UIScreen.main.bounds.width
        let frameWidth: CGFloat = screenWidth - 12
        let frameHeight: CGFloat = frameWidth / imageAspectRatio
        let cornerImageName = globalStateManager.playerRole == "FAKE_ARTIST" ? "cornerImageTitleCardFakeArtist" : "cornerImageTitleCardPlayer"

        VStack {
            if flipped {
                ZStack {
                    VStack {
                        Text("The title is:")
                            .font(.title2)
                        Text("\(globalStateManager.titleChosenByQuestionMaster.isEmpty ? "X" : globalStateManager.titleChosenByQuestionMaster)")
                            .font(.title)
                            .fontWeight(.bold)
                        OkayButton(text: "Okay", action: {
                            withAnimation {
                                globalStateManager.showDrawCanvasView = true
                            }
                        })
                    }
                    .padding(.all)

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(cornerImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: frameHeight / 1.3)
                        }
                    }
                }
                .frame(width: frameWidth, height: frameHeight)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
            } else {
                Image(selectedCardImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: frameWidth, height: frameHeight)
            }
        }
        .frame(width: frameWidth, height: frameHeight)
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 1, y: 0, z: 0))
        .opacity(appear ? 1 : 0)
        .offset(x: appear ? 0 : UIScreen.main.bounds.width)
        .onAppear {
            selectedCardImage = randomCardImage()
            withAnimation(.easeInOut(duration: 1)) {
                appear = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    flipped = true
                }
            }
        }
    }

    private func randomCardImage() -> String {
        let cardImages = ["titleCardBlue", "titleCardBrown", "titleCardDarkRed", "titleCardDarkTeal", "titleCardGray", "titleCardGreen", "titleCardOrange", "titleCardPink", "titleCardRed", "titleCardYellow"]
        return cardImages.randomElement() ?? "titleCardBlue"
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView()
    }
}
