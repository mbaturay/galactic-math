import SpriteKit

final class TitleScene: SKScene {
    private var starField: StarField!
    private var titleLabel: SKLabelNode!
    private var subtitleLabel: SKLabelNode!
    private var tapLabel: SKLabelNode!
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.01, blue: 0.1, alpha: 1.0)

        // Star field
        starField = StarField()
        starField.setup(size: size, grade: .grade3)
        addChild(starField)

        // Title
        titleLabel = SKLabelNode(text: "GALACTIC MATH")
        titleLabel.fontName = "AvenirNext-Heavy"
        titleLabel.fontSize = min(size.width * 0.11, 52)
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        // Title glow animation
        let glow = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.titleLabel.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
            },
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.titleLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
            },
            SKAction.wait(forDuration: 1.0)
        ])
        titleLabel.run(SKAction.repeatForever(glow))

        // Subtitle
        subtitleLabel = SKLabelNode(text: "Learn Math in Space!")
        subtitleLabel.fontName = "AvenirNext-Medium"
        subtitleLabel.fontSize = min(size.width * 0.05, 22)
        subtitleLabel.fontColor = SKColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.68 - 40)
        subtitleLabel.zPosition = 10
        addChild(subtitleLabel)

        // Animated rocket
        spawnFlyingRocket()

        // Tap to start
        tapLabel = SKLabelNode(text: "TAP TO START")
        tapLabel.fontName = "AvenirNext-Bold"
        tapLabel.fontSize = min(size.width * 0.06, 26)
        tapLabel.fontColor = .white
        tapLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.30)
        tapLabel.zPosition = 10
        addChild(tapLabel)

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        tapLabel.run(SKAction.repeatForever(pulse))

        // High scores per grade
        let gm = GameManager.shared
        var yPos = size.height * 0.22
        for grade in Grade.allCases {
            if let best = gm.slots.values.filter({ $0.currentGrade == grade || $0.highScore(for: grade) > 0 }).max(by: { $0.highScore(for: grade) < $1.highScore(for: grade) }), best.highScore(for: grade) > 0 {
                let scoreLabel = SKLabelNode(text: "\(grade.shortName): \(best.highScore(for: grade))")
                scoreLabel.fontName = "AvenirNext-Medium"
                scoreLabel.fontSize = 14
                scoreLabel.fontColor = grade.primaryColor.withAlphaComponent(0.7)
                scoreLabel.position = CGPoint(x: size.width / 2, y: yPos)
                scoreLabel.zPosition = 10
                addChild(scoreLabel)
                yPos -= 22
            }
        }

        // Parents button
        let parentsBtn = createButton(text: "Parents", position: CGPoint(x: size.width - 50, y: 30), fontSize: 12)
        parentsBtn.name = "parentsButton"
        addChild(parentsBtn)

        // Credits
        let credits = SKLabelNode(text: "Educational Game")
        credits.fontName = "AvenirNext-Regular"
        credits.fontSize = 11
        credits.fontColor = SKColor(white: 0.5, alpha: 0.6)
        credits.position = CGPoint(x: size.width / 2, y: 12)
        credits.zPosition = 10
        addChild(credits)
    }

    private func spawnFlyingRocket() {
        let rocket = SKLabelNode(text: "\u{1F680}")
        rocket.fontSize = 45
        rocket.position = CGPoint(x: -40, y: size.height * 0.55)
        rocket.zPosition = 5
        addChild(rocket)

        let fly = SKAction.sequence([
            SKAction.move(to: CGPoint(x: size.width + 40, y: size.height * 0.58), duration: 4.0),
            SKAction.move(to: CGPoint(x: -40, y: size.height * 0.52), duration: 0),
            SKAction.wait(forDuration: 2.0)
        ])
        rocket.run(SKAction.repeatForever(fly))
    }

    private func createButton(text: String, position: CGPoint, fontSize: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 10

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Medium"
        label.fontSize = fontSize
        label.fontColor = SKColor(white: 0.6, alpha: 0.8)
        label.verticalAlignmentMode = .center
        container.addChild(label)

        let bg = SKShapeNode(rectOf: CGSize(width: label.frame.width + 20, height: label.frame.height + 10), cornerRadius: 5)
        bg.fillColor = SKColor(white: 0.2, alpha: 0.5)
        bg.strokeColor = SKColor(white: 0.4, alpha: 0.5)
        bg.lineWidth = 1.0
        bg.zPosition = -1
        container.addChild(bg)

        return container
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check parents button
        if let parentsBtn = childNode(withName: "parentsButton") {
            let distance = hypot(location.x - parentsBtn.position.x, location.y - parentsBtn.position.y)
            if distance < 50 {
                transitionToParentGate()
                return
            }
        }

        AudioManager.shared.playMenuTap()
        transitionToProfileSelect()
    }

    private func transitionToProfileSelect() {
        let transition = SKTransition.push(with: .left, duration: 0.5)
        let profileScene = ProfileSelectScene(size: size)
        profileScene.scaleMode = .resizeFill
        view?.presentScene(profileScene, transition: transition)
    }

    private func transitionToParentGate() {
        let transition = SKTransition.push(with: .up, duration: 0.5)
        let gateScene = ParentGateScene(size: size)
        gateScene.scaleMode = .resizeFill
        view?.presentScene(gateScene, transition: transition)
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)
    }
}

// MARK: - Parent Gate Scene
final class ParentGateScene: SKScene {
    private var answerLabel: SKLabelNode!
    private var currentAnswer: String = ""
    private let correctAnswer = 28
    private var starField: StarField!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.01, blue: 0.1, alpha: 1.0)

        starField = StarField()
        starField.setup(size: size, grade: .grade3)
        addChild(starField)

        let topY = titleSafeY

        let title = SKLabelNode(text: "Parent Access")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 28
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: topY)
        title.zPosition = 10
        addChild(title)

        let question = SKLabelNode(text: "What is 4 x 7?")
        question.fontName = "AvenirNext-Medium"
        question.fontSize = 24
        question.fontColor = SKColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 1.0)
        question.position = CGPoint(x: size.width / 2, y: contentStartY)
        question.zPosition = 10
        addChild(question)

        answerLabel = SKLabelNode(text: "_")
        answerLabel.fontName = "AvenirNext-Bold"
        answerLabel.fontSize = 36
        answerLabel.fontColor = .white
        answerLabel.position = CGPoint(x: size.width / 2, y: contentStartY - 60)
        answerLabel.zPosition = 10
        addChild(answerLabel)

        // Number pad — 3 columns, fits portrait width
        let buttonSize: CGFloat = 50
        let spacing: CGFloat = min(size.width * 0.18, 65)
        let startX = size.width / 2 - spacing
        let startY = contentStartY - 120

        for i in 1...9 {
            let row = (i - 1) / 3
            let col = (i - 1) % 3
            let btn = createNumButton(
                text: "\(i)",
                position: CGPoint(x: startX + CGFloat(col) * spacing, y: startY - CGFloat(row) * spacing),
                size: buttonSize
            )
            btn.name = "num_\(i)"
            addChild(btn)
        }

        let zeroBtn = createNumButton(text: "0", position: CGPoint(x: size.width / 2, y: startY - 3 * spacing), size: buttonSize)
        zeroBtn.name = "num_0"
        addChild(zeroBtn)

        // Back button
        let backBtn = createNumButton(text: "Back", position: CGPoint(x: 51, y: navBarY), size: 40)
        backBtn.name = "backButton"
        addChild(backBtn)

        // Clear button
        let clearBtn = createNumButton(text: "C", position: CGPoint(x: startX - spacing, y: startY - 3 * spacing), size: buttonSize)
        clearBtn.name = "clearButton"
        addChild(clearBtn)
    }

    private func createNumButton(text: String, position: CGPoint, size: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 10

        let bg = SKShapeNode(circleOfRadius: size / 2)
        bg.fillColor = SKColor(white: 0.15, alpha: 0.8)
        bg.strokeColor = SKColor(white: 0.4, alpha: 0.6)
        bg.lineWidth = 1.5
        container.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = size * 0.45
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        for child in children {
            guard let name = child.name else { continue }
            let dist = hypot(location.x - child.position.x, location.y - child.position.y)
            if dist < 35 {
                if name.starts(with: "num_") {
                    let digit = String(name.dropFirst(4))
                    currentAnswer += digit
                    answerLabel.text = currentAnswer
                    checkAnswer()
                } else if name == "clearButton" {
                    currentAnswer = ""
                    answerLabel.text = "_"
                } else if name == "backButton" {
                    goBack()
                }
                break
            }
        }
    }

    private func checkAnswer() {
        if let answer = Int(currentAnswer), answer == correctAnswer {
            let transition = SKTransition.push(with: .up, duration: 0.5)
            let dashboard = ParentDashboardScene(size: size)
            dashboard.scaleMode = .resizeFill
            view?.presentScene(dashboard, transition: transition)
        } else if currentAnswer.count >= 3 {
            currentAnswer = ""
            answerLabel.text = "_"
            let shake = SKAction.sequence([
                SKAction.moveBy(x: -10, y: 0, duration: 0.05),
                SKAction.moveBy(x: 20, y: 0, duration: 0.05),
                SKAction.moveBy(x: -20, y: 0, duration: 0.05),
                SKAction.moveBy(x: 10, y: 0, duration: 0.05)
            ])
            answerLabel.run(shake)
        }
    }

    private func goBack() {
        let transition = SKTransition.push(with: .down, duration: 0.5)
        let title = TitleScene(size: size)
        title.scaleMode = .resizeFill
        view?.presentScene(title, transition: transition)
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)
    }
}

// MARK: - Parent Dashboard
final class ParentDashboardScene: SKScene {
    private var starField: StarField!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.01, blue: 0.1, alpha: 1.0)

        starField = StarField()
        starField.setup(size: size, grade: .grade3)
        addChild(starField)

        let topY = titleSafeY

        let title = SKLabelNode(text: "Parent Dashboard")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 26
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: topY)
        title.zPosition = 10
        addChild(title)

        let gm = GameManager.shared
        var yPos = contentStartY

        if gm.slots.isEmpty {
            let noData = SKLabelNode(text: "No player data yet. Start playing!")
            noData.fontName = "AvenirNext-Medium"
            noData.fontSize = 18
            noData.fontColor = SKColor(white: 0.7, alpha: 1.0)
            noData.position = CGPoint(x: size.width / 2, y: size.height / 2)
            noData.zPosition = 10
            addChild(noData)
        } else {
            for i in 0..<GameManager.maxSlots {
                guard let profile = gm.slots[i] else { continue }
                let report = ProgressManager.shared.generateReport(for: profile)
                drawProfileReport(report, yStart: yPos)
                yPos -= 160
            }
        }

        // Back button
        let backBtn = SKNode()
        backBtn.position = CGPoint(x: 51, y: navBarY)
        backBtn.zPosition = 100
        backBtn.name = "backButton"

        let backBg = SKShapeNode(rectOf: CGSize(width: 80, height: 30), cornerRadius: 8)
        backBg.fillColor = SKColor(white: 0.15, alpha: 0.8)
        backBg.strokeColor = SKColor(white: 0.4, alpha: 0.6)
        backBtn.addChild(backBg)

        let backLabel = SKLabelNode(text: "Back")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 14
        backLabel.fontColor = .white
        backLabel.verticalAlignmentMode = .center
        backBtn.addChild(backLabel)

        addChild(backBtn)
    }

    private func drawProfileReport(_ report: ProgressReport, yStart: CGFloat) {
        let profile = report.profile
        let nameLabel = SKLabelNode(text: "\(profile.name) - \(profile.currentGrade.displayName)")
        nameLabel.fontName = "AvenirNext-Bold"
        nameLabel.fontSize = 17
        nameLabel.fontColor = profile.currentGrade.primaryColor
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: 20, y: yStart)
        nameLabel.zPosition = 10
        addChild(nameLabel)

        let stats = SKLabelNode(text: "Acc: \(Int(report.overallAccuracy * 100))% | Probs: \(report.totalProblemsAttempted) | Hi: \(profile.highScore(for: profile.currentGrade))")
        stats.fontName = "AvenirNext-Regular"
        stats.fontSize = 12
        stats.fontColor = SKColor(white: 0.8, alpha: 1.0)
        stats.horizontalAlignmentMode = .left
        stats.position = CGPoint(x: 20, y: yStart - 22)
        stats.zPosition = 10
        addChild(stats)

        // Topic bars
        var barY = yStart - 48
        let barMaxWidth: CGFloat = min(size.width - 140, 240)

        for (key, topicStats) in profile.accuracyPerTopic {
            guard let topic = MathTopic(rawValue: key), topicStats.total >= 2 else { continue }
            if barY < 50 { break }

            let topicLabel = SKLabelNode(text: topic.displayName)
            topicLabel.fontName = "AvenirNext-Regular"
            topicLabel.fontSize = 10
            topicLabel.fontColor = .white
            topicLabel.horizontalAlignmentMode = .left
            topicLabel.position = CGPoint(x: 25, y: barY)
            topicLabel.zPosition = 10
            addChild(topicLabel)

            let barWidth = barMaxWidth * CGFloat(topicStats.accuracy)
            let barColor: SKColor = topicStats.accuracy > 0.9 ? .green :
                                    topicStats.accuracy > 0.7 ? .yellow : .red

            let bgBar = SKShapeNode(rectOf: CGSize(width: barMaxWidth, height: 8))
            bgBar.fillColor = SKColor(white: 0.15, alpha: 0.5)
            bgBar.strokeColor = .clear
            bgBar.position = CGPoint(x: 120 + barMaxWidth / 2, y: barY + 3)
            bgBar.zPosition = 10
            addChild(bgBar)

            if barWidth > 0 {
                let bar = SKShapeNode(rect: CGRect(x: 0, y: -4, width: barWidth, height: 8), cornerRadius: 2)
                bar.fillColor = barColor
                bar.strokeColor = .clear
                bar.position = CGPoint(x: 120, y: barY + 3)
                bar.zPosition = 11
                addChild(bar)
            }

            let pctLabel = SKLabelNode(text: "\(Int(topicStats.accuracy * 100))%")
            pctLabel.fontName = "AvenirNext-Medium"
            pctLabel.fontSize = 9
            pctLabel.fontColor = barColor
            pctLabel.horizontalAlignmentMode = .left
            pctLabel.position = CGPoint(x: 125 + barMaxWidth, y: barY)
            pctLabel.zPosition = 10
            addChild(pctLabel)

            barY -= 18
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let backBtn = childNode(withName: "backButton") {
            let dist = hypot(location.x - backBtn.position.x, location.y - backBtn.position.y)
            if dist < 50 {
                let transition = SKTransition.push(with: .down, duration: 0.5)
                let title = TitleScene(size: size)
                title.scaleMode = .resizeFill
                view?.presentScene(title, transition: transition)
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)
    }
}
