import Combine
import SwiftUI

class GlobalStateManager: ObservableObject {
    static let shared = GlobalStateManager()
    
    @Published var username: String = ""
    @Published var players: [String] = []
    @Published var communicationConnectionId: String = ""
    @Published var gameCode: String = ""
    @Published var gameEnded: Bool = false
    @Published var gameCodeInvalid: Bool = false
    @Published var usernameInUse: Bool = false
    @Published var gameInProgress: Bool = false
    @Published var gameFull: Bool = false
    
    func addPlayer(player: String) {
        players.append(player)
    }
    
    func setUsername(usernameToSet: String) {
        username = usernameToSet
    }
    
    func setCommunicationConnectionId(connectionId: String) {
        communicationConnectionId = connectionId
    }
    
    func setGameCode(gameCodeToSet: String) {
        gameCode = gameCodeToSet
    }
    
    func setGameEnded(isGameEnded: Bool) {
        DispatchQueue.main.async {
            self.gameEnded = isGameEnded
        }
    }
    
    func setGameCodeInvalid(isGameCodeInvalid: Bool) {
        DispatchQueue.main.async {
            self.gameCodeInvalid = isGameCodeInvalid
        }
    }
    
    func setUsernameInUse(isUsernameInUse: Bool) {
        DispatchQueue.main.async {
            self.usernameInUse = isUsernameInUse
        }
    }
    
    func setGameInProgress(isGameInProgress: Bool) {
        DispatchQueue.main.async {
            self.gameInProgress = isGameInProgress
        }
    }
    
    func setGameFull(isGameFull: Bool) {
        DispatchQueue.main.async {
            self.gameFull = isGameFull
        }
    }
}
