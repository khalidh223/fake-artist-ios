import SwiftUI

struct DrawCanvasView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared
    @ObservedObject var canvasCommunicationWebSocketManager = CanvasCommunicationWebSocketManager.shared
    @ObservedObject var drawingWebSocketManager = DrawingWebSocketManager.shared
    @State private var paths = [DrawingPath]()
    @State private var lastPoint: CGPoint? = nil

    var body: some View {
        ZStack {
            Color(.white)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Canvas { context, _ in
                    for drawingPath in paths {
                        var path = Path()
                        path.move(to: CGPoint(x: drawingPath.startX, y: drawingPath.startY))
                        path.addLine(to: CGPoint(x: drawingPath.endX, y: drawingPath.endY))
                        context.stroke(path, with: .color(drawingPath.color), lineWidth: 4)
                    }
                }
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        handleDrawing(value: value)
                    }
                    .onEnded { _ in
                        lastPoint = nil
                    }
                )
                .onReceive(drawingWebSocketManager.$receivedDrawingData) { data in
                    guard let data = data else { return }
                    addPath(from: data)
                }
            }
        }
    }

    private func handleDrawing(value: DragGesture.Value) {
        let currentPoint = value.location
        let previousPoint = lastPoint ?? currentPoint

        // Prepare data to send
        let drawingData: [String: Any] = [
            "x": currentPoint.x,
            "y": currentPoint.y,
            "prevX": previousPoint.x,
            "prevY": previousPoint.y,
            "color": globalStateManager.userSelectedColorHex,
            "gameCode": globalStateManager.gameCode
        ]

        print("Drawing at: \(currentPoint)")

        // Send data to WebSocket
        drawingWebSocketManager.sendDrawingMessage("drawingData", data: drawingData)

        // Update the last point
        lastPoint = currentPoint
    }

    private func addPath(from data: DrawingData) {
        guard let color = Color(hex: data.color) else { return }
        let newPath = DrawingPath(startX: data.prevX, startY: data.prevY, endX: data.x, endY: data.y, color: color)
        print("Received path data: \(data)")
        paths.append(newPath)
    }
}

extension Color {
    init?(hex: String) {
        let r, g, b: Double

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = Double((hexNumber & 0xff0000) >> 16) / 255
                    g = Double((hexNumber & 0x00ff00) >> 8) / 255
                    b = Double(hexNumber & 0x0000ff) / 255

                    self.init(red: r, green: g, blue: b)
                    return
                }
            }
        }

        return nil
    }
}

struct DrawingPath {
    var startX: Double
    var startY: Double
    var endX: Double
    var endY: Double
    var color: Color
}
