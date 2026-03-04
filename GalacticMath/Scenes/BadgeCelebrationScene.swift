import SpriteKit

final class BadgeCelebrationScene: SKScene {
    var earnedBadges: [Badge] = []
    var selectedGrade: Grade = .kindergarten
    private var starField: StarField!
    private var currentBadgeIndex: Int = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.01, blue: 0.1, alpha: 1.0)

        starField = StarField()
        starField.setup(size: size, grade: selectedGrade)
        addChild(starField)

        let confetti = ConfettiNode()
        confetti.zPosition = 150
        addChild(confetti)
        confetti.burst(in: size)

        AudioManager.shared.playLevelClear()

        showBadge(at: 0)
    }

    private func showBadge(at index: Int) {
        guard index < earnedBadges.count else {
            continueToNextLevel()
            return
        }
        currentBadgeIndex = index
        let badge = earnedBadges[index]

        // Remove previous badge display
        children.filter { $0.name == "badgeContent" }.forEach { $0.removeFromParent() }

        let container = SKNode()
        container.name = "badgeContent"
        container.zPosition = 10

        // "NEW BADGE!" header
        let header = SKLabelNode(text: "NEW BADGE!")
        header.fontName = "AvenirNext-Heavy"
        header.fontSize = min(size.width * 0.09, 38)
        header.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        header.position = CGPoint(x: size.width / 2, y: size.height * 0.80)
        container.addChild(header)

        // Badge emoji — large
        let emojiLabel = SKLabelNode(text: badge.emoji)
        emojiLabel.fontSize = 80
        emojiLabel.verticalAlignmentMode = .center
        emojiLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        emojiLabel.setScale(0.1)
        container.addChild(emojiLabel)

        // Pop in animation
        emojiLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.2)
        ]))

        // Badge name
        let nameLabel = SKLabelNode(text: badge.name)
        nameLabel.fontName = "AvenirNext-Heavy"
        nameLabel.fontSize = 26
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.44)
        nameLabel.alpha = 0
        container.addChild(nameLabel)

        nameLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        // Description
        let descLabel = SKLabelNode(text: badge.badgeDescription)
        descLabel.fontName = "AvenirNext-Medium"
        descLabel.fontSize = 16
        descLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        descLabel.numberOfLines = 0
        descLabel.preferredMaxLayoutWidth = size.width - 60
        descLabel.horizontalAlignmentMode = .center
        descLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.37)
        descLabel.alpha = 0
        container.addChild(descLabel)

        descLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        // Continue prompt
        let remaining = earnedBadges.count - index - 1
        let continueText = remaining > 0 ? "Tap to see next badge (\(remaining) more)" : "Tap to continue"
        let continueLabel = SKLabelNode(text: continueText)
        continueLabel.fontName = "AvenirNext-Medium"
        continueLabel.fontSize = 16
        continueLabel.fontColor = SKColor(white: 0.5, alpha: 0.8)
        continueLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        continueLabel.alpha = 0
        container.addChild(continueLabel)

        continueLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.8),
                SKAction.fadeAlpha(to: 0.8, duration: 0.8)
            ]))
        ]))

        addChild(container)

        // Glow ring behind badge
        let ring = SKShapeNode(circleOfRadius: 60)
        ring.fillColor = .clear
        ring.strokeColor = selectedGrade.primaryColor.withAlphaComponent(0.4)
        ring.lineWidth = 3.0
        ring.glowWidth = 6.0
        ring.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        ring.zPosition = 9
        ring.name = "badgeContent"
        addChild(ring)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 1.0),
            SKAction.scale(to: 0.95, duration: 1.0)
        ])
        ring.run(SKAction.repeatForever(pulse))
    }

    private func continueToNextLevel() {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .resizeFill
        gameScene.selectedGrade = selectedGrade
        view?.presentScene(gameScene, transition: SKTransition.doorway(withDuration: 1.0))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        AudioManager.shared.playMenuTap()
        let nextIndex = currentBadgeIndex + 1
        if nextIndex < earnedBadges.count {
            showBadge(at: nextIndex)
        } else {
            continueToNextLevel()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)
    }
}
