import SwiftUI

struct GameWinnerView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared
    @ObservedObject var canvasCommunicationWebSocketManager = CanvasCommunicationWebSocketManager.shared
    @ObservedObject var communicationWebSocketManager = CommunicationWebSocketManager.shared
    @ObservedObject private var drawingWebSocket = DrawingWebSocketManager.shared
    @State private var showHomeScreen = false
    
    var gameWinner: String
    
    var body: some View {
        if !showHomeScreen {
            ZStack {
                Color(.clear)
                    .ignoresSafeArea(.all)
                VStack {
                    Spacer()
                    VStack {
                        Text("Game over, \(gameWinner) wins!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 10)
                            .padding(.top, 20)
                    
                        Image("player")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            .padding(.bottom, 10)
                        HomeButton(text: "BACK TO HOME", action: {
                            resetAndDisconnect()
                        })
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                
                    Spacer()
                }
            }
        } else {
            Home()
        }
    }
    
    private func resetAndDisconnect() {
        showHomeScreen = true
        canvasCommunicationWebSocketManager.disconnect()
        communicationWebSocketManager.disconnect()
        drawingWebSocket.closeDrawingSocketConnection()
        globalStateManager.resetGlobalGameState()
    }
}

#Preview {
    GameWinnerView(gameWinner: "hello")
}
