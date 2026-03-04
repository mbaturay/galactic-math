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
        let barHeight: CGFloat = 56
        let barCenterY = size.height - topInset - barHeight / 2

        // === DARK BACKGROUND BAR ===
        let barBg = SKShapeNode(rectOf: CGSize(width: size.width, height: barHeight))
        barBg.position = CGPoint(x: size.width / 2, y: barCenterY)
        barBg.fillColor = SKColor(white: 0.0, alpha: 0.55)
        barBg.strokeColor = .clear
        barBg.zPosition = 99
        addChild(barBg)

        // === LEFT: Pause icon (no background) ===
        pauseButton = SKNode()
        pauseButton.position = CGPoint(x: 30, y: barCenterY)
        pauseButton.zPosition = 101
        pauseButton.name = "pauseButton"

        let pauseIcon = SKLabelNode(text: "⏸")
        pauseIcon.fontSize = 30
        pauseIcon.fontColor = SKColor(white: 1.0, alpha: 0.7)
        pauseIcon.verticalAlignmentMode = .center
        pauseIcon.horizontalAlignmentMode = .center
        pauseButton.addChild(pauseIcon)
        addChild(pauseButton)

        // === MIDDLE: Player name (line 1) + ❤️ lives (line 2) ===
        let midX = size.width / 2

        let profile = GameManager.shared.currentProfile
        playerNameLabel = SKLabelNode(text: (profile?.name ?? "").uppercased())
        playerNameLabel.fontName = "AvenirNext-Bold"
        playerNameLabel.fontSize = 16
        playerNameLabel.fontColor = .white
        playerNameLabel.horizontalAlignmentMode = .center
        playerNameLabel.verticalAlignmentMode = .center
        playerNameLabel.position = CGPoint(x: midX, y: barCenterY + 10)
        addChild(playerNameLabel)

        livesLabel = SKLabelNode(text: "❤️ \(ageGroup.lives)")
        livesLabel.fontName = "AvenirNext-Bold"
        livesLabel.fontSize = 14
        livesLabel.fontColor = .white
        livesLabel.horizontalAlignmentMode = .center
        livesLabel.verticalAlignmentMode = .center
        livesLabel.position = CGPoint(x: midX, y: barCenterY - 10)
        addChild(livesLabel)

        // === RIGHT: Score (line 1) + Level (line 2) ===
        scoreLabel = SKLabelNode(text: "0")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: size.width - 15, y: barCenterY + 8)
        addChild(scoreLabel)

        levelLabel = SKLabelNode(text: "Level 1")
        levelLabel.fontName = "AvenirNext-Medium"
        levelLabel.fontSize = 11
        levelLabel.fontColor = ageGroup.primaryColor
        levelLabel.horizontalAlignmentMode = .right
        levelLabel.verticalAlignmentMode = .center
        levelLabel.position = CGPoint(x: size.width - 15, y: barCenterY - 12)
        addChild(levelLabel)

        // Streak — kept for API compatibility, not displayed in bar
        streakLabel = SKLabelNode(text: "")
        streakLabel.fontName = "AvenirNext-Bold"
        streakLabel.fontSize = 14
        streakLabel.fontColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)

        // === QUESTION PANEL below bar (top-anchored) ===
        problemDisplay = ProblemDisplayNode()
        problemDisplay.setup(ageGroup: ageGroup, width: size.width)
        problemDisplay.position = CGPoint(x: size.width / 2, y: barCenterY - barHeight / 2 - 4)
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
        levelLabel.text = "Lv.\(level) · \(topic)"
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
        // Streak feedback is handled via showMessage() — no bar display
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
        if dist < 35 {
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
