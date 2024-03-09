import SwiftUI

struct LoadingNewRoundView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared
    @State var showRoleDisplayView = false
    var body: some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: .regular))
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                if !showRoleDisplayView {
                    Text("Loading new round...")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .multilineTextAlignment(.center)
                        .font(.title)
                }
                Spacer()
            }
            .transition(.scale.combined(with: .opacity))
        }
        .ignoresSafeArea(.all)
        .onReceive(globalStateManager.$showRoleDisplayViewAfterReset) { showRoleDisplayViewAfterReset in
            if showRoleDisplayViewAfterReset {
                showRoleDisplayView = true
            }
        }
    }
}

#Preview {
    LoadingNewRoundView()
        .background(VisualEffectView(effect: UIBlurEffect(style: .regular)))
        .transition(.scale.combined(with: .opacity))
        .ignoresSafeArea(.all)
}
