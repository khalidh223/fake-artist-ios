import SwiftUI

struct ColorChoice: Identifiable {
    let id = UUID()
    let penColor: String
    let hex: String
}

let colors: [ColorChoice] = [
    ColorChoice(penColor: "black", hex: "#000000"),
    ColorChoice(penColor: "brown", hex: "#954A13"),
    ColorChoice(penColor: "darkblue", hex: "#005AA7"),
    ColorChoice(penColor: "darkpink", hex: "#BE228B"),
    ColorChoice(penColor: "green", hex: "#006F66"),
    ColorChoice(penColor: "lightblue", hex: "#00AEEB"),
    ColorChoice(penColor: "lightgreen", hex: "#76CAA1"),
    ColorChoice(penColor: "orange", hex: "#FF8335"),
    ColorChoice(penColor: "pink", hex: "#FB108B"),
    ColorChoice(penColor: "purple", hex: "#4F4E9D"),
    ColorChoice(penColor: "red", hex: "#FC212E"),
    ColorChoice(penColor: "yellow", hex: "#FFF144"),
]

struct RoleDisplayView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared
    @ObservedObject var canvasCommunicationWebSocketManager = CanvasCommunicationWebSocketManager.shared
    @ObservedObject var communicationWebSocketManager = CommunicationWebSocketManager.shared
    @State private var selectedColor: String?

    var body: some View {
        VStack {
            Spacer()

            VStack {
                Text("")
                    .padding(.bottom, 10)
                Text("Your role is:")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 10)

                Image(roleImageName())
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(0.7)
                    .offset(y: 20)
                    .frame(width: 151, height: 151)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black, lineWidth: 3))
                    .foregroundColor(.black)
                    .padding(.bottom, 10)

                Text(formatRoleName(globalStateManager.playerRole))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 5)

                Text(roleDescription())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding()

                Text(roleDetails())
                    .font(.body)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()

                Text("Pick your color:")
                    .font(.body)
                    .foregroundColor(.black)
                    .fontWeight(.bold)
                    .padding()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(colors, id: \.id) { colorChoice in
                            Image(colorChoice.penColor)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 19, height: 120)
                                .opacity(isColorDisabled(colorChoice.penColor) ? 0.3 : 1) // More pronounced dimming
                                .grayscale(isColorDisabled(colorChoice.penColor) ? 1 : 0)
                                .offset(y: selectedColor == colorChoice.penColor ? -15 : 0) // Shift up if selected
                                .onTapGesture {
                                    if !isColorDisabled(colorChoice.penColor) {
                                        selectedColor = colorChoice.penColor
                                        sendColorChoice(colorChoice.penColor)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal) // Add horizontal padding
                    .frame(height: 150) // Set a fixed height for the scroll view
                }
                .padding(.bottom)
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            Spacer()
        }.onAppear {
            print("Current colorToUsernameMap: \(globalStateManager.colorToUsernameMap)")
        }
        .onChange(of: globalStateManager.colorToUsernameMap) { newValue in
            print("colorToUsernameMap changed: \(newValue)")
        }
    }

    private func isColorDisabled(_ color: String) -> Bool {
        return globalStateManager.colorToUsernameMap[color] != nil && globalStateManager.colorToUsernameMap[color] != globalStateManager.username
    }

    private func sendColorChoice(_ hexCode: String) {
        let messageData: [String: Any] = [
            "action": "sendColorChosen",
            "colorChosen": hexCode,
            "gameCode": globalStateManager.gameCode,
            "connectionId": globalStateManager.communicationConnectionId,
            "username": globalStateManager.username,
        ]
        canvasCommunicationWebSocketManager.sendCommunicationMessage(messageData)
    }

    private func formatRoleName(_ role: String) -> String {
        switch role {
        case "FAKE_ARTIST":
            return "Fake Artist"
        case "PLAYER":
            return "Player"
        case "QUESTION_MASTER":
            return "Question Master"
        default:
            return ""
        }
    }

    // Function to determine the image name based on the role
    private func roleImageName() -> String {
        switch globalStateManager.playerRole {
        case "PLAYER":
            return "player"
        case "FAKE_ARTIST":
            return "fakeArtist"
        case "QUESTION_MASTER":
            return "questionMaster"
        default:
            return "defaultImage" // Replace with a default image name if needed
        }
    }

    private func roleDescription() -> String {
        switch globalStateManager.playerRole {
        case "FAKE_ARTIST":
            return "Fake it ‘till you make it."
        case "PLAYER":
            return "Find the Fake Artist!"
        default:
            return ""
        }
    }

    private func roleDetails() -> String {
        switch globalStateManager.playerRole {
        case "PLAYER":
            return "The Question Master shares the title with all but one player — the Fake Artist. You get two rounds to make a single mark, without releasing your click. Earn points by identifying the Fake Artist!"
        case "FAKE_ARTIST":
            return "You will see the theme, but not the title - earn points by not getting caught, or by guessing the title correctly if caught!"
        case "QUESTION_MASTER":
            return "As the Question Master, you won't be drawing. You will pick the theme and the title the Players will draw, and the Fake Artist will attempt to guess to earn you points, for the next two rounds!"
        default:
            return ""
        }
    }
}

struct RoleDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        RoleDisplayView()
    }
}
