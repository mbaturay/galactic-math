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
    private var scrollContainer: SKNode!
    private var scrollContentHeight: CGFloat = 0
    private var scrollOffset: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var scrollVelocity: CGFloat = 0
    private var visibleAreaBottom: CGFloat = 0
    private var visibleAreaHeight: CGFloat = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.01, blue: 0.1, alpha: 1.0)

        starField = StarField()
        starField.setup(size: size, grade: .grade3)
        addChild(starField)

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

        // Title
        let title = SKLabelNode(text: "Parent Dashboard")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 26
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: titleSafeY)
        title.zPosition = 10
        addChild(title)

        // Scrollable area
        visibleAreaBottom = 16.0
        visibleAreaHeight = contentStartY - visibleAreaBottom

        // Clip mask
        let cropNode = SKCropNode()
        cropNode.zPosition = 5
        let mask = SKShapeNode(rect: CGRect(x: 0, y: visibleAreaBottom, width: size.width, height: visibleAreaHeight))
        mask.fillColor = .white
        cropNode.maskNode = mask
        addChild(cropNode)

        scrollContainer = SKNode()
        scrollContainer.position = .zero
        cropNode.addChild(scrollContainer)

        buildCards()
    }

    // MARK: - Build Cards

    private func buildCards() {
        scrollContainer.removeAllChildren()

        let gm = GameManager.shared
        let cardWidth = min(size.width - 32, 400.0)
        let cardX = size.width / 2
        let cardSpacing: CGFloat = 16
        let topicRowHeight: CGFloat = 22
        let cardPadding: CGFloat = 16

        // Build cards top-down from contentStartY
        var cursorY = contentStartY

        var hasAnySlot = false
        for i in 0..<GameManager.maxSlots {
            if let profile = gm.slots[i] {
                hasAnySlot = true
                let grade = profile.currentGrade
                let gradeTopics = Curriculum.topicList(for: grade)
                let topicCount = gradeTopics.count
                let headerHeight: CGFloat = 70
                let topicSectionHeight = CGFloat(topicCount) * topicRowHeight + 30
                let cardHeight = headerHeight + topicSectionHeight + cardPadding

                cursorY -= cardHeight / 2

                let card = buildPlayerCard(
                    profile: profile,
                    gradeTopics: gradeTopics,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                    topicRowHeight: topicRowHeight
                )
                card.position = CGPoint(x: cardX, y: cursorY)
                scrollContainer.addChild(card)

                cursorY -= cardHeight / 2 + cardSpacing
            } else {
                // Empty slot
                let emptyHeight: CGFloat = 60
                cursorY -= emptyHeight / 2

                let card = buildEmptySlotCard(width: cardWidth, height: emptyHeight)
                card.position = CGPoint(x: cardX, y: cursorY)
                scrollContainer.addChild(card)

                cursorY -= emptyHeight / 2 + cardSpacing
            }
        }

        if !hasAnySlot {
            let noData = SKLabelNode(text: "No player data yet. Start playing!")
            noData.fontName = "AvenirNext-Medium"
            noData.fontSize = 18
            noData.fontColor = SKColor(white: 0.7, alpha: 1.0)
            noData.position = CGPoint(x: 0, y: size.height / 2)
            scrollContainer.addChild(noData)
        }

        // Total content height = distance from contentStartY down to bottom of last card
        scrollContentHeight = contentStartY - cursorY + cardSpacing
        scrollOffset = 0
    }

    // MARK: - Player Card

    private func buildPlayerCard(profile: PlayerProfile, gradeTopics: [MathTopic], cardWidth: CGFloat, cardHeight: CGFloat, topicRowHeight: CGFloat) -> SKNode {
        let card = SKNode()
        let grade = profile.currentGrade
        let accentColor = grade.primaryColor

        // Card background
        let bg = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 12)
        bg.fillColor = SKColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 0.85)
        bg.strokeColor = accentColor.withAlphaComponent(0.5)
        bg.lineWidth = 1.5
        card.addChild(bg)

        let innerLeft = -cardWidth / 2 + 16
        let innerRight = cardWidth / 2 - 16
        let barMaxWidth = min(cardWidth * 0.35, 140.0)

        // ── Header Row 1: Avatar + Name + Grade/Level ──
        let headerY = cardHeight / 2 - 24

        let avatarLabel = SKLabelNode(text: profile.avatar)
        avatarLabel.fontSize = 22
        avatarLabel.verticalAlignmentMode = .center
        avatarLabel.position = CGPoint(x: innerLeft + 12, y: headerY)
        card.addChild(avatarLabel)

        let nameLabel = SKLabelNode(text: profile.name.uppercased())
        nameLabel.fontName = "AvenirNext-Heavy"
        nameLabel.fontSize = 17
        nameLabel.fontColor = accentColor
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: innerLeft + 32, y: headerY)
        card.addChild(nameLabel)

        let gradeInfo = "\(grade.displayName)  Lv.\(profile.currentLevel(for: grade))"
        let gradeLabel = SKLabelNode(text: gradeInfo)
        gradeLabel.fontName = "AvenirNext-Medium"
        gradeLabel.fontSize = 12
        gradeLabel.fontColor = SKColor(white: 0.8, alpha: 0.9)
        gradeLabel.horizontalAlignmentMode = .right
        gradeLabel.verticalAlignmentMode = .center
        gradeLabel.position = CGPoint(x: innerRight, y: headerY)
        card.addChild(gradeLabel)

        // ── Header Row 2: Progress bar + Accuracy ──
        let row2Y = headerY - 24
        let level = profile.currentLevel(for: grade)
        let progressFraction = CGFloat(level) / 20.0
        let progressBarWidth = min(cardWidth * 0.5, 200.0)

        // Progress bar background
        let progBg = SKShapeNode(rect: CGRect(x: 0, y: -4, width: progressBarWidth, height: 8), cornerRadius: 4)
        progBg.fillColor = SKColor(white: 0.2, alpha: 0.6)
        progBg.strokeColor = .clear
        progBg.position = CGPoint(x: innerLeft, y: row2Y)
        card.addChild(progBg)

        // Progress bar fill
        let progFillWidth = max(progressBarWidth * progressFraction, 1)
        let progColor: SKColor = progressFraction > 0.8 ? .green : progressFraction > 0.6 ? .yellow : SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 1.0)
        let progFill = SKShapeNode(rect: CGRect(x: 0, y: -4, width: progFillWidth, height: 8), cornerRadius: 4)
        progFill.fillColor = progColor
        progFill.strokeColor = .clear
        progFill.position = CGPoint(x: innerLeft, y: row2Y)
        card.addChild(progFill)

        let report = ProgressManager.shared.generateReport(for: profile)
        let accText = "Acc: \(Int(report.overallAccuracy * 100))%"
        let accLabel = SKLabelNode(text: accText)
        accLabel.fontName = "AvenirNext-Bold"
        accLabel.fontSize = 12
        accLabel.fontColor = SKColor(white: 0.9, alpha: 1.0)
        accLabel.horizontalAlignmentMode = .right
        accLabel.verticalAlignmentMode = .center
        accLabel.position = CGPoint(x: innerRight, y: row2Y)
        card.addChild(accLabel)

        // ── Header Row 3: Problems + High Score ──
        let row3Y = row2Y - 18
        let statsText = "Problems: \(report.totalProblemsAttempted)  |  Best: \(profile.highScore(for: grade))"
        let statsLabel = SKLabelNode(text: statsText)
        statsLabel.fontName = "AvenirNext-Regular"
        statsLabel.fontSize = 11
        statsLabel.fontColor = SKColor(white: 0.65, alpha: 0.9)
        statsLabel.horizontalAlignmentMode = .left
        statsLabel.verticalAlignmentMode = .center
        statsLabel.position = CGPoint(x: innerLeft, y: row3Y)
        card.addChild(statsLabel)

        // ── Divider ──
        let dividerY = row3Y - 12
        let divider = SKShapeNode(rectOf: CGSize(width: cardWidth - 32, height: 0.5))
        divider.fillColor = SKColor(white: 0.4, alpha: 0.3)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: 0, y: dividerY)
        card.addChild(divider)

        // ── Topic Breakdown ──
        let topicHeaderY = dividerY - 16
        let topicHeader = SKLabelNode(text: "TOPIC BREAKDOWN:")
        topicHeader.fontName = "AvenirNext-DemiBold"
        topicHeader.fontSize = 10
        topicHeader.fontColor = SKColor(white: 0.55, alpha: 0.9)
        topicHeader.horizontalAlignmentMode = .left
        topicHeader.verticalAlignmentMode = .center
        topicHeader.position = CGPoint(x: innerLeft, y: topicHeaderY)
        card.addChild(topicHeader)

        let barLeft = innerRight - barMaxWidth - 40
        var topicY = topicHeaderY - topicRowHeight

        for topic in gradeTopics {
            let key = topic.rawValue
            let stats = profile.accuracyPerTopic[key]

            // Topic name — truncate if needed
            var topicName = topic.displayName
            if topicName.count > 22 {
                topicName = String(topicName.prefix(20)) + "..."
            }
            let topicLabel = SKLabelNode(text: topicName)
            topicLabel.fontName = "AvenirNext-Medium"
            topicLabel.fontSize = 11
            topicLabel.fontColor = SKColor(white: 0.7, alpha: 0.9)
            topicLabel.horizontalAlignmentMode = .left
            topicLabel.verticalAlignmentMode = .center
            topicLabel.position = CGPoint(x: innerLeft, y: topicY)
            card.addChild(topicLabel)

            if let stats = stats, stats.total > 0 {
                let acc = stats.accuracy
                let barColor: SKColor = acc > 0.8 ? .green : acc > 0.6 ? .yellow : SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 1.0)

                // Bar background
                let barBg = SKShapeNode(rect: CGRect(x: 0, y: -3.5, width: barMaxWidth, height: 7), cornerRadius: 3.5)
                barBg.fillColor = SKColor(white: 0.15, alpha: 0.5)
                barBg.strokeColor = .clear
                barBg.position = CGPoint(x: barLeft, y: topicY)
                card.addChild(barBg)

                // Bar fill
                let fillWidth = max(barMaxWidth * CGFloat(acc), 1)
                let barFill = SKShapeNode(rect: CGRect(x: 0, y: -3.5, width: fillWidth, height: 7), cornerRadius: 3.5)
                barFill.fillColor = barColor
                barFill.strokeColor = .clear
                barFill.position = CGPoint(x: barLeft, y: topicY)
                card.addChild(barFill)

                // Percentage
                let pctLabel = SKLabelNode(text: "\(Int(acc * 100))%")
                pctLabel.fontName = "AvenirNext-Bold"
                pctLabel.fontSize = 10
                pctLabel.fontColor = barColor
                pctLabel.horizontalAlignmentMode = .right
                pctLabel.verticalAlignmentMode = .center
                pctLabel.position = CGPoint(x: innerRight, y: topicY)
                card.addChild(pctLabel)
            } else {
                let notStarted = SKLabelNode(text: "Not started")
                notStarted.fontName = "AvenirNext-Regular"
                notStarted.fontSize = 10
                notStarted.fontColor = SKColor(white: 0.4, alpha: 0.8)
                notStarted.horizontalAlignmentMode = .right
                notStarted.verticalAlignmentMode = .center
                notStarted.position = CGPoint(x: innerRight, y: topicY)
                card.addChild(notStarted)
            }

            topicY -= topicRowHeight
        }

        return card
    }

    // MARK: - Empty Slot Card

    private func buildEmptySlotCard(width: CGFloat, height: CGFloat) -> SKNode {
        let card = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12)
        bg.fillColor = SKColor(white: 0.08, alpha: 0.6)
        bg.strokeColor = SKColor(white: 0.25, alpha: 0.4)
        bg.lineWidth = 1.0
        card.addChild(bg)

        let plus = SKLabelNode(text: "+")
        plus.fontName = "AvenirNext-Light"
        plus.fontSize = 24
        plus.fontColor = SKColor(white: 0.35, alpha: 0.8)
        plus.verticalAlignmentMode = .center
        plus.position = CGPoint(x: -30, y: 0)
        card.addChild(plus)

        let label = SKLabelNode(text: "Empty Slot")
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 14
        label.fontColor = SKColor(white: 0.35, alpha: 0.8)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: -16, y: 0)
        card.addChild(label)

        return card
    }

    // MARK: - Scrolling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        scrollVelocity = 0
        lastTouchY = location.y

        // Back button
        if let backBtn = childNode(withName: "backButton") {
            let dist = hypot(location.x - backBtn.position.x, location.y - backBtn.position.y)
            if dist < 50 {
                let transition = SKTransition.push(with: .down, duration: 0.5)
                let title = TitleScene(size: size)
                title.scaleMode = .resizeFill
                view?.presentScene(title, transition: transition)
                return
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let dy = location.y - lastTouchY
        scrollVelocity = dy
        lastTouchY = location.y

        applyScroll(dy)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Momentum will be applied in update
    }

    private func applyScroll(_ delta: CGFloat) {
        let maxScroll = max(scrollContentHeight - visibleAreaHeight, 0)
        scrollOffset = min(max(scrollOffset + delta, 0), maxScroll)
        scrollContainer.position.y = scrollOffset
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)

        // Momentum scrolling
        if abs(scrollVelocity) > 0.5 {
            applyScroll(scrollVelocity)
            scrollVelocity *= 0.92
        } else {
            scrollVelocity = 0
        }
    }
}
