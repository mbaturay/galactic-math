import SpriteKit

final class GameOverScene: SKScene {
    var selectedGrade: Grade = .kindergarten
    var bossDestroyedPlayer: Bool = false
    private var starField: StarField!

    override func didMove(to view: SKView) {
        backgroundColor = selectedGrade.backgroundColor

        starField = StarField()
        starField.setup(size: size, grade: selectedGrade)
        addChild(starField)

        AudioManager.shared.playGameOver()

        let gm = GameManager.shared

        // Title
        let titleText = bossDestroyedPlayer
            ? "YOUR PLANET HAS BEEN DESTROYED BY THE SENTINEL! \u{1F4A5}"
            : "MISSION FAILED!\nYOUR SHIP WAS DESTROYED! \u{1F680}"
        let title = SKLabelNode(text: titleText)
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = min(size.width * 0.08, 32)
        title.fontColor = bossDestroyedPlayer
            ? SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
            : SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)
        title.numberOfLines = 0
        title.preferredMaxLayoutWidth = size.width - 40
        title.horizontalAlignmentMode = .center
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: size.width / 2, y: titleSafeY)
        title.zPosition = 10
        addChild(title)

        // Player avatar
        let cY = contentStartY
        let avatar = gm.currentProfile?.avatar ?? "\u{1F680}"
        let avatarLabel = SKLabelNode(text: avatar)
        avatarLabel.fontSize = 50
        avatarLabel.position = CGPoint(x: size.width / 2, y: cY)
        avatarLabel.zPosition = 10
        addChild(avatarLabel)

        // Score
        let scoreLabel = SKLabelNode(text: "Score: \(gm.score)")
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = selectedGrade.primaryColor
        scoreLabel.position = CGPoint(x: size.width / 2, y: cY - 66)
        scoreLabel.zPosition = 10
        addChild(scoreLabel)

        // Level reached
        let levelLabel = SKLabelNode(text: "Level Reached: \(gm.currentLevel)")
        levelLabel.fontName = "AvenirNext-Medium"
        levelLabel.fontSize = 18
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: size.width / 2, y: cY - 110)
        levelLabel.zPosition = 10
        addChild(levelLabel)

        // Try Again button
        let retryBtn = createButton(
            text: "TRY AGAIN",
            color: selectedGrade.primaryColor,
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
            GameManager.shared.startNewGame(grade: selectedGrade)
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .resizeFill
            gameScene.selectedGrade = selectedGrade
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
