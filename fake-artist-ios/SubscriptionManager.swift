import Combine

class SubscriptionManager: ObservableObject {
    var cancellables = Set<AnyCancellable>()
    
    let playerWithFiveOrMorePointsPublisher = PassthroughSubject<String, Never>()

    func setupSubscriptions(globalStateManager: GlobalStateManager) {
        globalStateManager.pointUpdates
            .sink { [weak self] _ in
                guard let self = self, let player = self.findPlayerWithFiveOrMorePoints(globalStateManager: globalStateManager), !player.isEmpty else { return }
                self.playerWithFiveOrMorePointsPublisher.send(player)
            }
            .store(in: &cancellables)
    }

    private func findPlayerWithFiveOrMorePoints(globalStateManager: GlobalStateManager) -> String? {
        let playerToNumberOfOneCoins = globalStateManager.numberOfOnePoints
        let playerToNumberOfTwoCoins = globalStateManager.numberOfTwoPoints
        let allPlayers = Set(playerToNumberOfOneCoins.keys).union(playerToNumberOfTwoCoins.keys)
        for player in allPlayers {
            let oneCoins = playerToNumberOfOneCoins[player] ?? 0
            let twoCoins = playerToNumberOfTwoCoins[player] ?? 0
            let totalPoints = oneCoins + 2 * twoCoins
            if totalPoints >= 5 {
                return player
            }
        }
        return nil
    }
}
