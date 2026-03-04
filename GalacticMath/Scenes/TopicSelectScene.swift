import SpriteKit

final class TopicSelectScene: SKScene {
    var selectedGrade: Grade = .kindergarten
    private var starField: StarField!

    override func didMove(to view: SKView) {
        backgroundColor = selectedGrade.backgroundColor

        starField = StarField()
        starField.setup(size: size, grade: selectedGrade)
        addChild(starField)

        addBackButton(atY: navBarY)

        let titleY = titleSafeY

        let title = SKLabelNode(text: "\(selectedGrade.emoji) \(selectedGrade.displayName)")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = min(size.width * 0.08, 32)
        title.fontColor = selectedGrade.primaryColor
        title.position = CGPoint(x: size.width / 2, y: titleY)
        title.zPosition = 10
        addChild(title)

        let profile = GameManager.shared.currentProfile
        let currentLevel = profile?.currentLevel(for: selectedGrade) ?? 1
        let topics = Curriculum.topicList(for: selectedGrade)

        let topicHeight: CGFloat = 56
        let spacing: CGFloat = 10
        let startY = contentStartY
        let topicWidth = min(size.width * 0.85, 320.0)

        for (i, topic) in topics.enumerated() {
            let y = startY - CGFloat(i) * (topicHeight + spacing)
            let levelsStart = i * 4 + 1
            let levelsEnd = i * 4 + 4

            let completed = min(max(currentLevel - levelsStart, 0), 4)
            let isCurrent = currentLevel >= levelsStart && currentLevel <= levelsEnd
            let isLocked = currentLevel < levelsStart

            let row = createTopicRow(
                topic: topic,
                completed: completed,
                isCurrent: isCurrent,
                isLocked: isLocked,
                width: topicWidth,
                height: topicHeight
            )
            row.position = CGPoint(x: size.width / 2, y: y)
            row.zPosition = 10
            addChild(row)
        }

        // Launch button
        let launchBtn = SKNode()
        launchBtn.position = CGPoint(x: size.width / 2, y: 40)
        launchBtn.zPosition = 10
        launchBtn.name = "launchButton"

        let btnSize = CGSize(width: min(size.width * 0.7, 220), height: 50)
        let btnBg = SKShapeNode(rectOf: btnSize, cornerRadius: 14)
        btnBg.fillColor = selectedGrade.primaryColor.withAlphaComponent(0.3)
        btnBg.strokeColor = selectedGrade.primaryColor.withAlphaComponent(0.8)
        btnBg.lineWidth = 2.5
        btnBg.glowWidth = 3.0
        launchBtn.addChild(btnBg)

        let btnLabel = SKLabelNode(text: "LAUNCH MISSION")
        btnLabel.fontName = "AvenirNext-Bold"
        btnLabel.fontSize = 20
        btnLabel.fontColor = .white
        btnLabel.verticalAlignmentMode = .center
        launchBtn.addChild(btnLabel)

        let glow = SKAction.sequence([
            SKAction.run { btnBg.glowWidth = 5.0 },
            SKAction.wait(forDuration: 0.8),
            SKAction.run { btnBg.glowWidth = 3.0 },
            SKAction.wait(forDuration: 0.8)
        ])
        launchBtn.run(SKAction.repeatForever(glow))

        addChild(launchBtn)
    }

    private func createTopicRow(topic: MathTopic, completed: Int, isCurrent: Bool, isLocked: Bool, width: CGFloat, height: CGFloat) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        if isCurrent {
            bg.fillColor = selectedGrade.primaryColor.withAlphaComponent(0.15)
            bg.strokeColor = selectedGrade.primaryColor.withAlphaComponent(0.6)
            bg.lineWidth = 2.0
        } else if isLocked {
            bg.fillColor = SKColor(white: 0.08, alpha: 0.4)
            bg.strokeColor = SKColor(white: 0.2, alpha: 0.3)
            bg.lineWidth = 1.0
        } else {
            bg.fillColor = SKColor(white: 0.12, alpha: 0.5)
            bg.strokeColor = SKColor(white: 0.3, alpha: 0.4)
            bg.lineWidth = 1.0
        }
        container.addChild(bg)

        let nameLabel = SKLabelNode(text: topic.displayName)
        nameLabel.fontName = isCurrent ? "AvenirNext-Bold" : "AvenirNext-Medium"
        nameLabel.fontSize = 15
        nameLabel.fontColor = isLocked ? SKColor(white: 0.4, alpha: 0.6) : .white
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: -width / 2 + 16, y: 6)
        container.addChild(nameLabel)

        // Progress dots
        let dotSpacing: CGFloat = 14
        let dotStartX = -width / 2 + 16
        for d in 0..<4 {
            let dot = SKShapeNode(circleOfRadius: 4)
            if d < completed {
                dot.fillColor = selectedGrade.primaryColor
                dot.strokeColor = selectedGrade.primaryColor
            } else {
                dot.fillColor = SKColor(white: 0.15, alpha: 0.5)
                dot.strokeColor = SKColor(white: 0.3, alpha: 0.5)
            }
            dot.lineWidth = 1.0
            dot.position = CGPoint(x: dotStartX + CGFloat(d) * dotSpacing, y: -12)
            container.addChild(dot)
        }

        // Status label
        let statusText: String
        if completed >= 4 {
            statusText = "\u{2705}"
        } else if isCurrent {
            statusText = "\u{25B6}\u{FE0F}"
        } else if isLocked {
            statusText = "\u{1F512}"
        } else {
            statusText = ""
        }
        let statusLabel = SKLabelNode(text: statusText)
        statusLabel.fontSize = 18
        statusLabel.verticalAlignmentMode = .center
        statusLabel.position = CGPoint(x: width / 2 - 24, y: 0)
        container.addChild(statusLabel)

        return container
    }

    private func addBackButton(atY y: CGFloat) {
        let backBtn = SKNode()
        backBtn.position = CGPoint(x: 51, y: y)
        backBtn.zPosition = 10
        backBtn.name = "backButton"

        let backBg = SKShapeNode(rectOf: CGSize(width: 70, height: 28), cornerRadius: 8)
        backBg.fillColor = SKColor(white: 0.15, alpha: 0.7)
        backBg.strokeColor = SKColor(white: 0.4, alpha: 0.5)
        backBtn.addChild(backBg)

        let backLabel = SKLabelNode(text: "\u{25C0} Back")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 14
        backLabel.fontColor = SKColor(white: 0.7, alpha: 0.9)
        backLabel.verticalAlignmentMode = .center
        backBtn.addChild(backLabel)

        addChild(backBtn)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        AudioManager.shared.playMenuTap()

        if let backBtn = childNode(withName: "backButton") {
            let dist = hypot(location.x - backBtn.position.x, location.y - backBtn.position.y)
            if dist < 50 {
                let scene = GradeSelectScene(size: size)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.5))
                return
            }
        }

        if let launchBtn = childNode(withName: "launchButton") {
            let dist = hypot(location.x - launchBtn.position.x, location.y - launchBtn.position.y)
            if dist < 60 {
                let gm = GameManager.shared
                gm.startNewGame(grade: selectedGrade)
                let gameScene = GameScene(size: size)
                gameScene.scaleMode = .resizeFill
                gameScene.selectedGrade = selectedGrade
                view?.presentScene(gameScene, transition: SKTransition.doorway(withDuration: 1.0))
                return
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)
    }
}
