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
    @State private var showWaitingText = false
    @State private var showConfirmationView = false
    @State private var showCardView = false
    @State private var theme = ""
    @State private var title = ""

    var body: some View {
        if !globalStateManager.showDrawCanvasView {
            ZStack {
                if !showWaitingText {
                    VStack {
                        Spacer()

                        VStack {
                            Text("")
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

                            if globalStateManager.playerRole != "QUESTION_MASTER" {
                                Text("Pick your color:")
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .fontWeight(.bold)
                                    .padding()

                                GeometryReader { geometry in
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(colors, id: \.id) { colorChoice in
                                                Image(colorChoice.penColor)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 19, height: 120)
                                                    .opacity(isColorDisabled(colorChoice.penColor) ? 0.3 : 1)
                                                    .grayscale(isColorDisabled(colorChoice.penColor) ? 1 : 0)
                                                    .offset(y: selectedColor == colorChoice.penColor ? -15 : 0)
                                                    .onTapGesture {
                                                        if !isColorDisabled(colorChoice.penColor) {
                                                            selectedColor = colorChoice.penColor
                                                            sendColorChoice(colorChoice.penColor)
                                                        }
                                                    }
                                            }
                                        }
                                        .padding(.horizontal)
                                        .frame(height: 150)
                                        .frame(minWidth: geometry.size.width)
                                    }
                                }
                                .frame(height: 150)
                                .padding(.bottom)
                            } else {
                                PickTitleAndThemeView(theme: $theme, title: $title)
                            }

                            Button("Done") {
                                if globalStateManager.playerRole == "QUESTION_MASTER" {
                                    sendThemeAndTitle()
                                    globalStateManager.setShowDrawCanvasView(isDrawCanvasShown: true)
                                } else {
                                    if let selectedColor = selectedColor, let colorHex = colors.first(where: { $0.penColor == selectedColor })?.hex {
                                        sendColorConfirmed(colorHex)
                                        withAnimation {
                                            showWaitingText = true
                                        }
                                    }
                                }
                            }
                            .disabled((globalStateManager.playerRole == "QUESTION_MASTER" && (theme.isEmpty || title.isEmpty)) || (globalStateManager.playerRole != "QUESTION_MASTER" && selectedColor == nil))
                            .padding()
                        }
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

                        Spacer()
                    }
                } else if globalStateManager.allPlayersConfirmedColor {
                    QuestionMasterSayingThemeView(onThemeDisplayed: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showCardView = true
                            }
                        }
                    })
                    .opacity(showCardView ? 0 : 1)
                } else {
                    Text("Waiting for all players to pick their colors...")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                if showCardView {
                    CardView()
                        .transition(.slide)
                }
            }
            .onChange(of: globalStateManager.allPlayersConfirmedColor) { _ in
                withAnimation {
                    showConfirmationView = globalStateManager.allPlayersConfirmedColor
                }
            }
            .onChange(of: globalStateManager.showDrawCanvasView) { show in
                if show {
                    // Hide the blur effect
                    globalStateManager.showBlurEffect = false
                }
            }
        } else {
            DrawCanvasView().transition(.opacity)
        }
    }

    private func isColorDisabled(_ color: String) -> Bool {
        return globalStateManager.colorToUsernameMap[color] != nil && globalStateManager.colorToUsernameMap[color] != globalStateManager.username
    }

    private func sendColorChoice(_ colorName: String) {
        if let colorChoice = colors.first(where: { $0.penColor == colorName }) {
            globalStateManager.setUserSelectedColor(hex: colorChoice.hex)

            let messageData: [String: Any] = [
                "action": "sendColorChosen",
                "colorChosen": colorName,
                "gameCode": globalStateManager.gameCode,
                "connectionId": globalStateManager.communicationConnectionId,
                "username": globalStateManager.username,
            ]
            canvasCommunicationWebSocketManager.sendCommunicationMessage(messageData)
        }
    }

    private func sendColorConfirmed(_ hexCode: String) {
        let messageData: [String: Any] = [
            "action": "sendColorConfirmed",
            "color": hexCode,
            "gameCode": globalStateManager.gameCode,
            "username": globalStateManager.username,
        ]
        canvasCommunicationWebSocketManager.sendCommunicationMessage(messageData)
    }

    private func sendThemeAndTitle() {
        let messageData: [String: Any] = [
            "action": "sendThemeAndTitleChosenByQuestionMaster",
            "theme": theme,
            "title": title,
            "gameCode": globalStateManager.gameCode,
        ]
        communicationWebSocketManager.sendCommunicationMessage(messageData)
        globalStateManager.setThemeChosenByQuestionMaster(theme: theme)
        globalStateManager.setTitleChosenByQuestionMaster(title: title)
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
        case "QUESTION_MASTER":
            return "Help the Fake Artist win!"
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
            return "You won't be drawing! You will pick a theme and title the Players and Fake Artist will draw. The Fake Artist attempts to guess the title to earn you points!"
        default:
            return ""
        }
    }
}

struct RoleDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock GlobalStateManager for preview
        let mockGlobalStateManager = GlobalStateManager()
        mockGlobalStateManager.setPlayerRole("QUESTION_MASTER") // Example role
        mockGlobalStateManager.allPlayersConfirmedColor = true // Set to true to preview the confirmation view

        return RoleDisplayView(globalStateManager: mockGlobalStateManager)
            .previewLayout(.sizeThatFits) // Adjust layout as needed
            .padding()
            .background(Color.gray.opacity(0.1))
    }
}
