import SwiftUI

struct PointsDistributionView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared
    @ObservedObject var canvasCommunicationWebSocketManager = CanvasCommunicationWebSocketManager.shared
    @State var fakeArtistAndQuestionMasterWins = false
    @State var playerWins = false
    @State var showLoadingNewRoundView = false

    var body: some View {
        if !showLoadingNewRoundView {
            VStack {
                Spacer()
                VStack {
                    Text(fakeArtistAndQuestionMasterWins ? "Fake Artist and Question Master win!" : "Players win!")
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .font(.system(size: 18))
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)

                    if fakeArtistAndQuestionMasterWins {
                        HStack(spacing: 20) {
                            fakeArtistAndQuestionMasterView()
                        }
                    } else if playerWins {
                        playerWinsSection()
                    }

                    HomeButton(text: "OKAY", action: {
                        canvasCommunicationWebSocketManager.sendResetRoundStateForPlayer(gameCode: globalStateManager.gameCode, username: globalStateManager.username, currentQuestionMaster: globalStateManager.questionMaster)
                        showLoadingNewRoundView = true

                    })
                    .padding(.top, 20)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                Spacer()
            }
            .padding(.horizontal)
            .onAppear {
                determineWinner()
                if fakeArtistAndQuestionMasterWins {
                    globalStateManager.incrementNumberOfTwoPoints(username: globalStateManager.fakeArtist)
                    globalStateManager.incrementNumberOfTwoPoints(username: globalStateManager.questionMaster)
                }

                if playerWins {
                    globalStateManager.players.filter { $0 != globalStateManager.questionMaster && $0 != globalStateManager.fakeArtist }.forEach { player in
                        globalStateManager.incrementNumberOfOnePoints(username: player)
                    }
                }
            }
            .onReceive(self.globalStateManager.$allPlayersResettedRoundState) {
                allPlayersResettedRoundState in if allPlayersResettedRoundState == true {
                    showLoadingNewRoundView = false
                }
            }
        } else {
            LoadingNewRoundView()
                .background(VisualEffectView(effect: UIBlurEffect(style: .regular)))
                .transition(.scale.combined(with: .opacity))
                .ignoresSafeArea(.all)
        }
    }

    @ViewBuilder
    private func fakeArtistAndQuestionMasterView() -> some View {
        VStack {
            Image("fakeArtist")
                .resizable()
                .scaledToFit()
                .frame(height: 90)
            Text(globalStateManager.fakeArtist.count > 8 ? "\(globalStateManager.fakeArtist.prefix(5))..." : globalStateManager.fakeArtist)
                .fontWeight(.bold)
            HStack {
                Image("two_coin")
                Text("x1")
            }
        }

        VStack {
            Image("questionMaster")
                .resizable()
                .scaledToFit()
                .frame(height: 90)
            Text(globalStateManager.questionMaster.count > 8 ? "\(globalStateManager.questionMaster.prefix(5))..." : globalStateManager.questionMaster)
                .fontWeight(.bold)
            HStack {
                Image("two_coin")
                Text("x1")
            }
        }
    }

    @ViewBuilder
    private func playerWinsSection() -> some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

        if globalStateManager.players.count > 9 {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    playerWinsViews()
                }
            }
        } else {
            LazyVGrid(columns: columns, spacing: 20) {
                playerWinsViews()
            }
        }
    }

    @ViewBuilder
    private func playerWinsViews() -> some View {
        ForEach(globalStateManager.players.filter { $0 != globalStateManager.questionMaster && $0 != globalStateManager.fakeArtist }, id: \.self) { player in
            VStack {
                Image("player")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 90)
                Text(player.count > 8 ? "\(player.prefix(5))..." : player)
                    .fontWeight(.bold)
                    .padding(.vertical, 1)
                HStack {
                    Image("one_coin")
                    Text("x1")
                }
            }
        }
    }

    private func determineWinner() {
        let votes = globalStateManager.votesForFakeArtist
        let fakeArtistVotes = votes[globalStateManager.fakeArtist] ?? 0
        let maxVotes = votes.values.max() ?? 0

        if fakeArtistVotes != maxVotes || votes.values.filter({ $0 == maxVotes }).count > 1 {
            fakeArtistAndQuestionMasterWins = true
        } 
        else if globalStateManager.fakeArtistGuessedTitleCorrectly == true {
            fakeArtistAndQuestionMasterWins = true
        } else {
            playerWins = true
        }
    }
}

struct PointsDistributionView_Previews: PreviewProvider {
    static var previews: some View {
        let mockGlobalStateManager = GlobalStateManager.shared
        mockGlobalStateManager.votesForFakeArtist = ["hello": 4, "goodbye": 3]
        mockGlobalStateManager.fakeArtist = "goodbye"
        mockGlobalStateManager.questionMaster = "hello"
        mockGlobalStateManager.players = ["hello", "goodbye", "khalid", "sup", "nope", "right", "yes", "alpha", "bravo", "charlie", "delta"]
        return PointsDistributionView(globalStateManager: mockGlobalStateManager)
    }
}
