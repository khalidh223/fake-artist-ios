import SwiftUI

struct GuessTitleView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared
    @ObservedObject var canvasCommunicationWebSocketManager = CanvasCommunicationWebSocketManager.shared
    @State private var title = ""
    @State private var showFakeArtistSayingTitleView = false
    var body: some View {
        if (!showFakeArtistSayingTitleView) {
            VStack {
                Spacer()
                VStack {
                    Text("You were caught!")
                        .fontWeight(.bold)
                        .font(.title2)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 10)
                        .padding(.top, 20)
                    Text("But, you and the Question Master still have the opportunity to earn points if you can guess the title correctly!")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 10)
                        .padding(.top, 20)
                    
                    VStack {
                        Text("What is the title?")
                            .font(.headline)
                            .fontWeight(.bold)
                        TextField("Lion", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.bottom, 20)
                            .padding(.horizontal, 40)
                            .padding(.top, 5)
                    }
                    
                    HomeButton(text: "OKAY", isDisabled: title == "", action: { canvasCommunicationWebSocketManager.sendFakeArtistGuess(gameCode: globalStateManager.gameCode, title: title)
                        showFakeArtistSayingTitleView = true
                    })
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                Spacer()
            }
        } else {
            FakeArtistSayingTitleView()
        }
    }
}

#Preview {
    GuessTitleView()
}
