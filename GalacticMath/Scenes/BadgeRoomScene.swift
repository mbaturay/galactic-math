import SpriteKit

final class BadgeRoomScene: SKScene {
    private var starField: StarField!
    private var popupVisible = false

    // Badge data for tap lookup
    private struct BadgeInfo {
        let badge: Badge
        let grade: Grade?       // nil for special badges
        let topicIndex: Int?    // 0-4 for topic badges, nil for grad/special
        let earned: Bool
    }
    private var badgeInfoMap: [String: BadgeInfo] = [:]

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.01, blue: 0.1, alpha: 1.0)

        starField = StarField()
        starField.setup(size: size, grade: .grade3)
        addChild(starField)

        guard let profile = GameManager.shared.currentProfile else { return }

        layoutScene(profile: profile)
    }

    // MARK: - Layout

    private func layoutScene(profile: PlayerProfile) {
        addBackButton(atY: navBarY)

        let topY = titleSafeY

        // Title
        let title = SKLabelNode(text: "Badge Room")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = min(size.width * 0.07, 26)
        title.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: topY)
        title.zPosition = 100
        addChild(title)

        // Stats section
        let statsY = layoutStats(profile: profile, below: contentStartY)

        // Badge matrix
        let matrixY = layoutMatrix(profile: profile, below: statsY - 14)

        // Special badges
        layoutSpecialBadges(profile: profile, below: matrixY - 14)
    }

    // MARK: - Stats Section

    private func layoutStats(profile: PlayerProfile, below topY: CGFloat) -> CGFloat {
        // Avatar + Name
        let avatarName = SKLabelNode(text: "\(profile.avatar) \(profile.name)")
        avatarName.fontName = "AvenirNext-Bold"
        avatarName.fontSize = 18
        avatarName.fontColor = .white
        avatarName.position = CGPoint(x: size.width / 2, y: topY)
        avatarName.zPosition = 10
        addChild(avatarName)

        // Stat pills
        let pillY = topY - 30
        let hours = Int(profile.totalPlayTime) / 3600
        let mins = (Int(profile.totalPlayTime) % 3600) / 60
        let accPct = Int(profile.overallAccuracy * 100)
        let streak = profile.longestStreak
        let badgeCount = profile.totalBadgeCount

        let pills = [
            "\u{23F1} \(hours)h \(mins)m",
            "\u{1F3AF} \(accPct)%",
            "\u{1F525} \(streak)",
            "\u{1F3C6} \(badgeCount)/\(Badge.totalCount)"
        ]

        let pillW: CGFloat = (size.width - 32 - 12) / 4  // 16pt margins, 4pt gaps × 3
        let startX: CGFloat = 16 + pillW / 2

        let grade = profile.currentGrade
        for (i, text) in pills.enumerated() {
            let x = startX + CGFloat(i) * (pillW + 4)

            let bg = SKShapeNode(rectOf: CGSize(width: pillW, height: 24), cornerRadius: 12)
            bg.fillColor = grade.primaryColor.withAlphaComponent(0.2)
            bg.strokeColor = grade.primaryColor.withAlphaComponent(0.5)
            bg.lineWidth = 1
            bg.position = CGPoint(x: x, y: pillY)
            bg.zPosition = 10
            addChild(bg)

            let label = SKLabelNode(text: text)
            label.fontName = "AvenirNext-DemiBold"
            label.fontSize = 10
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: x, y: pillY)
            label.zPosition = 11
            addChild(label)
        }

        return pillY - 14
    }

    // MARK: - Badge Matrix

    private func layoutMatrix(profile: PlayerProfile, below topY: CGFloat) -> CGFloat {
        let cellSize: CGFloat = 54
        let gradSize: CGFloat = 62
        let labelW: CGFloat = 28
        let marginX: CGFloat = 12

        // Calculate spacing to fill available width
        let contentW = 5 * cellSize + gradSize + labelW
        let gapCount: CGFloat = 5  // 5 gaps between 6 cells
        let availableForGaps = size.width - 2 * marginX - contentW
        let spacing = max(3, availableForGaps / (gapCount + 1))  // +1 for gap after label

        let matrixW = labelW + spacing + 5 * cellSize + gradSize + gapCount * spacing
        let originX = max(marginX, (size.width - matrixW) / 2)

        let rowHeight = gradSize + spacing
        let currentGrade = profile.currentGrade

        var yPos = topY

        for grade in Grade.allCases {
            let badges = Badge.badgesForGrade(grade)
            let topics = Curriculum.topicList(for: grade)
            let isCurrentGrade = grade == currentGrade

            // Current grade row highlight
            if isCurrentGrade {
                let highlightW = matrixW + 10
                let bg = SKShapeNode(rectOf: CGSize(width: highlightW, height: rowHeight - 2), cornerRadius: 8)
                bg.fillColor = grade.primaryColor.withAlphaComponent(0.08)
                bg.strokeColor = grade.primaryColor.withAlphaComponent(0.2)
                bg.lineWidth = 1
                bg.position = CGPoint(x: originX + matrixW / 2, y: yPos - (gradSize / 2 - 2))
                bg.zPosition = 5
                addChild(bg)
            }

            // Row label
            let rowLabel = SKLabelNode(text: grade.shortName)
            rowLabel.fontName = "AvenirNext-Bold"
            rowLabel.fontSize = 11
            rowLabel.fontColor = grade.primaryColor
            rowLabel.horizontalAlignmentMode = .left
            rowLabel.verticalAlignmentMode = .center
            rowLabel.position = CGPoint(x: originX, y: yPos - gradSize / 2 + 2)
            rowLabel.zPosition = 10
            addChild(rowLabel)

            // Badge cells
            var cellX = originX + labelW + spacing

            for (col, badge) in badges.enumerated() {
                let isGrad = (col == badges.count - 1)
                let thisSize = isGrad ? gradSize : cellSize
                let earned = profile.hasBadge(badge)
                let topicIndex = col < topics.count ? col : nil

                let nodeName = "badge_\(grade.rawValue)_\(col)"
                badgeInfoMap[nodeName] = BadgeInfo(
                    badge: badge,
                    grade: grade,
                    topicIndex: topicIndex,
                    earned: earned
                )

                let container = SKNode()
                container.position = CGPoint(x: cellX + thisSize / 2, y: yPos - gradSize / 2 + 2)
                container.zPosition = 10
                container.name = nodeName

                // Background
                let bg: SKShapeNode
                if isGrad {
                    bg = SKShapeNode(rectOf: CGSize(width: thisSize, height: thisSize), cornerRadius: 8)
                    if earned {
                        bg.fillColor = SKColor(red: 0.15, green: 0.12, blue: 0.0, alpha: 0.8)
                        bg.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.9)
                        bg.lineWidth = 2.0
                        bg.glowWidth = 2.0
                    } else {
                        bg.fillColor = SKColor(white: 0.06, alpha: 0.5)
                        bg.strokeColor = SKColor(red: 0.5, green: 0.42, blue: 0.0, alpha: 0.3)
                        bg.lineWidth = 1.5
                    }
                } else {
                    bg = SKShapeNode(rectOf: CGSize(width: thisSize, height: thisSize), cornerRadius: 6)
                    if earned {
                        bg.fillColor = SKColor(white: 0.15, alpha: 0.7)
                        bg.strokeColor = grade.primaryColor.withAlphaComponent(0.6)
                        bg.lineWidth = 1.5
                        bg.glowWidth = 1.0
                    } else {
                        bg.fillColor = SKColor(white: 0.06, alpha: 0.4)
                        bg.strokeColor = SKColor(white: 0.15, alpha: 0.3)
                        bg.lineWidth = 1.0
                    }
                }
                container.addChild(bg)

                // Emoji
                let emojiLabel = SKLabelNode(text: badge.emoji)
                emojiLabel.fontSize = 32
                emojiLabel.verticalAlignmentMode = .center
                emojiLabel.alpha = earned ? 1.0 : 0.25
                container.addChild(emojiLabel)

                addChild(container)
                cellX += thisSize + spacing
            }

            yPos -= rowHeight
        }

        return yPos
    }

    // MARK: - Special Badges (2 rows of 5)

    private func layoutSpecialBadges(profile: PlayerProfile, below topY: CGFloat) {
        let header = SKLabelNode(text: "SPECIAL ACHIEVEMENTS")
        header.fontName = "AvenirNext-Bold"
        header.fontSize = 10
        header.fontColor = SKColor(white: 0.5, alpha: 0.8)
        header.position = CGPoint(x: size.width / 2, y: topY)
        header.zPosition = 10
        addChild(header)

        let specials = Badge.specialBadges  // 10 badges
        let cellSize: CGFloat = 54
        let spacing: CGFloat = 6
        let perRow = 5
        let rowW = CGFloat(perRow) * cellSize + CGFloat(perRow - 1) * spacing
        let startX = (size.width - rowW) / 2 + cellSize / 2

        for (i, badge) in specials.enumerated() {
            let row = i / perRow      // 0 or 1
            let col = i % perRow      // 0-4
            let x = startX + CGFloat(col) * (cellSize + spacing)
            let y = topY - 28 - CGFloat(row) * (cellSize + spacing)
            let earned = profile.hasBadge(badge)

            let nodeName = "special_\(i)"
            badgeInfoMap[nodeName] = BadgeInfo(
                badge: badge,
                grade: nil,
                topicIndex: nil,
                earned: earned
            )

            let container = SKNode()
            container.position = CGPoint(x: x, y: y)
            container.zPosition = 10
            container.name = nodeName

            let bg = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize), cornerRadius: 6)
            if earned {
                bg.fillColor = SKColor(white: 0.15, alpha: 0.7)
                bg.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.6)
                bg.lineWidth = 1.5
                bg.glowWidth = 1.0
            } else {
                bg.fillColor = SKColor(white: 0.06, alpha: 0.4)
                bg.strokeColor = SKColor(white: 0.15, alpha: 0.3)
                bg.lineWidth = 1.0
            }
            container.addChild(bg)

            let emojiLabel = SKLabelNode(text: badge.emoji)
            emojiLabel.fontSize = 32
            emojiLabel.verticalAlignmentMode = .center
            emojiLabel.alpha = earned ? 1.0 : 0.25
            container.addChild(emojiLabel)

            addChild(container)
        }
    }

    // MARK: - Back Button

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

    // MARK: - Badge Popup

    private func showBadgePopup(info: BadgeInfo) {
        popupVisible = true

        // Dim overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = SKColor(white: 0, alpha: 0.65)
        overlay.strokeColor = .clear
        overlay.zPosition = 200
        overlay.name = "popup"
        addChild(overlay)

        let popupW: CGFloat = min(size.width * 0.75, 260)
        let popupH: CGFloat = info.earned ? 180 : 160
        let popupBg = SKShapeNode(rectOf: CGSize(width: popupW, height: popupH), cornerRadius: 16)
        popupBg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        popupBg.fillColor = SKColor(red: 0.06, green: 0.04, blue: 0.14, alpha: 0.95)
        popupBg.strokeColor = info.earned
            ? SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.6)
            : SKColor(white: 0.3, alpha: 0.4)
        popupBg.lineWidth = 1.5
        popupBg.zPosition = 201
        popupBg.name = "popup"
        addChild(popupBg)

        let cx = size.width / 2
        let cy = size.height / 2

        if info.earned {
            let bigEmoji = SKLabelNode(text: info.badge.emoji)
            bigEmoji.fontSize = 48
            bigEmoji.verticalAlignmentMode = .center
            bigEmoji.position = CGPoint(x: cx, y: cy + 50)
            bigEmoji.zPosition = 202
            bigEmoji.name = "popup"
            addChild(bigEmoji)

            let nameLabel = SKLabelNode(text: info.badge.name)
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontSize = 18
            nameLabel.fontColor = .white
            nameLabel.position = CGPoint(x: cx, y: cy + 14)
            nameLabel.zPosition = 202
            nameLabel.name = "popup"
            addChild(nameLabel)

            let descText: String
            if info.badge.isSpecial {
                descText = info.badge.badgeDescription
            } else if let grade = info.grade, let topicIdx = info.topicIndex {
                let topics = Curriculum.topicList(for: grade)
                descText = topicIdx < topics.count ? topics[topicIdx].displayName : grade.displayName
            } else if info.grade != nil {
                descText = "Graduation"
            } else {
                descText = ""
            }

            let descLabel = SKLabelNode(text: descText)
            descLabel.fontName = "AvenirNext-Medium"
            descLabel.fontSize = 13
            descLabel.fontColor = SKColor(white: 0.7, alpha: 0.9)
            descLabel.position = CGPoint(x: cx, y: cy - 10)
            descLabel.zPosition = 202
            descLabel.name = "popup"
            addChild(descLabel)

            if let dateEarned = GameManager.shared.currentProfile?.badgesEarned[info.badge.rawValue] {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                let dateLabel = SKLabelNode(text: "Earned \(formatter.string(from: dateEarned))")
                dateLabel.fontName = "AvenirNext-Regular"
                dateLabel.fontSize = 11
                dateLabel.fontColor = SKColor(white: 0.5, alpha: 0.8)
                dateLabel.position = CGPoint(x: cx, y: cy - 34)
                dateLabel.zPosition = 202
                dateLabel.name = "popup"
                addChild(dateLabel)
            }

            let dismiss = SKLabelNode(text: "tap to dismiss")
            dismiss.fontName = "AvenirNext-Regular"
            dismiss.fontSize = 10
            dismiss.fontColor = SKColor(white: 0.4, alpha: 0.6)
            dismiss.position = CGPoint(x: cx, y: cy - 60)
            dismiss.zPosition = 202
            dismiss.name = "popup"
            addChild(dismiss)
        } else {
            let bigEmoji = SKLabelNode(text: info.badge.emoji)
            bigEmoji.fontSize = 48
            bigEmoji.verticalAlignmentMode = .center
            bigEmoji.alpha = 0.3
            bigEmoji.position = CGPoint(x: cx, y: cy + 42)
            bigEmoji.zPosition = 202
            bigEmoji.name = "popup"
            addChild(bigEmoji)

            let lockedLabel = SKLabelNode(text: "Locked")
            lockedLabel.fontName = "AvenirNext-Bold"
            lockedLabel.fontSize = 18
            lockedLabel.fontColor = SKColor(white: 0.5, alpha: 0.8)
            lockedLabel.position = CGPoint(x: cx, y: cy + 6)
            lockedLabel.zPosition = 202
            lockedLabel.name = "popup"
            addChild(lockedLabel)

            let hintText: String
            if info.badge.isSpecial {
                hintText = info.badge.badgeDescription
            } else if let grade = info.grade, let topicIdx = info.topicIndex {
                let topics = Curriculum.topicList(for: grade)
                let topicName = topicIdx < topics.count ? topics[topicIdx].displayName : "all topics"
                hintText = "Complete \(topicName) in \(grade.displayName)"
            } else if let grade = info.grade {
                hintText = "Complete all topics in \(grade.displayName)"
            } else {
                hintText = "Keep playing to unlock!"
            }

            let hintLabel = SKLabelNode(text: hintText)
            hintLabel.fontName = "AvenirNext-Medium"
            hintLabel.fontSize = 12
            hintLabel.fontColor = SKColor(white: 0.6, alpha: 0.8)
            hintLabel.numberOfLines = 0
            hintLabel.preferredMaxLayoutWidth = popupW - 30
            hintLabel.horizontalAlignmentMode = .center
            hintLabel.verticalAlignmentMode = .center
            hintLabel.position = CGPoint(x: cx, y: cy - 24)
            hintLabel.zPosition = 202
            hintLabel.name = "popup"
            addChild(hintLabel)

            let dismiss = SKLabelNode(text: "tap to dismiss")
            dismiss.fontName = "AvenirNext-Regular"
            dismiss.fontSize = 10
            dismiss.fontColor = SKColor(white: 0.4, alpha: 0.6)
            dismiss.position = CGPoint(x: cx, y: cy - 56)
            dismiss.zPosition = 202
            dismiss.name = "popup"
            addChild(dismiss)
        }
    }

    private func dismissPopup() {
        children.filter { $0.name == "popup" }.forEach { $0.removeFromParent() }
        popupVisible = false
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Dismiss popup on any tap
        if popupVisible {
            dismissPopup()
            return
        }

        AudioManager.shared.playMenuTap()

        // Back button
        if let backBtn = childNode(withName: "backButton") {
            let dist = hypot(location.x - backBtn.position.x, location.y - backBtn.position.y)
            if dist < 50 {
                let scene = GradeSelectScene(size: size)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.5))
                return
            }
        }

        // Find tapped badge
        for (nodeName, info) in badgeInfoMap {
            if let node = childNode(withName: nodeName) {
                let dist = hypot(location.x - node.position.x, location.y - node.position.y)
                if dist < 34 {
                    showBadgePopup(info: info)
                    return
                }
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)
    }
}
