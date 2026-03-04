import SpriteKit

final class GameOverScene: SKScene {
    var selectedAgeGroup: AgeGroup = .cadet
    private var starField: StarField!

    override func didMove(to view: SKView) {
        backgroundColor = selectedAgeGroup.backgroundColor

        starField = StarField()
        starField.setup(size: size, ageGroup: selectedAgeGroup)
        addChild(starField)

        AudioManager.shared.playGameOver()

        let gm = GameManager.shared

        // Title
        let title = SKLabelNode(text: "MISSION OVER!")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = min(size.width * 0.09, 40)
        title.fontColor = SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        title.zPosition = 10
        addChild(title)

        // Friendly message
        let message: String
        switch selectedAgeGroup {
        case .cadet:
            message = "Good try, Space Cadet! Keep practicing!"
        case .pilot:
            message = "Nice effort, Star Pilot! Try again?"
        case .ace:
            message = "Great attempt, Commander! Ready for another mission?"
        }

        let msgLabel = SKLabelNode(text: message)
        msgLabel.fontName = "AvenirNext-Medium"
        msgLabel.fontSize = min(size.width * 0.04, 18)
        msgLabel.fontColor = SKColor(white: 0.85, alpha: 1.0)
        msgLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.67)
        msgLabel.zPosition = 10
        addChild(msgLabel)

        // Player avatar
        let avatar = gm.currentProfile?.avatar ?? "🚀"
        let avatarLabel = SKLabelNode(text: avatar)
        avatarLabel.fontSize = 50
        avatarLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.61)
        avatarLabel.zPosition = 10
        addChild(avatarLabel)

        // Score
        let scoreLabel = SKLabelNode(text: "Score: \(gm.score)")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = selectedAgeGroup.primaryColor
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
        scoreLabel.zPosition = 10
        addChild(scoreLabel)

        // Level reached
        let levelLabel = SKLabelNode(text: "Level Reached: \(gm.currentLevel)")
        levelLabel.fontName = "AvenirNext-Medium"
        levelLabel.fontSize = 18
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
        levelLabel.zPosition = 10
        addChild(levelLabel)

        // Try Again button
        let retryBtn = createButton(
            text: "TRY AGAIN",
            color: selectedAgeGroup.primaryColor,
            position: CGPoint(x: size.width / 2, y: size.height * 0.32),
            name: "tryAgain"
        )
        addChild(retryBtn)

        // Main Menu button
        let menuBtn = createButton(
            text: "MAIN MENU",
            color: SKColor(white: 0.5, alpha: 1.0),
            position: CGPoint(x: size.width / 2, y: size.height * 0.22),
            name: "mainMenu"
        )
        addChild(menuBtn)
    }

    private func createButton(text: String, color: SKColor, position: CGPoint, name: String) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 10
        container.name = name

        let btnSize = CGSize(width: min(size.width * 0.7, 220), height: 50)
        let bg = SKShapeNode(rectOf: btnSize, cornerRadius: 12)
        bg.fillColor = color.withAlphaComponent(0.3)
        bg.strokeColor = color.withAlphaComponent(0.8)
        bg.lineWidth = 2.0
        bg.glowWidth = 2.0
        container.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Find the closest named button to the tap
        var closestName: String?
        var closestDist: CGFloat = .greatestFiniteMagnitude
        for child in children {
            guard let name = child.name else { continue }
            let dist = hypot(location.x - child.position.x, location.y - child.position.y)
            if dist < 60 && dist < closestDist {
                closestDist = dist
                closestName = name
            }
        }

        guard let tappedName = closestName else { return }

        AudioManager.shared.playMenuTap()

        if tappedName == "tryAgain" {
            GameManager.shared.startNewGame(ageGroup: selectedAgeGroup)
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .resizeFill
            gameScene.selectedAgeGroup = selectedAgeGroup
            view?.presentScene(gameScene, transition: SKTransition.doorway(withDuration: 1.0))
        } else if tappedName == "mainMenu" {
            GameManager.shared.resetToMenu()
            let scene = TitleScene(size: self.size)
            scene.scaleMode = .resizeFill
            view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
        }
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)
    }
}
