import SwiftUI

struct RoleDisplayView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared

    var body: some View {
        VStack {
            Spacer()

            VStack {
                Text("")
                    .padding(.bottom, 10)
                Text("Your role is:")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                Image(roleImageName())
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(0.7)
                    .offset(y: 20)
                    .frame(width: 151, height: 151)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black, lineWidth: 3))
                    .padding(.bottom, 10)

                Text(formatRoleName(globalStateManager.playerRole))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 5)

                Text(roleDescription())
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()

                Text(roleDetails())
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

            Spacer()
        }
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
