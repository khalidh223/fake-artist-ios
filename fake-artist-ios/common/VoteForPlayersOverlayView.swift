import SwiftUI

struct VoteForPlayersOverlayView: View {
    var body: some View {
        Color.white.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
        Text("stopped game overlay here")
            .font(.title)
            .foregroundColor(.black)
            .transition(.opacity)
    }
}

#Preview {
    VoteForPlayersOverlayView()
}
