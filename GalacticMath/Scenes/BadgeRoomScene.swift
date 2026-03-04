import SpriteKit

final class BadgeRoomScene: SKScene {
    private var starField: StarField!
    private var scrollOffset: CGFloat = 0
    private var contentHeight: CGFloat = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.01, blue: 0.1, alpha: 1.0)

        starField = StarField()
        starField.setup(size: size, grade: .grade3)
        addChild(starField)

        let title = SKLabelNode(text: "\u{1F3C6} Badge Room")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = min(size.width * 0.08, 30)
        title.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.92)
        title.zPosition = 100
        addChild(title)

        addBackButton()

        guard let profile = GameManager.shared.currentProfile else { return }

        let badgeCountLabel = SKLabelNode(text: "\(profile.totalBadgeCount) badges earned")
        badgeCountLabel.fontName = "AvenirNext-Medium"
        badgeCountLabel.fontSize = 14
        badgeCountLabel.fontColor = SKColor(white: 0.7, alpha: 0.9)
        badgeCountLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.86)
        badgeCountLabel.zPosition = 100
        addChild(badgeCountLabel)

        layoutBadges(profile: profile)
    }

    private func layoutBadges(profile: PlayerProfile) {
        var yPos = size.height * 0.80

        // Grade badges
        for grade in Grade.allCases {
            let badges = Badge.badgesForGrade(grade)

            let header = SKLabelNode(text: "\(grade.emoji) \(grade.displayName)")
            header.fontName = "AvenirNext-Bold"
            header.fontSize = 14
            header.fontColor = grade.primaryColor
            header.horizontalAlignmentMode = .left
            header.position = CGPoint(x: 20, y: yPos)
            header.zPosition = 10
            addChild(header)
            yPos -= 28

            yPos = layoutBadgeRow(badges: badges, profile: profile, yPos: yPos)
            yPos -= 16
        }

        // Special badges
        let specialHeader = SKLabelNode(text: "\u{2B50} Special Badges")
        specialHeader.fontName = "AvenirNext-Bold"
        specialHeader.fontSize = 14
        specialHeader.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        specialHeader.horizontalAlignmentMode = .left
        specialHeader.position = CGPoint(x: 20, y: yPos)
        specialHeader.zPosition = 10
        addChild(specialHeader)
        yPos -= 28

        _ = layoutBadgeRow(badges: Badge.specialBadges, profile: profile, yPos: yPos)
    }

    private func layoutBadgeRow(badges: [Badge], profile: PlayerProfile, yPos: CGFloat) -> CGFloat {
        let badgeSize: CGFloat = min((size.width - 40) / CGFloat(badges.count) - 8, 50)
        let spacing: CGFloat = 8
        let totalW = CGFloat(badges.count) * badgeSize + CGFloat(badges.count - 1) * spacing
        let startX = (size.width - totalW) / 2 + badgeSize / 2

        for (i, badge) in badges.enumerated() {
            let x = startX + CGFloat(i) * (badgeSize + spacing)
            let earned = profile.hasBadge(badge)

            let container = SKNode()
            container.position = CGPoint(x: x, y: yPos)
            container.zPosition = 10

            let bg = SKShapeNode(circleOfRadius: badgeSize / 2)
            if earned {
                bg.fillColor = SKColor(white: 0.2, alpha: 0.8)
                bg.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.8)
                bg.lineWidth = 2.0
                bg.glowWidth = 1.5
            } else {
                bg.fillColor = SKColor(white: 0.08, alpha: 0.5)
                bg.strokeColor = SKColor(white: 0.2, alpha: 0.4)
                bg.lineWidth = 1.0
            }
            container.addChild(bg)

            let emojiLabel = SKLabelNode(text: earned ? badge.emoji : "?")
            emojiLabel.fontSize = badgeSize * 0.5
            emojiLabel.verticalAlignmentMode = .center
            emojiLabel.alpha = earned ? 1.0 : 0.3
            container.addChild(emojiLabel)

            if earned {
                let nameLabel = SKLabelNode(text: badge.name)
                nameLabel.fontName = "AvenirNext-Medium"
                nameLabel.fontSize = 7
                nameLabel.fontColor = SKColor(white: 0.7, alpha: 0.9)
                nameLabel.verticalAlignmentMode = .center
                nameLabel.position = CGPoint(x: 0, y: -badgeSize / 2 - 10)
                container.addChild(nameLabel)
            }

            addChild(container)
        }

        return yPos - badgeSize / 2 - 14
    }

    private func addBackButton() {
        let backBtn = SKNode()
        backBtn.position = CGPoint(x: 45, y: size.height - 35)
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
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)
    }
}
