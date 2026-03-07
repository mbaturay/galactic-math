import SpriteKit

final class BadgeRoomScene: SKScene {
    private var starField: StarField!
    private var popupVisible = false

    // Tab state
    private enum Tab { case badges, ships }
    private var activeTab: Tab = .badges
    private var tabBadgesBtn: SKNode!
    private var tabShipsBtn: SKNode!

    // Badge data for tap lookup
    private struct BadgeInfo {
        let badge: Badge
        let grade: Grade?       // nil for special badges
        let topicIndex: Int?    // 0-4 for topic badges, nil for grad/special
        let earned: Bool
    }
    private var badgeInfoMap: [String: BadgeInfo] = [:]

    // Scroll infrastructure
    private var cropNode: SKCropNode!
    private var scrollContainer: SKNode!
    private var scrollableHeight: CGFloat = 0
    private var visibleHeight: CGFloat = 0
    private var scrollOffset: CGFloat = 0
    private var lastTouchY: CGFloat = 0
    private var isDragging = false
    private var scrollVelocity: CGFloat = 0
    private var lastTouchTime: TimeInterval = 0

    // Ship carousel
    private static let shipCount = 13
    private var selectedShipIndex: Int = 0
    private var shipCarouselNodes: [SKNode] = []
    private var lastTouchX: CGFloat = 0
    private var carouselOffset: CGFloat = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.01, blue: 0.1, alpha: 1.0)

        starField = StarField()
        starField.setup(size: size, grade: .grade3)
        addChild(starField)

        guard let profile = GameManager.shared.currentProfile else { return }
        selectedShipIndex = profile.selectedShipIndex

        layoutScene(profile: profile)
    }

    // MARK: - Layout

    private func layoutScene(profile: PlayerProfile) {
        addBackButton(atY: navBarY)

        // Avatar + name on the RIGHT side of the nav bar row, next to the notch
        let avatarName = SKLabelNode(text: "\(profile.avatar) \(profile.name)")
        avatarName.fontName = "AvenirNext-Bold"
        avatarName.fontSize = 14
        avatarName.fontColor = .white
        avatarName.horizontalAlignmentMode = .right
        avatarName.verticalAlignmentMode = .center
        avatarName.position = CGPoint(x: size.width - 14, y: navBarY)
        avatarName.zPosition = 100
        addChild(avatarName)

        let topY = titleSafeY

        // Title
        let title = SKLabelNode(text: "Badge Room")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = min(size.width * 0.07, 26)
        title.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: topY)
        title.zPosition = 100
        title.name = "titleLabel"
        addChild(title)

        // Stats pills directly under title
        let statsBottomY = layoutStats(profile: profile, below: topY - 28)

        // Tab buttons
        let tabY = statsBottomY - 18
        layoutTabs(atY: tabY, grade: profile.currentGrade)

        // Content area below tabs
        let scrollTop = tabY - 24
        let scrollBottom: CGFloat = 20
        visibleHeight = scrollTop - scrollBottom

        cropNode = SKCropNode()
        cropNode.position = CGPoint(x: 0, y: scrollBottom)
        cropNode.zPosition = 10

        let mask = SKSpriteNode(color: .white, size: CGSize(width: size.width, height: visibleHeight))
        mask.anchorPoint = CGPoint(x: 0, y: 0)
        cropNode.maskNode = mask

        scrollContainer = SKNode()
        cropNode.addChild(scrollContainer)
        addChild(cropNode)

        showBadgesTab(profile: profile)
    }

    // MARK: - Tabs

    private func layoutTabs(atY y: CGFloat, grade: Grade) {
        let tabW: CGFloat = min(size.width * 0.38, 130)
        let gap: CGFloat = 10
        let leftX = size.width / 2 - tabW - gap / 2
        let rightX = size.width / 2 + gap / 2

        tabBadgesBtn = createTabButton(text: "Badges", x: leftX, y: y, width: tabW, active: true, grade: grade)
        tabBadgesBtn.name = "tabBadges"
        addChild(tabBadgesBtn)

        tabShipsBtn = createTabButton(text: "Ships", x: rightX, y: y, width: tabW, active: false, grade: grade)
        tabShipsBtn.name = "tabShips"
        addChild(tabShipsBtn)
    }

    private func createTabButton(text: String, x: CGFloat, y: CGFloat, width: CGFloat, active: Bool, grade: Grade) -> SKNode {
        let btn = SKNode()
        btn.position = CGPoint(x: x + width / 2, y: y)
        btn.zPosition = 100

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 30), cornerRadius: 15)
        bg.fillColor = active ? grade.primaryColor.withAlphaComponent(0.35) : SKColor(white: 0.1, alpha: 0.5)
        bg.strokeColor = active ? grade.primaryColor.withAlphaComponent(0.8) : SKColor(white: 0.25, alpha: 0.5)
        bg.lineWidth = active ? 2.0 : 1.0
        bg.name = "tabBg"
        btn.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 13
        label.fontColor = active ? .white : SKColor(white: 0.5, alpha: 0.8)
        label.verticalAlignmentMode = .center
        label.name = "tabLabel"
        btn.addChild(label)

        return btn
    }

    private func switchToTab(_ tab: Tab) {
        guard tab != activeTab else { return }
        activeTab = tab
        guard let profile = GameManager.shared.currentProfile else { return }
        let grade = profile.currentGrade

        // Update tab visuals
        updateTabVisuals(grade: grade)

        // Update title
        if let titleNode = childNode(withName: "titleLabel") as? SKLabelNode {
            titleNode.text = tab == .badges ? "Badge Room" : "Ship Hangar"
        }

        // Clear scroll content
        scrollContainer.removeAllChildren()
        badgeInfoMap.removeAll()
        shipCarouselNodes.removeAll()
        scrollOffset = 0
        scrollContainer.position.y = 0

        switch tab {
        case .badges:
            showBadgesTab(profile: profile)
        case .ships:
            showShipsTab(profile: profile)
        }
    }

    private func updateTabVisuals(grade: Grade) {
        let badgesActive = activeTab == .badges
        let shipsActive = activeTab == .ships

        if let bg = tabBadgesBtn.childNode(withName: "tabBg") as? SKShapeNode {
            bg.fillColor = badgesActive ? grade.primaryColor.withAlphaComponent(0.35) : SKColor(white: 0.1, alpha: 0.5)
            bg.strokeColor = badgesActive ? grade.primaryColor.withAlphaComponent(0.8) : SKColor(white: 0.25, alpha: 0.5)
            bg.lineWidth = badgesActive ? 2.0 : 1.0
        }
        if let label = tabBadgesBtn.childNode(withName: "tabLabel") as? SKLabelNode {
            label.fontColor = badgesActive ? .white : SKColor(white: 0.5, alpha: 0.8)
        }

        if let bg = tabShipsBtn.childNode(withName: "tabBg") as? SKShapeNode {
            bg.fillColor = shipsActive ? grade.primaryColor.withAlphaComponent(0.35) : SKColor(white: 0.1, alpha: 0.5)
            bg.strokeColor = shipsActive ? grade.primaryColor.withAlphaComponent(0.8) : SKColor(white: 0.25, alpha: 0.5)
            bg.lineWidth = shipsActive ? 2.0 : 1.0
        }
        if let label = tabShipsBtn.childNode(withName: "tabLabel") as? SKLabelNode {
            label.fontColor = shipsActive ? .white : SKColor(white: 0.5, alpha: 0.8)
        }
    }

    // MARK: - Badges Tab

    private func showBadgesTab(profile: PlayerProfile) {
        let matrixBottomY = layoutMatrix(profile: profile, startY: visibleHeight)
        let contentBottomY = layoutSpecialBadges(profile: profile, below: matrixBottomY - 14)
        let totalContentHeight = visibleHeight - contentBottomY
        scrollableHeight = max(0, totalContentHeight - visibleHeight)
    }

    // MARK: - Ships Tab

    private func showShipsTab(profile: PlayerProfile) {
        scrollableHeight = 0  // No vertical scrolling for ships

        let grade = profile.currentGrade
        let centerY = visibleHeight * 0.55
        let shipSize: CGFloat = min(size.width * 0.35, 140)
        let cardSpacing: CGFloat = shipSize + 30
        let totalW = CGFloat(BadgeRoomScene.shipCount) * cardSpacing

        // Instruction text
        let hint = SKLabelNode(text: "SWIPE TO BROWSE - TAP TO SELECT")
        hint.fontName = "AvenirNext-Medium"
        hint.fontSize = 10
        hint.fontColor = SKColor(white: 0.5, alpha: 0.7)
        hint.position = CGPoint(x: size.width / 2, y: visibleHeight - 10)
        hint.zPosition = 12
        scrollContainer.addChild(hint)

        // Ship name label
        let nameLabel = SKLabelNode(text: shipName(for: selectedShipIndex))
        nameLabel.fontName = "AvenirNext-Heavy"
        nameLabel.fontSize = 20
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: size.width / 2, y: centerY + shipSize / 2 + 30)
        nameLabel.zPosition = 12
        nameLabel.name = "shipNameLabel"
        scrollContainer.addChild(nameLabel)

        // Ship cards
        shipCarouselNodes.removeAll()
        for i in 0..<BadgeRoomScene.shipCount {
            let card = buildShipCard(index: i, shipSize: shipSize, grade: grade)
            card.name = "shipCard_\(i)"
            scrollContainer.addChild(card)
            shipCarouselNodes.append(card)
        }

        // Select button
        let selectBtn = SKNode()
        selectBtn.position = CGPoint(x: size.width / 2, y: centerY - shipSize / 2 - 50)
        selectBtn.zPosition = 12
        selectBtn.name = "selectShipBtn"

        let isAlreadySelected = selectedShipIndex == profile.selectedShipIndex
        let btnBg = SKShapeNode(rectOf: CGSize(width: 160, height: 44), cornerRadius: 12)
        btnBg.fillColor = isAlreadySelected
            ? SKColor(white: 0.15, alpha: 0.6)
            : grade.primaryColor.withAlphaComponent(0.4)
        btnBg.strokeColor = isAlreadySelected
            ? SKColor(white: 0.4, alpha: 0.5)
            : grade.primaryColor.withAlphaComponent(0.9)
        btnBg.lineWidth = 2.0
        btnBg.name = "selectBtnBg"
        selectBtn.addChild(btnBg)

        let btnLabel = SKLabelNode(text: isAlreadySelected ? "SELECTED" : "SELECT SHIP")
        btnLabel.fontName = "AvenirNext-Bold"
        btnLabel.fontSize = 16
        btnLabel.fontColor = .white
        btnLabel.verticalAlignmentMode = .center
        btnLabel.name = "selectBtnLabel"
        selectBtn.addChild(btnLabel)

        scrollContainer.addChild(selectBtn)

        // Ship index dots
        let dotSpacing: CGFloat = 14
        let dotsStartX = size.width / 2 - CGFloat(BadgeRoomScene.shipCount - 1) * dotSpacing / 2
        for i in 0..<BadgeRoomScene.shipCount {
            let dot = SKShapeNode(circleOfRadius: i == selectedShipIndex ? 4 : 3)
            dot.fillColor = i == selectedShipIndex ? grade.primaryColor : SKColor(white: 0.3, alpha: 0.6)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: dotsStartX + CGFloat(i) * dotSpacing, y: centerY - shipSize / 2 - 20)
            dot.zPosition = 12
            dot.name = "shipDot_\(i)"
            scrollContainer.addChild(dot)
        }

        carouselOffset = CGFloat(selectedShipIndex) * cardSpacing
        updateCarouselLayout(animated: false)
    }

    private func buildShipCard(index: Int, shipSize: CGFloat, grade: Grade) -> SKNode {
        let card = SKNode()
        card.zPosition = 11

        // Card background
        let isSelected = index == selectedShipIndex
        let bg = SKShapeNode(rectOf: CGSize(width: shipSize + 20, height: shipSize + 20), cornerRadius: 16)
        bg.fillColor = isSelected
            ? grade.primaryColor.withAlphaComponent(0.15)
            : SKColor(white: 0.08, alpha: 0.5)
        bg.strokeColor = isSelected
            ? grade.primaryColor.withAlphaComponent(0.7)
            : SKColor(white: 0.2, alpha: 0.3)
        bg.lineWidth = isSelected ? 2.5 : 1.0
        bg.name = "cardBg"
        card.addChild(bg)

        // Ship sprite
        let textureName = "Spaceship_\(index)"
        let texture = SKTexture(imageNamed: textureName)
        let sprite = SKSpriteNode(texture: texture)
        let maxDim = max(sprite.size.width, sprite.size.height)
        let scale = shipSize * 0.75 / maxDim
        sprite.setScale(scale)
        sprite.zPosition = 1
        card.addChild(sprite)

        return card
    }

    private func updateCarouselLayout(animated: Bool) {
        let centerY = visibleHeight * 0.55
        let shipSize: CGFloat = min(size.width * 0.35, 140)
        let cardSpacing: CGFloat = shipSize + 30
        let centerX = size.width / 2

        for (i, card) in shipCarouselNodes.enumerated() {
            let targetX = centerX + CGFloat(i) * cardSpacing - carouselOffset
            let distFromCenter = abs(targetX - centerX)
            let normalizedDist = min(distFromCenter / cardSpacing, 2.0)

            // Scale: 1.0 at center, 0.7 at edges
            let cardScale = 1.0 - normalizedDist * 0.15
            // Alpha: 1.0 at center, 0.4 at edges
            let cardAlpha = 1.0 - normalizedDist * 0.3

            let targetPos = CGPoint(x: targetX, y: centerY)

            if animated {
                card.run(SKAction.group([
                    SKAction.move(to: targetPos, duration: 0.2),
                    SKAction.scale(to: cardScale, duration: 0.2),
                    SKAction.fadeAlpha(to: cardAlpha, duration: 0.2)
                ]))
            } else {
                card.position = targetPos
                card.setScale(cardScale)
                card.alpha = cardAlpha
            }
        }
    }

    private func snapToNearestShip() {
        let shipSize: CGFloat = min(size.width * 0.35, 140)
        let cardSpacing: CGFloat = shipSize + 30

        var nearestIndex = Int((carouselOffset / cardSpacing).rounded())
        nearestIndex = max(0, min(nearestIndex, BadgeRoomScene.shipCount - 1))

        selectedShipIndex = nearestIndex
        carouselOffset = CGFloat(nearestIndex) * cardSpacing
        updateCarouselLayout(animated: true)
        updateShipUI()
    }

    private func updateShipUI() {
        guard let profile = GameManager.shared.currentProfile else { return }
        let grade = profile.currentGrade

        // Update name
        if let nameLabel = scrollContainer.childNode(withName: "shipNameLabel") as? SKLabelNode {
            nameLabel.text = shipName(for: selectedShipIndex)
        }

        // Update dots
        for i in 0..<BadgeRoomScene.shipCount {
            if let dot = scrollContainer.childNode(withName: "shipDot_\(i)") as? SKShapeNode {
                dot.fillColor = i == selectedShipIndex ? grade.primaryColor : SKColor(white: 0.3, alpha: 0.6)
                let r: CGFloat = i == selectedShipIndex ? 4 : 3
                dot.path = CGPath(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2), transform: nil)
            }
        }

        // Update card highlights
        for (i, card) in shipCarouselNodes.enumerated() {
            if let bg = card.childNode(withName: "cardBg") as? SKShapeNode {
                let isSelected = i == selectedShipIndex
                bg.fillColor = isSelected
                    ? grade.primaryColor.withAlphaComponent(0.15)
                    : SKColor(white: 0.08, alpha: 0.5)
                bg.strokeColor = isSelected
                    ? grade.primaryColor.withAlphaComponent(0.7)
                    : SKColor(white: 0.2, alpha: 0.3)
                bg.lineWidth = isSelected ? 2.5 : 1.0
            }
        }

        // Update select button
        let isAlreadySelected = selectedShipIndex == profile.selectedShipIndex
        if let btn = scrollContainer.childNode(withName: "selectShipBtn") {
            if let bg = btn.childNode(withName: "selectBtnBg") as? SKShapeNode {
                bg.fillColor = isAlreadySelected
                    ? SKColor(white: 0.15, alpha: 0.6)
                    : grade.primaryColor.withAlphaComponent(0.4)
                bg.strokeColor = isAlreadySelected
                    ? SKColor(white: 0.4, alpha: 0.5)
                    : grade.primaryColor.withAlphaComponent(0.9)
            }
            if let label = btn.childNode(withName: "selectBtnLabel") as? SKLabelNode {
                label.text = isAlreadySelected ? "SELECTED" : "SELECT SHIP"
            }
        }
    }

    private func shipName(for index: Int) -> String {
        let names = [
            "Starfighter Alpha", "Nova Striker", "Phantom Wing",
            "Ice Lance", "Solar Dart", "Titan Hawk",
            "Nebula Cruiser", "Storm Eagle", "Shadow Blade",
            "Comet Chaser", "Void Runner", "Crystal Viper",
            "Dark Sentinel"
        ]
        guard index < names.count else { return "Ship \(index)" }
        return names[index]
    }

    // MARK: - Stats Section

    private func layoutStats(profile: PlayerProfile, below topY: CGFloat) -> CGFloat {
        let pillY = topY
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

        let pillW: CGFloat = (size.width - 32 - 12) / 4
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

    // MARK: - Badge Matrix (into scrollContainer)

    private func layoutMatrix(profile: PlayerProfile, startY: CGFloat) -> CGFloat {
        let cellSize: CGFloat = 54
        let gradSize: CGFloat = 62
        let labelW: CGFloat = 28
        let marginX: CGFloat = 12

        let contentW = 5 * cellSize + gradSize + labelW
        let gapCount: CGFloat = 5
        let availableForGaps = size.width - 2 * marginX - contentW
        let spacing = max(3, availableForGaps / (gapCount + 1))

        let matrixW = labelW + spacing + 5 * cellSize + gradSize + gapCount * spacing
        let originX = max(marginX, (size.width - matrixW) / 2)

        let rowHeight = gradSize + spacing
        let currentGrade = profile.currentGrade

        var yPos = startY

        for grade in Grade.allCases {
            let badges = Badge.badgesForGrade(grade)
            let topics = Curriculum.topicList(for: grade)
            let isCurrentGrade = grade == currentGrade

            if isCurrentGrade {
                let highlightW = matrixW + 10
                let bg = SKShapeNode(rectOf: CGSize(width: highlightW, height: rowHeight - 2), cornerRadius: 8)
                bg.fillColor = grade.primaryColor.withAlphaComponent(0.08)
                bg.strokeColor = grade.primaryColor.withAlphaComponent(0.2)
                bg.lineWidth = 1
                bg.position = CGPoint(x: originX + matrixW / 2, y: yPos - (gradSize / 2 - 2))
                bg.zPosition = 5
                scrollContainer.addChild(bg)
            }

            let rowLabel = SKLabelNode(text: grade.shortName)
            rowLabel.fontName = "AvenirNext-Bold"
            rowLabel.fontSize = 11
            rowLabel.fontColor = grade.primaryColor
            rowLabel.horizontalAlignmentMode = .left
            rowLabel.verticalAlignmentMode = .center
            rowLabel.position = CGPoint(x: originX, y: yPos - gradSize / 2 + 2)
            rowLabel.zPosition = 10
            scrollContainer.addChild(rowLabel)

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

                let emojiLabel = SKLabelNode(text: badge.emoji)
                emojiLabel.fontSize = 32
                emojiLabel.verticalAlignmentMode = .center
                emojiLabel.alpha = earned ? 1.0 : 0.25
                container.addChild(emojiLabel)

                scrollContainer.addChild(container)
                cellX += thisSize + spacing
            }

            yPos -= rowHeight
        }

        return yPos
    }

    // MARK: - Special Badges (2 rows of 5, into scrollContainer)

    private func layoutSpecialBadges(profile: PlayerProfile, below topY: CGFloat) -> CGFloat {
        let header = SKLabelNode(text: "SPECIAL ACHIEVEMENTS")
        header.fontName = "AvenirNext-Bold"
        header.fontSize = 10
        header.fontColor = SKColor(white: 0.5, alpha: 0.8)
        header.position = CGPoint(x: size.width / 2, y: topY)
        header.zPosition = 10
        scrollContainer.addChild(header)

        let specials = Badge.specialBadges
        let cellSize: CGFloat = 54
        let spacing: CGFloat = 6
        let perRow = 5
        let rowW = CGFloat(perRow) * cellSize + CGFloat(perRow - 1) * spacing
        let startX = (size.width - rowW) / 2 + cellSize / 2

        var lowestY = topY

        for (i, badge) in specials.enumerated() {
            let row = i / perRow
            let col = i % perRow
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

            scrollContainer.addChild(container)

            let bottomEdge = y - cellSize / 2
            if bottomEdge < lowestY {
                lowestY = bottomEdge
            }
        }

        return lowestY
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

    // MARK: - Scroll Helpers

    private func clampScrollOffset() {
        scrollOffset = max(0, min(scrollOffset, scrollableHeight))
    }

    // MARK: - Badge Popup

    private func showBadgePopup(info: BadgeInfo) {
        popupVisible = true

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

        if popupVisible {
            dismissPopup()
            return
        }

        let location = touch.location(in: self)
        lastTouchY = location.y
        lastTouchX = location.x
        lastTouchTime = touch.timestamp
        isDragging = false
        scrollVelocity = 0
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if popupVisible { return }

        let location = touch.location(in: self)

        if activeTab == .ships {
            let deltaX = location.x - lastTouchX
            if !isDragging && abs(deltaX) > 5 {
                isDragging = true
            }
            if isDragging {
                carouselOffset -= deltaX
                // Clamp
                let shipSize: CGFloat = min(size.width * 0.35, 140)
                let cardSpacing: CGFloat = shipSize + 30
                let maxOffset = CGFloat(BadgeRoomScene.shipCount - 1) * cardSpacing
                carouselOffset = max(-cardSpacing * 0.3, min(carouselOffset, maxOffset + cardSpacing * 0.3))
                updateCarouselLayout(animated: false)
                lastTouchX = location.x
            }
        } else {
            let deltaY = location.y - lastTouchY
            if !isDragging && abs(deltaY) > 5 {
                isDragging = true
            }
            if isDragging {
                scrollOffset -= deltaY
                clampScrollOffset()
                scrollContainer.position.y = scrollOffset

                let dt = touch.timestamp - lastTouchTime
                if dt > 0 {
                    scrollVelocity = deltaY / CGFloat(dt)
                }
                lastTouchY = location.y
                lastTouchTime = touch.timestamp
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if popupVisible { return }

        if activeTab == .ships && isDragging {
            isDragging = false
            snapToNearestShip()
            return
        }

        if isDragging {
            isDragging = false
            return
        }

        // It was a tap
        let location = touch.location(in: self)
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

        // Tab buttons
        if let badgesBtn = tabBadgesBtn {
            let dist = hypot(location.x - badgesBtn.position.x, location.y - badgesBtn.position.y)
            if dist < 70 {
                switchToTab(.badges)
                return
            }
        }
        if let shipsBtn = tabShipsBtn {
            let dist = hypot(location.x - shipsBtn.position.x, location.y - shipsBtn.position.y)
            if dist < 70 {
                switchToTab(.ships)
                return
            }
        }

        // Ships tab: select button
        if activeTab == .ships {
            let scrollLocation = touch.location(in: scrollContainer)
            if let selectBtn = scrollContainer.childNode(withName: "selectShipBtn") {
                let dist = hypot(scrollLocation.x - selectBtn.position.x, scrollLocation.y - selectBtn.position.y)
                if dist < 80 {
                    GameManager.shared.selectShip(selectedShipIndex)
                    updateShipUI()

                    // Brief confirmation flash
                    if let bg = selectBtn.childNode(withName: "selectBtnBg") as? SKShapeNode {
                        bg.run(SKAction.sequence([
                            SKAction.run { bg.glowWidth = 6 },
                            SKAction.wait(forDuration: 0.2),
                            SKAction.run { bg.glowWidth = 0 }
                        ]))
                    }
                    return
                }
            }

            // Tap on a ship card
            for (i, card) in shipCarouselNodes.enumerated() {
                let scrollLocation2 = touch.location(in: scrollContainer)
                let dist = hypot(scrollLocation2.x - card.position.x, scrollLocation2.y - card.position.y)
                if dist < 70 {
                    let shipSize: CGFloat = min(size.width * 0.35, 140)
                    let cardSpacing: CGFloat = shipSize + 30
                    selectedShipIndex = i
                    carouselOffset = CGFloat(i) * cardSpacing
                    updateCarouselLayout(animated: true)
                    updateShipUI()
                    return
                }
            }
            return
        }

        // Badge tap (in scrollContainer coordinate space)
        let scrollLocation = touch.location(in: scrollContainer)
        for (nodeName, info) in badgeInfoMap {
            if let node = scrollContainer.childNode(withName: nodeName) {
                let dist = hypot(scrollLocation.x - node.position.x, scrollLocation.y - node.position.y)
                if dist < 34 {
                    showBadgePopup(info: info)
                    return
                }
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if activeTab == .ships && isDragging {
            isDragging = false
            snapToNearestShip()
            return
        }
        isDragging = false
        scrollVelocity = 0
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)

        if activeTab == .badges && !isDragging && abs(scrollVelocity) > 1 {
            scrollOffset -= scrollVelocity * (1.0 / 60.0)
            scrollVelocity *= 0.92
            clampScrollOffset()
            scrollContainer.position.y = scrollOffset
        } else if !isDragging {
            scrollVelocity = 0
        }
    }
}
