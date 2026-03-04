import SpriteKit

final class AgeSelectScene: SKScene {
    private var starField: StarField!
    private var profileButtons: [SKNode] = []

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.01, blue: 0.1, alpha: 1.0)

        starField = StarField()
        starField.setup(size: size, ageGroup: .pilot)
        addChild(starField)

        // Title
        let title = SKLabelNode(text: "Who's Playing?")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = min(size.width * 0.08, 36)
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.88)
        title.zPosition = 10
        addChild(title)

        // Check for existing profiles
        let gm = GameManager.shared
        if gm.profiles.isEmpty {
            showAgeGroupButtons()
        } else {
            showProfileSelection()
        }

        // Back button
        let back = SKLabelNode(text: "\u{25C0} Back")
        back.fontName = "AvenirNext-Bold"
        back.fontSize = 18
        back.fontColor = SKColor(white: 0.7, alpha: 0.8)
        back.position = CGPoint(x: 50, y: size.height - 30)
        back.zPosition = 10
        back.name = "backButton"
        addChild(back)
    }

    private func showAgeGroupButtons() {
        let groups: [(AgeGroup, String, SKColor)] = [
            (.cadet, "\u{1F680} Space Cadet (4-7)", SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)),
            (.pilot, "\u{2B50} Star Pilot (7-10)", SKColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0)),
            (.ace, "\u{1F31F} Ace Commander (10-13)", SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0))
        ]

        let buttonWidth = min(size.width * 0.85, 350.0)
        let buttonHeight: CGFloat = 60
        let spacing: CGFloat = 20

        let totalHeight = CGFloat(groups.count) * buttonHeight + CGFloat(groups.count - 1) * spacing
        let startY = size.height * 0.55 + totalHeight / 2 - buttonHeight / 2

        for (i, group) in groups.enumerated() {
            let y = startY - CGFloat(i) * (buttonHeight + spacing)
            let btn = createAgeButton(
                text: group.1,
                color: group.2,
                position: CGPoint(x: size.width / 2, y: y),
                size: CGSize(width: buttonWidth, height: buttonHeight),
                name: "age_\(group.0.rawValue)"
            )
            addChild(btn)
        }

        // Hint for cadet
        let hint = SKLabelNode(text: "Ask a grown-up to help you choose!")
        hint.fontName = "AvenirNext-Regular"
        hint.fontSize = 13
        hint.fontColor = SKColor(white: 0.6, alpha: 0.7)
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.18)
        hint.zPosition = 10
        addChild(hint)
    }

    private func showProfileSelection() {
        let gm = GameManager.shared

        let buttonWidth = min(size.width * 0.8, 300.0)
        let buttonHeight: CGFloat = 50
        let spacing: CGFloat = 15
        var yPos = size.height * 0.68

        for (i, profile) in gm.profiles.enumerated() {
            if i >= 4 { break }
            let avatars = ["\u{1F680}", "\u{1F6F8}", "\u{2B50}", "\u{1F31F}", "\u{1F30D}"]
            let avatar = avatars[profile.avatarIndex % avatars.count]

            let btn = createAgeButton(
                text: "\(avatar) \(profile.name) - L\(profile.currentLevel)",
                color: profile.ageGroup.primaryColor,
                position: CGPoint(x: size.width / 2, y: yPos),
                size: CGSize(width: buttonWidth, height: buttonHeight),
                name: "profile_\(i)"
            )
            addChild(btn)
            yPos -= buttonHeight + spacing
        }

        if gm.profiles.count < 4 {
            let newBtn = createAgeButton(
                text: "+ New Player",
                color: SKColor(white: 0.5, alpha: 1.0),
                position: CGPoint(x: size.width / 2, y: yPos),
                size: CGSize(width: buttonWidth, height: buttonHeight),
                name: "newProfile"
            )
            addChild(newBtn)
        }
    }

    private func createAgeButton(text: String, color: SKColor, position: CGPoint, size: CGSize, name: String) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 10
        container.name = name

        let bg = SKShapeNode(rectOf: size, cornerRadius: 15)
        bg.fillColor = color.withAlphaComponent(0.2)
        bg.strokeColor = color.withAlphaComponent(0.8)
        bg.lineWidth = 2.5
        bg.glowWidth = 2.0
        container.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = min(self.size.width * 0.045, 20)
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        // Hover animation
        let glow = SKAction.sequence([
            SKAction.run { bg.glowWidth = 4.0 },
            SKAction.wait(forDuration: 1.0),
            SKAction.run { bg.glowWidth = 2.0 },
            SKAction.wait(forDuration: 1.0)
        ])
        container.run(SKAction.repeatForever(glow))

        return container
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        AudioManager.shared.playMenuTap()

        for child in children {
            guard let name = child.name else { continue }
            let dist = hypot(location.x - child.position.x, location.y - child.position.y)

            if name == "backButton" && dist < 50 {
                let transition = SKTransition.push(with: .right, duration: 0.5)
                let title = TitleScene(size: size)
                title.scaleMode = .resizeFill
                view?.presentScene(title, transition: transition)
                return
            }

            if dist < 100 {
                if name.starts(with: "age_") {
                    let groupName = String(name.dropFirst(4))
                    if let ageGroup = AgeGroup(rawValue: groupName) {
                        // Create a default profile
                        let gm = GameManager.shared
                        let playerName = "Player \(gm.profiles.count + 1)"
                        gm.createProfile(name: playerName, ageGroup: ageGroup, avatarIndex: gm.profiles.count)
                        gm.startNewGame(ageGroup: ageGroup)
                        transitionToGame(ageGroup: ageGroup)
                    }
                    return
                }

                if name.starts(with: "profile_") {
                    if let index = Int(String(name.dropFirst(8))) {
                        let gm = GameManager.shared
                        gm.selectProfile(at: index)
                        if let profile = gm.currentProfile {
                            gm.startNewGame(ageGroup: profile.ageGroup)
                            transitionToGame(ageGroup: profile.ageGroup)
                        }
                    }
                    return
                }

                if name == "newProfile" {
                    // Remove profiles/new buttons and show age group selection
                    children.filter { $0.name?.starts(with: "profile_") == true || $0.name == "newProfile" }
                        .forEach { $0.removeFromParent() }
                    showAgeGroupButtons()
                    return
                }
            }
        }
    }

    private func transitionToGame(ageGroup: AgeGroup) {
        let transition = SKTransition.doorway(withDuration: 1.0)
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .resizeFill
        gameScene.selectedAgeGroup = ageGroup
        view?.presentScene(gameScene, transition: transition)
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)
    }
}
