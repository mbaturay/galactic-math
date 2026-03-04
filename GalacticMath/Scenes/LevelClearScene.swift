import SpriteKit

final class LevelClearScene: SKScene {
    var selectedGrade: Grade = .kindergarten
    private var starField: StarField!

    override func didMove(to view: SKView) {
        backgroundColor = selectedGrade.backgroundColor

        starField = StarField()
        starField.setup(size: size, grade: selectedGrade)
        addChild(starField)

        // Confetti
        let confetti = ConfettiNode()
        confetti.zPosition = 150
        addChild(confetti)
        confetti.burst(in: size)

        AudioManager.shared.playLevelClear()

        let gm = GameManager.shared

        // Title
        let title = SKLabelNode(text: "LEVEL COMPLETE!")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = min(size.width * 0.09, 40)
        title.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.82)
        title.zPosition = 10
        addChild(title)

        let titlePop = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        title.run(titlePop)

        // Star rating
        let starRating = StarRatingNode()
        starRating.setup(rating: gm.starRating, size: 40)
        starRating.position = CGPoint(x: size.width / 2, y: size.height * 0.70)
        starRating.zPosition = 10
        addChild(starRating)

        // Stats
        let accuracyPct = Int(gm.accuracy * 100)
        let statsY = size.height * 0.58
        let lineSpacing: CGFloat = 30

        let stats = [
            "Problems Solved: \(gm.totalCorrect)",
            "Accuracy: \(accuracyPct)%",
            "Score: \(gm.score)"
        ]

        for (i, text) in stats.enumerated() {
            let label = SKLabelNode(text: text)
            label.fontName = "AvenirNext-Medium"
            label.fontSize = 18
            label.fontColor = .white
            label.position = CGPoint(x: size.width / 2, y: statsY - CGFloat(i) * lineSpacing)
            label.zPosition = 10
            addChild(label)
        }

        // Next Level button
        let nextBtn = createButton(
            text: "NEXT LEVEL",
            color: SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0),
            position: CGPoint(x: size.width / 2, y: size.height * 0.30),
            name: "nextLevel"
        )
        addChild(nextBtn)

        // Main Menu button
        let menuBtn = createButton(
            text: "MAIN MENU",
            color: SKColor(white: 0.5, alpha: 1.0),
            position: CGPoint(x: size.width / 2, y: size.height * 0.20),
            name: "mainMenu"
        )
        addChild(menuBtn)

        // Flying avatar
        let avatarEmoji = GameManager.shared.currentProfile?.avatar ?? "\u{1F680}"
        let rocket = SKLabelNode(text: avatarEmoji)
        rocket.fontSize = 40
        rocket.position = CGPoint(x: -50, y: size.height * 0.5)
        rocket.zPosition = 5
        addChild(rocket)

        let fly = SKAction.sequence([
            SKAction.move(to: CGPoint(x: size.width + 50, y: size.height * 0.55), duration: 3.0),
            SKAction.removeFromParent()
        ])
        rocket.run(fly)
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

        if tappedName == "nextLevel" {
            let earnedBadges = GameManager.shared.advanceLevel()

            if !earnedBadges.isEmpty {
                // Show badge celebration before continuing
                let badgeScene = BadgeCelebrationScene(size: self.size)
                badgeScene.scaleMode = .resizeFill
                badgeScene.earnedBadges = earnedBadges
                badgeScene.selectedGrade = selectedGrade
                view?.presentScene(badgeScene, transition: SKTransition.crossFade(withDuration: 0.8))
            } else {
                let gameScene = GameScene(size: self.size)
                gameScene.scaleMode = .resizeFill
                gameScene.selectedGrade = selectedGrade
                view?.presentScene(gameScene, transition: SKTransition.doorway(withDuration: 1.0))
            }
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
