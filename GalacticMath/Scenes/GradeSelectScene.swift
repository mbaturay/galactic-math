import SpriteKit

final class GradeSelectScene: SKScene {
    private var starField: StarField!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.01, blue: 0.1, alpha: 1.0)

        starField = StarField()
        starField.setup(size: size, grade: .grade3)
        addChild(starField)

        // Nav bar buttons (in the notch zone, flanking Dynamic Island)
        addBackButton(atY: navBarY)
        addBadgeRoomButton(atY: navBarY)

        // Title (below safe area)
        let titleY = titleSafeY

        let title = SKLabelNode(text: "Choose Your Mission")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = min(size.width * 0.08, 34)
        title.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: titleY)
        title.zPosition = 10
        addChild(title)

        if let profile = GameManager.shared.currentProfile {
            let nameLabel = SKLabelNode(text: "\(profile.avatar) \(profile.name)")
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontSize = 18
            nameLabel.fontColor = .white
            nameLabel.position = CGPoint(x: size.width / 2, y: titleY - 30)
            nameLabel.zPosition = 10
            addChild(nameLabel)
        }

        layoutGradePlanets(below: contentStartY)
    }

    private func layoutGradePlanets(below startY: CGFloat) {
        let profile = GameManager.shared.currentProfile
        let planetRadius: CGFloat = min(size.width * 0.13, 48)
        let cols = 2
        let gapX: CGFloat = size.width * 0.12
        let gapY: CGFloat = planetRadius * 2 + 28
        let gridW = CGFloat(cols) * planetRadius * 2 + gapX
        let originX = (size.width - gridW) / 2 + planetRadius

        for (i, grade) in Grade.allCases.enumerated() {
            let col = i % cols
            let row = i / cols
            let x = originX + CGFloat(col) * (planetRadius * 2 + gapX)
            let y = startY - CGFloat(row) * gapY

            let planet = createPlanet(grade: grade, profile: profile, radius: planetRadius)
            planet.position = CGPoint(x: x, y: y)
            planet.name = "grade_\(grade.rawValue)"
            planet.zPosition = 10
            addChild(planet)
        }
    }

    private func createPlanet(grade: Grade, profile: PlayerProfile?, radius: CGFloat) -> SKNode {
        let container = SKNode()

        let circle = SKShapeNode(circleOfRadius: radius)
        circle.fillColor = grade.primaryColor.withAlphaComponent(0.2)
        circle.strokeColor = grade.primaryColor.withAlphaComponent(0.8)
        circle.lineWidth = 2.5
        circle.glowWidth = 2.0
        container.addChild(circle)

        let emoji = SKLabelNode(text: grade.emoji)
        emoji.fontSize = radius * 0.65
        emoji.verticalAlignmentMode = .center
        emoji.position = CGPoint(x: 0, y: 2)
        container.addChild(emoji)

        let nameLabel = SKLabelNode(text: grade.displayName)
        nameLabel.fontName = "AvenirNext-Bold"
        nameLabel.fontSize = min(radius * 0.3, 13)
        nameLabel.fontColor = grade.primaryColor
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: -radius - 12)
        container.addChild(nameLabel)

        if let profile = profile {
            let currentLevel = profile.currentLevel(for: grade)
            let levelText = currentLevel > 20 ? "Complete!" : "Lv.\(currentLevel)/20"
            let levelLabel = SKLabelNode(text: levelText)
            levelLabel.fontName = "AvenirNext-Medium"
            levelLabel.fontSize = 10
            levelLabel.fontColor = SKColor(white: 0.6, alpha: 0.9)
            levelLabel.verticalAlignmentMode = .center
            levelLabel.position = CGPoint(x: 0, y: -radius - 25)
            container.addChild(levelLabel)

            if profile.isGraduated(grade: grade) {
                let grad = SKLabelNode(text: "\u{1F393}")
                grad.fontSize = 14
                grad.position = CGPoint(x: radius - 6, y: radius - 6)
                container.addChild(grad)
            }
        }

        let glow = SKAction.sequence([
            SKAction.run { circle.glowWidth = 4.0 },
            SKAction.wait(forDuration: 1.2 + Double(grade.rawValue) * 0.15),
            SKAction.run { circle.glowWidth = 2.0 },
            SKAction.wait(forDuration: 1.0)
        ])
        container.run(SKAction.repeatForever(glow))

        return container
    }

    private func addBackButton(atY y: CGFloat) {
        let backBtn = SKNode()
        backBtn.position = CGPoint(x: 51, y: y)
        backBtn.zPosition = 100
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

    private func addBadgeRoomButton(atY y: CGFloat) {
        let btn = SKNode()
        btn.position = CGPoint(x: size.width - 56, y: y)
        btn.zPosition = 100
        btn.name = "badgeRoom"

        let bg = SKShapeNode(rectOf: CGSize(width: 80, height: 28), cornerRadius: 8)
        bg.fillColor = SKColor(white: 0.15, alpha: 0.7)
        bg.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.5)
        btn.addChild(bg)

        let label = SKLabelNode(text: "\u{1F3C6} Badges")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 12
        label.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.9)
        label.verticalAlignmentMode = .center
        btn.addChild(label)

        addChild(btn)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        AudioManager.shared.playMenuTap()

        if let backBtn = childNode(withName: "backButton") {
            let dist = hypot(location.x - backBtn.position.x, location.y - backBtn.position.y)
            if dist < 50 {
                let scene = ProfileSelectScene(size: size)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.5))
                return
            }
        }

        if let badgeBtn = childNode(withName: "badgeRoom") {
            let dist = hypot(location.x - badgeBtn.position.x, location.y - badgeBtn.position.y)
            if dist < 50 {
                let scene = BadgeRoomScene(size: size)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: SKTransition.push(with: .left, duration: 0.5))
                return
            }
        }

        for grade in Grade.allCases {
            if let planet = childNode(withName: "grade_\(grade.rawValue)") {
                let dist = hypot(location.x - planet.position.x, location.y - planet.position.y)
                if dist < 60 {
                    let scene = TopicSelectScene(size: size)
                    scene.scaleMode = .resizeFill
                    scene.selectedGrade = grade
                    view?.presentScene(scene, transition: SKTransition.push(with: .left, duration: 0.5))
                    return
                }
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)
    }
}
