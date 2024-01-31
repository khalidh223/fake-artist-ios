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
    @Published var playerRole: String = ""
    @Published var colorToUsernameMap = [String: String]()
    @Published var userSelectedColorHex: String = ""
    @Published var playerToConfirmedColor = [String: String]()
    @Published var allPlayersConfirmedColor = false
    @Published var themeChosenByQuestionMaster = ""
    @Published var titleChosenByQuestionMaster = ""
    @Published var showDrawCanvasView = false
    @Published var showBlurEffect = false

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
    
    func setPlayerRole(_ role: String) {
        DispatchQueue.main.async {
            self.playerRole = role
        }
    }
    
    func setColorToUsernameMap(color: String, username: String) {
        DispatchQueue.main.async {
            for (existingColor, existingUsername) in self.colorToUsernameMap {
                if existingUsername == username {
                    self.colorToUsernameMap[existingColor] = nil
                }
            }

            self.colorToUsernameMap[color] = username
        }
    }
    
    func setUserSelectedColor(hex: String) {
        DispatchQueue.main.async {
            self.userSelectedColorHex = hex
        }
    }
    
    func setConfirmedColorForPlayer(color: String, username: String) {
        DispatchQueue.main.async {
            self.playerToConfirmedColor[username] = color
        }
    }
    
    func setShowDrawCanvasView(isDrawCanvasShown: Bool) {
        DispatchQueue.main.async {
            self.showDrawCanvasView = isDrawCanvasShown
        }
    }
}
