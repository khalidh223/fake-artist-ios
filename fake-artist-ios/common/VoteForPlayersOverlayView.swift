import SwiftUI

struct VoteForPlayersOverlayView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared
    @ObservedObject var canvasCommunicationWebSocketManager = CanvasCommunicationWebSocketManager.shared

    @State private var displayText = "On the count of three, pick the fake artist!"
    @State private var isVotingAllowed = true
    @State private var fadeInFakeArtist = false
    @State private var showPointsDistributionView = false
    @State private var fakeArtistHasOpportunityToGuess = false
    @State var fakeArtistAndQuestionMasterWins = false
    @State var playerWins = false

    var body: some View {
        if globalStateManager.showVoteFakeArtistView {
            if !showPointsDistributionView && !fakeArtistHasOpportunityToGuess {
                let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

                VStack {
                    Spacer()
                    VStack {
                        HStack {
                            if globalStateManager.questionMaster != globalStateManager.username {
                                Image("questionMaster")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 60)
                            }
                            Text(displayText)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .font(.system(size: 18))
                                .minimumScaleFactor(0.5)
                        }
                        .padding(.bottom, 10)
                        .padding(.horizontal, 10)
                        .padding(.top, 20)

                        if globalStateManager.players.count > 9 {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(globalStateManager.players.filter { $0 != globalStateManager.questionMaster }, id: \.self) { player in
                                        playerView(player: player)
                                    }
                                }
                            }
                        } else {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(globalStateManager.players.filter { $0 != globalStateManager.questionMaster }, id: \.self) { player in
                                    playerView(player: player)
                                }
                            }
                        }
                        if globalStateManager.votingCountdownStep > 3 && !fadeInFakeArtist {
                            HomeButton(text: "VIEW CANVAS", action: {
                                self.globalStateManager.showVoteFakeArtistView = false
                            })
                            .padding()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    Spacer()
                }
                .onChange(of: globalStateManager.fakeArtist) { _ in
                    fadeInFakeArtist = !globalStateManager.fakeArtist.isEmpty
                    if fadeInFakeArtist {
                        displayText = "The fake artist is..."
                        determineWinner()
                        if fakeArtistAndQuestionMasterWins {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                self.showPointsDistributionView = true
                            }
                        } else if playerWins {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                self.fakeArtistHasOpportunityToGuess = true
                            }
                        }
                    }
                }
                .onAppear {
                    if globalStateManager.username == globalStateManager.questionMaster {
                        displayText = "Players will now vote for the fake artist!"
                        isVotingAllowed = false
                    }

                    if globalStateManager.votingCountdownStep < 4 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            updateCountdown()
                        }
                    } else {
                        displayText = "3, 2, 1, pick!"
                        isVotingAllowed = false
                    }
                }
            } else if showPointsDistributionView {
                PointsDistributionView()
                    .background(VisualEffectView(effect: UIBlurEffect(style: .regular)))
                    .transition(.scale.combined(with: .opacity))
                    .ignoresSafeArea(.all)
            } else if fakeArtistHasOpportunityToGuess && globalStateManager.username != globalStateManager.fakeArtist {
                FakeArtistSayingTitleView()
                    .background(VisualEffectView(effect: UIBlurEffect(style: .regular)))
                    .transition(.scale.combined(with: .opacity))
                    .ignoresSafeArea(.all)
            } else if fakeArtistHasOpportunityToGuess && globalStateManager.username == globalStateManager.fakeArtist {
                GuessTitleView()
                    .background(VisualEffectView(effect: UIBlurEffect(style: .regular)))
                    .transition(.scale.combined(with: .opacity))
                    .ignoresSafeArea(.all)
            }
        }
    }

    private func determineWinner() {
        let votes = globalStateManager.votesForFakeArtist
        let fakeArtistVotes = votes[globalStateManager.fakeArtist] ?? 0
        let maxVotes = votes.values.max() ?? 0

        if fakeArtistVotes != maxVotes || votes.values.filter({ $0 == maxVotes }).count > 1 {
            fakeArtistAndQuestionMasterWins = true
        } else {
            playerWins = true
        }
    }

    @ViewBuilder
    private func playerView(player: String) -> some View {
        Button(action: {
            guard isVotingAllowed else { return }
            globalStateManager.selectedPlayer = player
            canvasCommunicationWebSocketManager.sendVoteForFakeArtist(votedFor: player, username: globalStateManager.username, gameCode: globalStateManager.gameCode)
        }) {
            VStack {
                Text(String(globalStateManager.votesForFakeArtist[player] ?? 0))
                if fadeInFakeArtist && player == globalStateManager.fakeArtist {
                    Image("fakeArtist")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 90)
                        .transition(.opacity)
                } else {
                    Image("player")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 90)
                }
                Text(player.count > 8 ? "\(player.prefix(5))..." : player)
                    .fontWeight(.bold)
                    .padding(.vertical, 1)
                let playerConfirmedColorHex = globalStateManager.playerToConfirmedColor[player] ?? ""

                Rectangle()
                    .fill(Color(hex: playerConfirmedColorHex) ?? Color.black)
                    .frame(width: 80, height: 15)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(globalStateManager.selectedPlayer == player ? Color.clear : nil)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(globalStateManager.selectedPlayer == player ? Color.blue : Color.clear, lineWidth: 3)
        )
        .cornerRadius(10)
        .padding(.bottom, 5)
        .disabled(globalStateManager.votingCountdownStep <= 3 || globalStateManager.username == player || globalStateManager.username == globalStateManager.questionMaster || globalStateManager.selectedPlayer != nil)
    }

    private func hexColorFor(penColor: String) -> String {
        guard let colorChoice = colors.first(where: { $0.penColor == penColor }) else {
            return "#FFFFFF"
        }
        return colorChoice.hex
    }

    private func updateCountdown() {
        if globalStateManager.votingCountdownStep == 0 {
            displayText = "3, "
            globalStateManager.votingCountdownStep += 1
            proceedWithCountdown()
        }
    }

    private func proceedWithCountdown() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.globalStateManager.votingCountdownStep == 1 {
                self.displayText += "2, "
                self.globalStateManager.votingCountdownStep += 1
                self.proceedWithCountdown()
            } else if self.globalStateManager.votingCountdownStep == 2 {
                self.displayText += "1, "
                self.globalStateManager.votingCountdownStep += 1
                self.proceedWithCountdown()
            } else if self.globalStateManager.votingCountdownStep == 3 {
                self.displayText += "pick!"
                self.globalStateManager.votingCountdownStep += 1
            }
        }
    }
}

struct VoteForPlayersOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        let mockGlobalStateManager = GlobalStateManager()
        mockGlobalStateManager.showVoteFakeArtistView = true
        mockGlobalStateManager.players = ["hello", "goodbyee", "khalid", "sup", "nope"]
        mockGlobalStateManager.playerToConfirmedColor = ["hello": "#00AEEB", "goodbyee": "#00AEEB", "khalid": "#00AEEB", "sup": "#00AEEB", "nope": "#00AEEB", "wow": "#00AEEB", "all": "#00AEEB", "yes": "#00AEEB"]
        mockGlobalStateManager.username = "hello"
        mockGlobalStateManager.questionMaster = "goodbyee"
        return VoteForPlayersOverlayView(globalStateManager: mockGlobalStateManager)
    }
}
