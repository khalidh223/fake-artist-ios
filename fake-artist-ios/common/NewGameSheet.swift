import SwiftUI

struct NewGameSheet: View {
    @Binding var isPresented: Bool
    @State private var username: String = ""
    @FocusState private var isUsernameFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Text("Enter your username!")
                    .font(.title2)
                    .bold()
                    .padding()

                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .focused($isUsernameFieldFocused)
                    .padding()

                Spacer()
            }
            .navigationBarItems(trailing: Button("Next") {
                // Handle the next button action
                isPresented = false
            }
            .disabled(username.isEmpty))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isUsernameFieldFocused = true
                }
            }
        }
    }
}
