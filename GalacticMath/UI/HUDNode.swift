import SpriteKit

final class HUDNode: SKNode {
    private var levelLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var livesLabel: SKLabelNode!
    private var streakLabel: SKLabelNode!
    private var beamIndicators: [SKShapeNode] = []

    private var playerNameLabel: SKLabelNode!
    private var pauseButton: SKNode!
    private var ageGroup: AgeGroup = .cadet
    private var sceneSize: CGSize = .zero

    // Message queue — never overlap
    private var messageQueue: [(text: String, color: SKColor)] = []
    private var isShowingMessage = false

    var problemDisplay: ProblemDisplayNode!
    var onPauseTapped: (() -> Void)?

    static func animalEmoji(for ageGroup: AgeGroup) -> String {
        switch ageGroup {
        case .cadet: return "🐱"
        case .pilot: return "🐶"
        case .ace:   return "🦊"
        }
    }

    func setup(size: CGSize, ageGroup: AgeGroup, safeAreaTop: CGFloat = 0) {
        self.sceneSize = size
        self.ageGroup = ageGroup
        removeAllChildren()
        messageQueue.removeAll()
        isShowingMessage = false
        zPosition = 100

        let topInset = max(safeAreaTop, 10)

        // === ROW 1: Pause (left), Player name (center-left), Score (right) ===
        let row1Y = size.height - topInset - 22

        // Pause button
        pauseButton = SKNode()
        pauseButton.position = CGPoint(x: 28, y: row1Y)
        pauseButton.zPosition = 101
        pauseButton.name = "pauseButton"

        let pauseBg = SKShapeNode(rectOf: CGSize(width: 36, height: 30), cornerRadius: 8)
        pauseBg.fillColor = SKColor(white: 0.15, alpha: 0.7)
        pauseBg.strokeColor = SKColor(white: 0.4, alpha: 0.6)
        pauseBg.lineWidth = 1.0
        pauseButton.addChild(pauseBg)

        let pauseIcon = SKLabelNode(text: "⏸")
        pauseIcon.fontSize = 16
        pauseIcon.verticalAlignmentMode = .center
        pauseIcon.horizontalAlignmentMode = .center
        pauseButton.addChild(pauseIcon)
        addChild(pauseButton)

        // Player name
        let profile = GameManager.shared.currentProfile
        playerNameLabel = SKLabelNode(text: profile?.name ?? "")
        playerNameLabel.fontName = "AvenirNext-Bold"
        playerNameLabel.fontSize = 14
        playerNameLabel.fontColor = SKColor(white: 0.85, alpha: 1.0)
        playerNameLabel.horizontalAlignmentMode = .left
        playerNameLabel.verticalAlignmentMode = .center
        playerNameLabel.position = CGPoint(x: 56, y: row1Y)
        addChild(playerNameLabel)

        // Score
        scoreLabel = SKLabelNode(text: "0")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: size.width - 15, y: row1Y)
        addChild(scoreLabel)

        // === ROW 2: Lives (left), Level (center), Streak (right) ===
        let row2Y = row1Y - 26

        // Lives: ❤️ 3
        livesLabel = SKLabelNode(text: "❤️ \(ageGroup.lives)")
        livesLabel.fontName = "AvenirNext-Bold"
        livesLabel.fontSize = 14
        livesLabel.fontColor = .white
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .center
        livesLabel.position = CGPoint(x: 15, y: row2Y)
        addChild(livesLabel)

        // Level
        levelLabel = SKLabelNode(text: "Level 1")
        levelLabel.fontName = "AvenirNext-Bold"
        levelLabel.fontSize = 13
        levelLabel.fontColor = ageGroup.primaryColor
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.verticalAlignmentMode = .center
        levelLabel.position = CGPoint(x: size.width / 2, y: row2Y)
        addChild(levelLabel)

        // Streak
        streakLabel = SKLabelNode(text: "")
        streakLabel.fontName = "AvenirNext-Bold"
        streakLabel.fontSize = 14
        streakLabel.fontColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        streakLabel.horizontalAlignmentMode = .right
        streakLabel.verticalAlignmentMode = .center
        streakLabel.position = CGPoint(x: size.width - 15, y: row2Y)
        addChild(streakLabel)

        // === QUESTION PANEL below HUD rows (top-anchored) ===
        problemDisplay = ProblemDisplayNode()
        problemDisplay.setup(ageGroup: ageGroup, width: size.width)
        // Panel top edge is at this y position; it expands downward
        problemDisplay.position = CGPoint(x: size.width / 2, y: row2Y - 12)
        addChild(problemDisplay)

        // Beam position indicators above touch controls
        setupBeamIndicators()
    }

    private func setupBeamIndicators() {
        for indicator in beamIndicators {
            indicator.removeFromParent()
        }
        beamIndicators.removeAll()

        let beamCount = ageGroup.beamCount
        let spacing: CGFloat = 30
        let startX = sceneSize.width / 2 - CGFloat(beamCount - 1) * spacing / 2
        let indicatorY: CGFloat = 100

        for i in 0..<beamCount {
            let dot = SKShapeNode(circleOfRadius: 5)
            let colors = ageGroup.beamColors
            dot.fillColor = colors[i % colors.count].withAlphaComponent(0.5)
            dot.strokeColor = colors[i % colors.count]
            dot.lineWidth = 1.0
            dot.position = CGPoint(x: startX + CGFloat(i) * spacing, y: indicatorY)
            addChild(dot)
            beamIndicators.append(dot)
        }
    }

    func updateLevel(_ level: Int, topic: String) {
        levelLabel.text = "Level \(level) · \(topic)"
    }

    func updateScore(_ score: Int) {
        scoreLabel.text = "\(score)"
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        scoreLabel.run(pop)
    }

    func updateLives(_ lives: Int) {
        livesLabel.text = "❤️ \(lives)"
    }

    func updateStreak(_ streak: Int) {
        if streak >= 3 {
            streakLabel.text = "🔥 x\(streak)"
            if streak == 3 || streak == 5 {
                let pop = SKAction.sequence([
                    SKAction.scale(to: 1.5, duration: 0.15),
                    SKAction.scale(to: 1.0, duration: 0.15)
                ])
                streakLabel.run(pop)
            }
        } else {
            streakLabel.text = ""
        }
    }

    func updateActiveBeam(_ beam: Int) {
        for (i, dot) in beamIndicators.enumerated() {
            let colors = ageGroup.beamColors
            if i == beam {
                dot.fillColor = colors[i % colors.count]
                dot.setScale(1.3)
            } else {
                dot.fillColor = colors[i % colors.count].withAlphaComponent(0.3)
                dot.setScale(1.0)
            }
        }
    }

    // MARK: - Message Queue

    func showMessage(_ text: String, color: SKColor = .white) {
        messageQueue.append((text, color))
        displayNextMessageIfNeeded()
    }

    private func displayNextMessageIfNeeded() {
        guard !isShowingMessage, !messageQueue.isEmpty else { return }
        isShowingMessage = true
        let item = messageQueue.removeFirst()

        let msg = SKLabelNode(text: item.text)
        msg.fontName = "AvenirNext-Bold"
        msg.fontSize = ageGroup == .cadet ? 32 : 26
        msg.fontColor = item.color
        msg.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        msg.zPosition = 200
        msg.setScale(0.1)
        msg.alpha = 0
        addChild(msg)

        let appear = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.3),
            SKAction.fadeIn(withDuration: 0.2)
        ])
        let hold = SKAction.wait(forDuration: 2.0)
        let disappear = SKAction.group([
            SKAction.scale(to: 1.5, duration: 0.3),
            SKAction.fadeOut(withDuration: 0.3)
        ])

        msg.run(SKAction.sequence([
            appear,
            hold,
            disappear,
            SKAction.removeFromParent(),
            SKAction.run { [weak self] in
                self?.isShowingMessage = false
                self?.displayNextMessageIfNeeded()
            }
        ]))
    }

    func flashScreenEdge(color: SKColor) {
        let flash = SKShapeNode(rectOf: sceneSize)
        flash.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        flash.fillColor = color.withAlphaComponent(0.15)
        flash.strokeColor = .clear
        flash.zPosition = 150
        addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }

    func handleTap(at sceneLocation: CGPoint) -> Bool {
        let localPos = convert(sceneLocation, from: scene!)
        let dist = hypot(localPos.x - pauseButton.position.x, localPos.y - pauseButton.position.y)
        if dist < 30 {
            let press = SKAction.sequence([
                SKAction.scale(to: 0.85, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            pauseButton.run(press)
            onPauseTapped?()
            return true
        }
        return false
    }
}
