import SocketIO
import SwiftUI

@main
struct fake_artist_iosApp: App {
    let drawingSocketManager = DrawingWebSocketManager.shared
    let communicationWebSocketManager = CommunicationWebSocketManager.shared

    var body: some Scene {
        WindowGroup {
            Home()
                .onAppear {
                    drawingSocketManager.establishDrawingSocketConnection()
                    communicationWebSocketManager.setupCommunicationSocket()
                }
                .onDisappear {
                    drawingSocketManager.closeDrawingSocketConnection()
                    communicationWebSocketManager.disconnect()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    drawingSocketManager.closeDrawingSocketConnection()
                    communicationWebSocketManager.disconnect()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    drawingSocketManager.establishDrawingSocketConnection()
                    communicationWebSocketManager.setupCommunicationSocket()
                }
        }
    }
}
