import SwiftUI

struct HomeButton: View {
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Rectangle()
                .foregroundColor(Color.black.opacity(0.001))
                .frame(height: 30)
                .overlay(
                    Text(text)
                )
        }
        .buttonStyle(OutlineButtonStyle(borderColor: Color(red: 241.0 / 255.0, green: 10.0 / 255.0, blue: 126.0 / 255.0), textColor: Color(red: 241.0 / 255.0, green: 10.0 / 255.0, blue: 126.0 / 255.0), borderWidth: 1))
        .padding(.bottom)
    }
}

struct Home: View {
    @State private var showNewGameSheet = false
    @State private var showJoinGameSheet = false

    var body: some View {
        ZStack {
            Color(red: 115.0 / 255.0, green: 5.0 / 255.0, blue: 60.0 / 255.0)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Image("logo")
                    .padding()
                    .padding()
                HomeButton(text: "NEW GAME", action: { showNewGameSheet = true })
                    .sheet(isPresented: $showNewGameSheet) {
                        NewGameSheet(isPresented: $showNewGameSheet)
                    }
                HomeButton(text: "JOIN GAME", action: { showJoinGameSheet = true })
                    .sheet(isPresented: $showJoinGameSheet) {
                        JoinGameSheet(isPresented: $showJoinGameSheet)
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
