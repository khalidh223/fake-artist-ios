import Combine
import SwiftUI

struct GameCodeInput: View {
    @Binding var code: String
    let codeLength = 6
    @FocusState private var isInputActive: Bool
    @State private var cursorVisible = false
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .leading) {
            TextField("", text: $code)
                .focused($isInputActive)
                .font(.title)
                .foregroundColor(.clear)
                .accentColor(.orange)
                .keyboardType(.default)
                .textContentType(.oneTimeCode)
                .onChange(of: code) { newValue in
                    if newValue.count > codeLength {
                        code = String(newValue.prefix(codeLength))
                    }
                    code = code.uppercased()
                }
                .frame(width: CGFloat(codeLength) * 44, height: 55)
                .opacity(0.01)

            HStack(spacing: 15) {
                ForEach(0 ..< codeLength, id: \.self) { index in
                    Text(code.count > index ? String(code[code.index(code.startIndex, offsetBy: index)]) : "")
                        .font(.title)
                        .frame(width: 44, height: 55)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
            }

            // Cursor
            if isInputActive && code.count < codeLength {
                Rectangle()
                    .frame(width: 28, height: 3) // Adjust the width and height as needed
                    .foregroundColor(.orange)
                    .opacity(cursorVisible ? 1 : 0)
                    .cornerRadius(1)
                    .offset(x: CGFloat(code.count) * (44 + 15) + 8, y: 21) // Adjust the offset to center the cursor
                    .onReceive(timer) { _ in
                        self.cursorVisible.toggle()
                    }
            }
        }
        .onTapGesture {
            self.isInputActive = true
        }
    }
}

struct JoinGameSheet: View {
    @Binding var isPresented: Bool
    @State private var username: String = ""
    @State private var gameCode: String = ""
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
                    .padding()
                    .focused($isUsernameFieldFocused)

                Spacer()

                Text("Enter your game code!")
                    .font(.title2)
                    .bold()
                    .padding()

                GameCodeInput(code: $gameCode)
                    .padding(.horizontal)
                    .padding(.bottom)

                Spacer()
            }
            .navigationBarItems(trailing: Button("Next") {
                // Handle the next button action
                isPresented = false
            }
            .disabled(username.isEmpty || gameCode.count != 6))
            .onAppear {
                DispatchQueue.main.async {
                    self.isUsernameFieldFocused = true
                }
            }
        }
    }
}
