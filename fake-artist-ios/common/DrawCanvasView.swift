import SwiftUI

struct DrawCanvasView: View {
    @ObservedObject var globalStateManager = GlobalStateManager.shared
    @ObservedObject var canvasCommunicationWebSocketManager = CanvasCommunicationWebSocketManager.shared
    @ObservedObject var drawingWebSocketManager = DrawingWebSocketManager.shared
    @State private var paths = [DrawingPath]()
    @State private var lastPoint: CGPoint? = nil
    // Threshold to decide when the sheet should snap to open or closed
    private let threshold: CGFloat = 100
    // The height of the partially opened sheet
    private let partialSheetHeight: CGFloat = 130
    // State to manage the offset of the sheet
    @State private var offset = CGSize.zero
    // State to manage the overall position of the sheet (false for partially open, true for fully open)
    @State private var isSheetOpen = false
    @State private var numberOfDrawings = 0
    @State private var numberOfRounds = 0
    @State private var isCurrentPlayerDrawingOverlayVisible = false
    @State private var isViewVotingButtonVisible = false
    @State private var overlayText = ""

    let maxDrawings = 2
    let maxRounds = 2

    var body: some View {
        ZStack {
            // Background content
            Color(.white)
            VStack {
                Canvas { context, _ in
                    for drawingPath in self.paths {
                        var path = Path()
                        path.move(to: CGPoint(x: drawingPath.startX, y: drawingPath.startY))
                        path.addLine(to: CGPoint(x: drawingPath.endX, y: drawingPath.endY))
                        context.stroke(path, with: .color(drawingPath.color), lineWidth: 4)
                    }
                }.ignoresSafeArea(.all)
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            if self.globalStateManager.currentPlayerDrawing == self.globalStateManager.username, !self.globalStateManager.stoppedGame {
                                self.handleDrawing(value: value)
                            }
                        }
                        .onEnded { _ in
                            self.handleGestureEnded()
                        }
                    )
                    .onReceive(self.drawingWebSocketManager.$receivedDrawingData) { data in
                        guard let data = data else { return }
                        self.addPath(from: data)
                    }
            }.ignoresSafeArea(.all)

            if self.isViewVotingButtonVisible {
                VStack {
                    HomeButton(text: "View Voting") {
                        self.globalStateManager.showVoteFakeArtistView = true
                    }
                    .padding()
                    .cornerRadius(8)
                    .padding(.top, 60)
                    Spacer()
                }
            }

            // Draggable Sheet
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    VStack(alignment: .center) {
                        // Handle area
                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: 40, height: 5)
                            .padding()
                        HStack {
                            RoundedBoxView(text: self.globalStateManager.themeChosenByQuestionMaster, title: "theme", backgroundColor: Color(hex: "#FDAECD")!)
                            Spacer()
                            RoundedBoxView(text: self.globalStateManager.titleChosenByQuestionMaster == "" ? "???" : self.globalStateManager.titleChosenByQuestionMaster, title: "title", backgroundColor: Color(hex: "#FDAECD")!)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        Spacer()
                        ScrollView {
                            Spacer()
                            Spacer()
                            VStack(alignment: .leading) {
                                ForEach(self.globalStateManager.players.sorted { $0.lowercased() < $1.lowercased() }, id: \.self) { player in
                                    HStack {
                                        if player == self.globalStateManager.currentPlayerDrawing && player != self.globalStateManager.questionMaster {
                                            Image(systemName: "arrow.right")
                                                .foregroundColor(.black)
                                                .scaleEffect(1.3)
                                        } else {
                                            Image(systemName: "arrow.right")
                                                .foregroundColor(.clear) // Make the placeholder arrow transparent
                                                .scaleEffect(1.3) // Ensure the placeholder matches the size of the actual arrow
                                        }
                                        Image(player != self.globalStateManager.questionMaster ? "player" : "questionMaster")
                                            .resizable()
                                            .scaledToFill()
                                            .scaleEffect(0.6)
                                            .offset(y: 5)
                                            .frame(width: 45, height: 45)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.black, lineWidth: 1))
                                            .foregroundColor(.black)

                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(player).fontWeight(.bold)
                                            let playerConfirmedColor = self.globalStateManager.playerToConfirmedColor[player] ?? ""
                                            let colorHex = self.hexColorFor(penColor: playerConfirmedColor)

                                            Rectangle()
                                                .fill(Color(hex: colorHex) ?? Color.black)
                                                .frame(width: 50, height: 10)
                                        }
                                        HStack(alignment: .center, spacing: 1) {
                                            Image("one_coin")
                                                .scaleEffect(0.8)
                                            Text("x\(globalStateManager.numberOfOnePoints[player] ?? 0)")
                                            Image("two_coin")
                                                .scaleEffect(0.8)
                                            Text("x\(globalStateManager.numberOfTwoPoints[player] ?? 0)")
                                        }
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height / 2)
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .offset(y: self.isSheetOpen ? 0 : geometry.size.height / 2 - self.partialSheetHeight)
                    .offset(y: self.offset.height)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                self.offset = gesture.translation
                            }
                            .onEnded { gesture in
                                let verticalMovement = gesture.translation.height
                                if verticalMovement > self.threshold {
                                    self.isSheetOpen = false
                                } else if verticalMovement < -self.threshold {
                                    self.isSheetOpen = true
                                }
                                self.offset = .zero
                            }
                    )
                    .animation(.linear(duration: 0.2), value: self.isSheetOpen)
                }
            }.ignoresSafeArea(.all)

            // Opaque overlay
            if self.isCurrentPlayerDrawingOverlayVisible {
                ZStack {
                    Color.white.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            self.isCurrentPlayerDrawingOverlayVisible = false
                        }

                    Text(self.overlayText)
                        .font(.title)
                        .foregroundColor(.black)
                        .transition(.opacity)
                        .animation(.easeInOut, value: self.isCurrentPlayerDrawingOverlayVisible)
                }.ignoresSafeArea(.all)
            } else if self.globalStateManager.showVoteFakeArtistView {
                VoteForPlayersOverlayView()
                    .background(VisualEffectView(effect: UIBlurEffect(style: .regular)))
                    .transition(.scale.combined(with: .opacity))
                    .ignoresSafeArea(.all)
            }
        }.ignoresSafeArea(.all)
            .onReceive(self.globalStateManager.$currentPlayerDrawing) { currentPlayerDrawing in
                if currentPlayerDrawing == self.globalStateManager.username {
                    self.overlayText = "Your turn to draw!"
                } else {
                    self.overlayText = "\(currentPlayerDrawing) is drawing"
                }
                self.isCurrentPlayerDrawingOverlayVisible = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.isCurrentPlayerDrawingOverlayVisible = false
                }
            }
            .onReceive(self.globalStateManager.$stoppedGame) {
                stoppedGame in if stoppedGame == true { self.isViewVotingButtonVisible = true
                    self.globalStateManager.showVoteFakeArtistView = true
                }
            }
            .onReceive(self.globalStateManager.$allPlayersResettedRoundState) {
                allPlayersResettedRoundState in if allPlayersResettedRoundState == true {
                    numberOfDrawings = 0
                    numberOfRounds = 0
                    paths.removeAll()
                }
            }
    }

    private func handleGestureEnded() {
        self.lastPoint = nil

        let sortedPlayers = self.globalStateManager.players.sorted { $0.lowercased() < $1.lowercased() }.filter { player in player != self.globalStateManager.questionMaster }
        let isLastSortedPlayerCurrentlyDrawing = sortedPlayers.last == self.globalStateManager.currentPlayerDrawing && sortedPlayers.last == self.globalStateManager.username
        if self.numberOfDrawings == self.maxDrawings - 1 && self.numberOfRounds == self.maxRounds - 1 && isLastSortedPlayerCurrentlyDrawing {
            self.canvasCommunicationWebSocketManager.sendStopGame(gameCode: self.globalStateManager.gameCode)
            self.numberOfRounds = 0
        }

        if self.globalStateManager.currentPlayerDrawing == self.globalStateManager.username {
            self.numberOfDrawings += 1
            if self.numberOfDrawings == self.maxDrawings && self.numberOfRounds != self.maxRounds {
                self.canvasCommunicationWebSocketManager.sendPlayerStoppedDrawing(username: self.globalStateManager.username, gameCode: self.globalStateManager.gameCode)
                self.numberOfDrawings = 0
                self.numberOfRounds += 1
            }
        }
    }

    private func hexColorFor(penColor: String) -> String {
        guard let colorChoice = colors.first(where: { $0.penColor == penColor }) else {
            return "#FFFFFF"
        }
        return colorChoice.hex
    }

    private func handleDrawing(value: DragGesture.Value) {
        let currentPoint = value.location
        let previousPoint = self.lastPoint ?? currentPoint

        let drawingData: [String: Any] = [
            "x": currentPoint.x,
            "y": currentPoint.y,
            "prevX": previousPoint.x,
            "prevY": previousPoint.y,
            "color": self.globalStateManager.userSelectedColorHex,
            "gameCode": self.globalStateManager.gameCode
        ]

        self.drawingWebSocketManager.sendDrawingMessage("drawingData", data: drawingData)

        self.lastPoint = currentPoint
    }

    private func addPath(from data: DrawingData) {
        guard let color = Color(hex: data.color) else { return }
        let newPath = DrawingPath(startX: data.prevX, startY: data.prevY, endX: data.x, endY: data.y, color: color)
        self.paths.append(newPath)
    }
}

struct RoundedBoxView: View {
    let text: String
    let title: String
    let backgroundColor: Color
    var width: CGFloat = 162
    var height: CGFloat = 50

    var body: some View {
        VStack(spacing: 6) {
            Text(self.title)
                .font(Font.system(size: 12))
                .foregroundColor(Color(hex: "#D26692"))
            Text(self.text)
                .font(Font.system(size: 20).weight(.bold))
                .foregroundColor(Color(hex: "#C15F87"))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.leading)
        }
        .frame(maxWidth: .infinity, minHeight: self.height, alignment: .leading)
        .background(self.backgroundColor)
        .cornerRadius(5)
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

struct DrawCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        let mockGlobalStateManager = GlobalStateManager()
        mockGlobalStateManager.showVoteFakeArtistView = true
        mockGlobalStateManager.themeChosenByQuestionMaster = "Animal"
        mockGlobalStateManager.titleChosenByQuestionMaster = "Lion"
        mockGlobalStateManager.userSelectedColorHex = "#954A13"
        mockGlobalStateManager.currentPlayerDrawing = "hello"
        mockGlobalStateManager.username = ""
        mockGlobalStateManager.playerRole = "PLAYER"
        mockGlobalStateManager.players = ["hello", "goodbye", "khalid", "sup", "nope", "wow", "all", "yes"]
        mockGlobalStateManager.playerToConfirmedColor = ["hello": "black", "goodbye": "brown", "khalid": "darkblue", "sup": "darkpink", "nope": "lightgreen", "wow": "lightblue", "all": "orange", "yes": "purple"]
        return DrawCanvasView(globalStateManager: mockGlobalStateManager)
    }
}
