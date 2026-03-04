import SpriteKit

final class HUDNode: SKNode {
    private var levelLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var livesNode: SKNode!
    private var streakLabel: SKLabelNode!
    private var beamIndicators: [SKShapeNode] = []

    private var ageGroup: AgeGroup = .cadet
    private var sceneSize: CGSize = .zero
    private var backButton: SKNode!

    var problemDisplay: ProblemDisplayNode!
    var onBackTapped: (() -> Void)?

    func setup(size: CGSize, ageGroup: AgeGroup, safeAreaTop: CGFloat = 0) {
        self.sceneSize = size
        self.ageGroup = ageGroup
        removeAllChildren()
        zPosition = 100

        let topInset = max(safeAreaTop, 10)

        // === TOP ROW: Problem display full width below safe area ===
        problemDisplay = ProblemDisplayNode()
        problemDisplay.setup(ageGroup: ageGroup, width: size.width)
        problemDisplay.position = CGPoint(x: size.width / 2, y: size.height - topInset - 30)
        addChild(problemDisplay)

        // === SECOND ROW: Back button + Lives (left), Score (right) ===
        let secondRowY = size.height - topInset - 70

        // Back button - top left
        backButton = SKNode()
        backButton.position = CGPoint(x: 30, y: secondRowY)
        backButton.zPosition = 101
        backButton.name = "backButton"

        let backBg = SKShapeNode(rectOf: CGSize(width: 44, height: 30), cornerRadius: 8)
        backBg.fillColor = SKColor(white: 0.15, alpha: 0.7)
        backBg.strokeColor = SKColor(white: 0.4, alpha: 0.6)
        backBg.lineWidth = 1.0
        backButton.addChild(backBg)

        let backArrow = SKLabelNode(text: "\u{25C0}")
        backArrow.fontName = "AvenirNext-Bold"
        backArrow.fontSize = 18
        backArrow.fontColor = .white
        backArrow.verticalAlignmentMode = .center
        backArrow.horizontalAlignmentMode = .center
        backButton.addChild(backArrow)

        addChild(backButton)

        // Lives - next to back button
        livesNode = SKNode()
        livesNode.position = CGPoint(x: 62, y: secondRowY - 4)
        addChild(livesNode)
        updateLives(ageGroup.lives)

        // Score - top right
        scoreLabel = SKLabelNode(text: "0")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: size.width - 15, y: secondRowY)
        addChild(scoreLabel)

        // === THIRD ROW: Level (left), Streak (right) ===
        let thirdRowY = secondRowY - 24

        // Level label
        levelLabel = SKLabelNode(text: "Level 1")
        levelLabel.fontName = "AvenirNext-Bold"
        levelLabel.fontSize = 14
        levelLabel.fontColor = ageGroup.primaryColor
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.verticalAlignmentMode = .center
        levelLabel.position = CGPoint(x: 15, y: thirdRowY)
        addChild(levelLabel)

        // Streak - right side
        streakLabel = SKLabelNode(text: "")
        streakLabel.fontName = "AvenirNext-Bold"
        streakLabel.fontSize = 16
        streakLabel.fontColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        streakLabel.horizontalAlignmentMode = .right
        streakLabel.verticalAlignmentMode = .center
        streakLabel.position = CGPoint(x: size.width - 15, y: thirdRowY)
        addChild(streakLabel)

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
        levelLabel.text = "Level \(level) - \(topic)"
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
        livesNode.removeAllChildren()
        let symbol = ageGroup == .cadet ? "\u{2B50}" : "\u{2764}\u{FE0F}"
        for i in 0..<lives {
            let heart = SKLabelNode(text: symbol)
            heart.fontSize = 16
            heart.position = CGPoint(x: CGFloat(i) * 20, y: 0)
            livesNode.addChild(heart)
        }
    }

    func updateStreak(_ streak: Int) {
        if streak >= 3 {
            streakLabel.text = "\u{1F525} x\(streak)"
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

    func showMessage(_ text: String, color: SKColor = .white) {
        let msg = SKLabelNode(text: text)
        msg.fontName = "AvenirNext-Bold"
        msg.fontSize = ageGroup == .cadet ? 32 : 26
        msg.fontColor = color
        msg.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        msg.zPosition = 200
        msg.setScale(0.1)
        addChild(msg)

        let appear = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.3),
            SKAction.fadeIn(withDuration: 0.2)
        ])
        let wait = SKAction.wait(forDuration: 1.0)
        let disappear = SKAction.group([
            SKAction.scale(to: 1.5, duration: 0.3),
            SKAction.fadeOut(withDuration: 0.3)
        ])
        msg.run(SKAction.sequence([appear, wait, disappear, SKAction.removeFromParent()]))
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
        let dist = hypot(localPos.x - backButton.position.x, localPos.y - backButton.position.y)
        if dist < 30 {
            let press = SKAction.sequence([
                SKAction.scale(to: 0.85, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            backButton.run(press)
            onBackTapped?()
            return true
        }
        return false
    }
}
