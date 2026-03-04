import SpriteKit

final class ProfileSelectScene: SKScene {

    // MARK: - Mode

    private enum Mode {
        case slotGrid
        case creatingName
        case creatingAvatar
        case creatingAgeGroup
        case editingProfile
        case actionMenu
        case deleteConfirm
    }

    // MARK: - State

    private var starField: StarField!
    private var mode: Mode = .slotGrid

    // Slot grid
    private var slotNodes: [Int: SKNode] = [:]

    // Creation flow
    private var pendingSlotIndex: Int = 0
    private var pendingName: String = ""
    private var pendingAvatar: String = GameManager.avatarOptions[0]

    // Editing
    private var editingSlotIndex: Int = 0

    // Long press
    private var longPressTimer: Timer?
    private var longPressSlot: Int?
    private var touchStartTime: TimeInterval = 0

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.01, blue: 0.1, alpha: 1.0)

        starField = StarField()
        starField.setup(size: size, ageGroup: .pilot)
        addChild(starField)

        showSlotGrid()
    }

    // MARK: - Slot Grid

    private func showSlotGrid() {
        mode = .slotGrid
        clearContent()

        let title = SKLabelNode(text: "Choose Your Pilot")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = min(size.width * 0.08, 34)
        title.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.88)
        title.zPosition = 10
        title.name = "content"
        addChild(title)

        // Back button
        let backBtn = SKNode()
        backBtn.position = CGPoint(x: 45, y: size.height - 35)
        backBtn.zPosition = 10
        backBtn.name = "backButton"

        let backBg = SKShapeNode(rectOf: CGSize(width: 70, height: 28), cornerRadius: 8)
        backBg.fillColor = SKColor(white: 0.15, alpha: 0.7)
        backBg.strokeColor = SKColor(white: 0.4, alpha: 0.5)
        backBtn.addChild(backBg)

        let backLabel = SKLabelNode(text: "◀ Back")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 14
        backLabel.fontColor = SKColor(white: 0.7, alpha: 0.9)
        backLabel.verticalAlignmentMode = .center
        backBtn.addChild(backLabel)

        addChild(backBtn)

        // 2x2 grid
        let gm = GameManager.shared
        let slotW = min(size.width * 0.42, 160.0)
        let slotH = slotW * 1.15
        let gapX: CGFloat = 14
        let gapY: CGFloat = 14
        let gridW = slotW * 2 + gapX
        let gridH = slotH * 2 + gapY
        let originX = (size.width - gridW) / 2
        let originY = size.height * 0.48 - gridH / 2

        slotNodes.removeAll()

        for i in 0..<GameManager.maxSlots {
            let col = i % 2
            let row = i / 2
            let x = originX + CGFloat(col) * (slotW + gapX) + slotW / 2
            let y = originY + CGFloat(1 - row) * (slotH + gapY) + slotH / 2

            let node: SKNode
            if let profile = gm.slots[i] {
                node = createOccupiedSlot(profile: profile, slotSize: CGSize(width: slotW, height: slotH))
            } else {
                node = createEmptySlot(slotSize: CGSize(width: slotW, height: slotH))
            }
            node.position = CGPoint(x: x, y: y)
            node.name = "slot_\(i)"
            node.zPosition = 10
            addChild(node)
            slotNodes[i] = node
        }

        // Hint text below slots
        let hint = SKLabelNode(text: "Hold any player to edit or delete")
        hint.fontName = "AvenirNext-Regular"
        hint.fontSize = 12
        hint.fontColor = SKColor(white: 0.45, alpha: 0.7)
        hint.horizontalAlignmentMode = .center
        hint.verticalAlignmentMode = .center
        hint.position = CGPoint(x: size.width / 2, y: originY - 16)
        hint.zPosition = 10
        hint.name = "content"
        addChild(hint)
    }

    private func createOccupiedSlot(profile: PlayerProfile, slotSize: CGSize) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: slotSize, cornerRadius: 16)
        bg.fillColor = profile.ageGroup.primaryColor.withAlphaComponent(0.12)
        bg.strokeColor = profile.ageGroup.primaryColor.withAlphaComponent(0.7)
        bg.lineWidth = 2.5
        bg.glowWidth = 2.0
        container.addChild(bg)

        // Avatar
        let avatarLabel = SKLabelNode(text: profile.avatar)
        avatarLabel.fontSize = 48
        avatarLabel.verticalAlignmentMode = .center
        avatarLabel.position = CGPoint(x: 0, y: slotSize.height * 0.2)
        container.addChild(avatarLabel)

        // Name
        let nameLabel = SKLabelNode(text: profile.name)
        nameLabel.fontName = "AvenirNext-Bold"
        nameLabel.fontSize = min(slotSize.width * 0.12, 17)
        nameLabel.fontColor = .white
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: -slotSize.height * 0.05)
        container.addChild(nameLabel)

        // Age badge
        let ageBadge = SKLabelNode(text: profile.ageGroup.shortName)
        ageBadge.fontName = "AvenirNext-Medium"
        ageBadge.fontSize = 10
        ageBadge.fontColor = profile.ageGroup.primaryColor
        ageBadge.verticalAlignmentMode = .center
        ageBadge.position = CGPoint(x: 0, y: -slotSize.height * 0.18)
        container.addChild(ageBadge)

        // Level + high score
        let statsText = "Lv.\(profile.currentLevel)  Hi: \(profile.highScore)"
        let statsLabel = SKLabelNode(text: statsText)
        statsLabel.fontName = "AvenirNext-Regular"
        statsLabel.fontSize = 10
        statsLabel.fontColor = SKColor(white: 0.6, alpha: 0.9)
        statsLabel.verticalAlignmentMode = .center
        statsLabel.position = CGPoint(x: 0, y: -slotSize.height * 0.30)
        container.addChild(statsLabel)

        // Hold hint
        let hint = SKLabelNode(text: "hold to edit")
        hint.fontName = "AvenirNext-Regular"
        hint.fontSize = 8
        hint.fontColor = SKColor(white: 0.4, alpha: 0.6)
        hint.verticalAlignmentMode = .center
        hint.position = CGPoint(x: 0, y: -slotSize.height * 0.42)
        container.addChild(hint)

        return container
    }

    private func createEmptySlot(slotSize: CGSize) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: slotSize, cornerRadius: 16)
        bg.fillColor = SKColor(white: 0.1, alpha: 0.3)
        bg.strokeColor = SKColor(white: 0.3, alpha: 0.3)
        bg.lineWidth = 2.0
        container.addChild(bg)

        let plus = SKLabelNode(text: "+")
        plus.fontName = "AvenirNext-Bold"
        plus.fontSize = 48
        plus.fontColor = SKColor(white: 0.4, alpha: 0.6)
        plus.verticalAlignmentMode = .center
        plus.position = CGPoint(x: 0, y: 10)
        container.addChild(plus)

        let label = SKLabelNode(text: "New Player")
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 13
        label.fontColor = SKColor(white: 0.4, alpha: 0.6)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -25)
        container.addChild(label)

        return container
    }

    // MARK: - Name Entry

    private func showNameEntry() {
        mode = .creatingName
        clearContent()
        pendingName = ""

        let title = SKLabelNode(text: "Enter Your Name")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = min(size.width * 0.07, 28)
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.88)
        title.zPosition = 10
        title.name = "content"
        addChild(title)

        // Name display
        let nameDisplay = SKLabelNode(text: "_")
        nameDisplay.fontName = "AvenirNext-Heavy"
        nameDisplay.fontSize = 32
        nameDisplay.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        nameDisplay.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        nameDisplay.zPosition = 10
        nameDisplay.name = "nameDisplay"
        addChild(nameDisplay)

        buildLetterKeyboard(startY: size.height * 0.68, nextButtonName: "nextFromName")

        // Back button
        addBackButton(action: "backToGrid")
    }

    /// Shared keyboard builder for name entry and edit profile screens.
    /// Layout: 4 rows of 7 letters (VWXYZ on row 4), then row 5 with ⌫ and Next.
    private func buildLetterKeyboard(startY: CGFloat, nextButtonName: String, nextButtonLabel: String = "Next →") {
        let rows: [[Character]] = [
            ["A","B","C","D","E","F","G"],
            ["H","I","J","K","L","M","N"],
            ["O","P","Q","R","S","T","U"],
            ["V","W","X","Y","Z"]
        ]
        let cols = 7
        let btnSize: CGFloat = min(size.width / 9, 42)
        let spacing: CGFloat = 4
        let totalW = CGFloat(cols) * btnSize + CGFloat(cols - 1) * spacing
        let gridStartX = (size.width - totalW) / 2 + btnSize / 2

        for (row, letters) in rows.enumerated() {
            // Centre shorter rows
            let rowOffsetX: CGFloat
            if letters.count < cols {
                rowOffsetX = CGFloat(cols - letters.count) * (btnSize + spacing) / 2
            } else {
                rowOffsetX = 0
            }

            for (col, char) in letters.enumerated() {
                let x = gridStartX + CGFloat(col) * (btnSize + spacing) + rowOffsetX
                let y = startY - CGFloat(row) * (btnSize + spacing)

                let btn = SKNode()
                btn.position = CGPoint(x: x, y: y)
                btn.zPosition = 10
                btn.name = "letter_\(char)"

                let bg = SKShapeNode(rectOf: CGSize(width: btnSize, height: btnSize), cornerRadius: 8)
                bg.fillColor = SKColor(white: 0.15, alpha: 0.8)
                bg.strokeColor = SKColor(white: 0.3, alpha: 0.6)
                bg.lineWidth = 1
                btn.addChild(bg)

                let label = SKLabelNode(text: String(char))
                label.fontName = "AvenirNext-Bold"
                label.fontSize = btnSize * 0.45
                label.fontColor = .white
                label.verticalAlignmentMode = .center
                btn.addChild(label)

                addChild(btn)
            }
        }

        // Row 5: ⌫ Backspace and Next →
        let row5Y = startY - 4 * (btnSize + spacing)
        let wideWidth = (totalW - spacing) / 2

        // Delete button
        let delBtn = SKNode()
        delBtn.position = CGPoint(x: size.width / 2 - wideWidth / 2 - spacing / 2, y: row5Y)
        delBtn.zPosition = 10
        delBtn.name = "deleteChar"

        let delBg = SKShapeNode(rectOf: CGSize(width: wideWidth, height: btnSize), cornerRadius: 8)
        delBg.fillColor = SKColor(red: 0.4, green: 0.15, blue: 0.15, alpha: 0.8)
        delBg.strokeColor = SKColor(red: 0.6, green: 0.3, blue: 0.3, alpha: 0.6)
        delBg.lineWidth = 1
        delBtn.addChild(delBg)

        let delLabel = SKLabelNode(text: "⌫ Delete")
        delLabel.fontName = "AvenirNext-Bold"
        delLabel.fontSize = btnSize * 0.38
        delLabel.fontColor = .white
        delLabel.verticalAlignmentMode = .center
        delBtn.addChild(delLabel)
        addChild(delBtn)

        // Next button (green, prominent)
        let nextBtn = SKNode()
        nextBtn.position = CGPoint(x: size.width / 2 + wideWidth / 2 + spacing / 2, y: row5Y)
        nextBtn.zPosition = 10
        nextBtn.name = nextButtonName

        let nextBg = SKShapeNode(rectOf: CGSize(width: wideWidth, height: btnSize), cornerRadius: 8)
        nextBg.fillColor = SKColor(red: 0.1, green: 0.5, blue: 0.2, alpha: 0.9)
        nextBg.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 0.8)
        nextBg.lineWidth = 2
        nextBg.glowWidth = 2
        nextBtn.addChild(nextBg)

        let nextLabel = SKLabelNode(text: nextButtonLabel)
        nextLabel.fontName = "AvenirNext-Bold"
        nextLabel.fontSize = btnSize * 0.42
        nextLabel.fontColor = .white
        nextLabel.verticalAlignmentMode = .center
        nextBtn.addChild(nextLabel)
        addChild(nextBtn)
    }

    private func updateNameDisplay() {
        if let display = childNode(withName: "nameDisplay") as? SKLabelNode {
            display.text = pendingName.isEmpty ? "_" : pendingName
        }
    }

    // MARK: - Avatar Picker

    private func showAvatarPicker() {
        mode = .creatingAvatar
        clearContent()
        pendingAvatar = GameManager.avatarOptions[0]

        let title = SKLabelNode(text: "Choose Your Ship")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = min(size.width * 0.07, 28)
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.85)
        title.zPosition = 10
        title.name = "content"
        addChild(title)

        // Name preview
        let preview = SKLabelNode(text: pendingName)
        preview.fontName = "AvenirNext-Heavy"
        preview.fontSize = 24
        preview.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        preview.position = CGPoint(x: size.width / 2, y: size.height * 0.76)
        preview.zPosition = 10
        preview.name = "content"
        addChild(preview)

        let avatars = GameManager.avatarOptions
        let btnSize: CGFloat = 60
        let spacing: CGFloat = 12
        let totalW = CGFloat(avatars.count) * btnSize + CGFloat(avatars.count - 1) * spacing
        let startX = (size.width - totalW) / 2 + btnSize / 2

        for (i, emoji) in avatars.enumerated() {
            let x = startX + CGFloat(i) * (btnSize + spacing)

            let btn = SKNode()
            btn.position = CGPoint(x: x, y: size.height * 0.58)
            btn.zPosition = 10
            btn.name = "avatar_\(i)"

            let bg = SKShapeNode(circleOfRadius: btnSize / 2)
            bg.fillColor = SKColor(white: 0.15, alpha: 0.8)
            bg.strokeColor = i == 0
                ? SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
                : SKColor(white: 0.3, alpha: 0.5)
            bg.lineWidth = i == 0 ? 3 : 1.5
            bg.name = "avatarBg_\(i)"
            btn.addChild(bg)

            let label = SKLabelNode(text: emoji)
            label.fontSize = 36
            label.verticalAlignmentMode = .center
            btn.addChild(label)

            addChild(btn)
        }

        // Next button
        let nextBtn = SKNode()
        nextBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.40)
        nextBtn.zPosition = 10
        nextBtn.name = "nextFromAvatar"

        let nextBg = SKShapeNode(rectOf: CGSize(width: 140, height: 44), cornerRadius: 12)
        nextBg.fillColor = SKColor(red: 0.1, green: 0.3, blue: 0.15, alpha: 0.8)
        nextBg.strokeColor = SKColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 0.6)
        nextBg.lineWidth = 2
        nextBtn.addChild(nextBg)

        let nextLabel = SKLabelNode(text: "Next →")
        nextLabel.fontName = "AvenirNext-Bold"
        nextLabel.fontSize = 18
        nextLabel.fontColor = .white
        nextLabel.verticalAlignmentMode = .center
        nextBtn.addChild(nextLabel)
        addChild(nextBtn)

        addBackButton(action: "backToName")
    }

    private func selectAvatar(_ index: Int) {
        let avatars = GameManager.avatarOptions
        guard index < avatars.count else { return }
        pendingAvatar = avatars[index]

        // Update visual selection
        for i in 0..<avatars.count {
            if let btn = childNode(withName: "avatar_\(i)"),
               let bg = btn.childNode(withName: "avatarBg_\(i)") as? SKShapeNode {
                if i == index {
                    bg.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
                    bg.lineWidth = 3
                } else {
                    bg.strokeColor = SKColor(white: 0.3, alpha: 0.5)
                    bg.lineWidth = 1.5
                }
            }
        }
    }

    // MARK: - Age Group Picker

    private func showAgeGroupPicker() {
        mode = .creatingAgeGroup
        clearContent()

        let title = SKLabelNode(text: "Choose Difficulty")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = min(size.width * 0.07, 28)
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.88)
        title.zPosition = 10
        title.name = "content"
        addChild(title)

        // Preview name + avatar
        let preview = SKLabelNode(text: "\(pendingAvatar) \(pendingName)")
        preview.fontName = "AvenirNext-Heavy"
        preview.fontSize = 22
        preview.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        preview.position = CGPoint(x: size.width / 2, y: size.height * 0.80)
        preview.zPosition = 10
        preview.name = "content"
        addChild(preview)

        let groups: [(AgeGroup, String, SKColor)] = [
            (.cadet, "🚀 Space Cadet (4-7)", SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)),
            (.pilot, "⭐ Star Pilot (7-10)", SKColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0)),
            (.ace, "🌟 Ace Commander (10-13)", SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0))
        ]

        let buttonWidth = min(size.width * 0.85, 350.0)
        let buttonHeight: CGFloat = 60
        let spacing: CGFloat = 20
        let totalHeight = CGFloat(groups.count) * buttonHeight + CGFloat(groups.count - 1) * spacing
        let startY = size.height * 0.52 + totalHeight / 2 - buttonHeight / 2

        for (i, group) in groups.enumerated() {
            let y = startY - CGFloat(i) * (buttonHeight + spacing)
            let btn = createStyledButton(
                text: group.1,
                color: group.2,
                position: CGPoint(x: size.width / 2, y: y),
                buttonSize: CGSize(width: buttonWidth, height: buttonHeight),
                nodeName: "ageGroup_\(group.0.rawValue)"
            )
            addChild(btn)
        }

        addBackButton(action: "backToAvatar")
    }

    // MARK: - Action Menu (long press)

    private func showActionMenu(slotIndex: Int) {
        mode = .actionMenu
        editingSlotIndex = slotIndex
        guard let profile = GameManager.shared.slots[slotIndex] else { return }

        // Dim overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = SKColor(white: 0, alpha: 0.6)
        overlay.strokeColor = .clear
        overlay.zPosition = 50
        overlay.name = "overlay"
        addChild(overlay)

        let menuW: CGFloat = min(size.width * 0.7, 240)
        let menuH: CGFloat = 180
        let menuBg = SKShapeNode(rectOf: CGSize(width: menuW, height: menuH), cornerRadius: 16)
        menuBg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        menuBg.fillColor = SKColor(red: 0.08, green: 0.05, blue: 0.18, alpha: 0.95)
        menuBg.strokeColor = SKColor(white: 0.3, alpha: 0.5)
        menuBg.lineWidth = 1.5
        menuBg.zPosition = 51
        menuBg.name = "overlay"
        addChild(menuBg)

        // Title
        let titleLabel = SKLabelNode(text: "\(profile.avatar) \(profile.name)")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 18
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 55)
        titleLabel.zPosition = 52
        titleLabel.name = "overlay"
        addChild(titleLabel)

        // Edit button
        let editBtn = createMenuButton(
            text: "Edit Player",
            color: SKColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0),
            position: CGPoint(x: size.width / 2, y: size.height / 2 + 10),
            width: menuW - 30,
            nodeName: "editPlayer"
        )
        editBtn.zPosition = 52
        addChild(editBtn)

        // Delete button
        let delBtn = createMenuButton(
            text: "Delete Player",
            color: SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0),
            position: CGPoint(x: size.width / 2, y: size.height / 2 - 40),
            width: menuW - 30,
            nodeName: "deletePlayer"
        )
        delBtn.zPosition = 52
        addChild(delBtn)

        // Cancel
        let cancelLabel = SKLabelNode(text: "Cancel")
        cancelLabel.fontName = "AvenirNext-Medium"
        cancelLabel.fontSize = 14
        cancelLabel.fontColor = SKColor(white: 0.6, alpha: 0.8)
        cancelLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 75)
        cancelLabel.zPosition = 52
        cancelLabel.name = "cancelMenu"
        addChild(cancelLabel)
    }

    private func createMenuButton(text: String, color: SKColor, position: CGPoint, width: CGFloat, nodeName: String) -> SKNode {
        let btn = SKNode()
        btn.position = position
        btn.name = nodeName

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 36), cornerRadius: 10)
        bg.fillColor = color.withAlphaComponent(0.25)
        bg.strokeColor = color.withAlphaComponent(0.7)
        bg.lineWidth = 1.5
        btn.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 15
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        btn.addChild(label)

        return btn
    }

    // MARK: - Delete Confirm

    private func showDeleteConfirm() {
        mode = .deleteConfirm
        removeOverlays()

        guard let profile = GameManager.shared.slots[editingSlotIndex] else { return }

        let overlay = SKShapeNode(rectOf: size)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = SKColor(white: 0, alpha: 0.7)
        overlay.strokeColor = .clear
        overlay.zPosition = 50
        overlay.name = "overlay"
        addChild(overlay)

        let boxW: CGFloat = min(size.width * 0.75, 260)
        let boxH: CGFloat = 160
        let box = SKShapeNode(rectOf: CGSize(width: boxW, height: boxH), cornerRadius: 16)
        box.position = CGPoint(x: size.width / 2, y: size.height / 2)
        box.fillColor = SKColor(red: 0.1, green: 0.05, blue: 0.15, alpha: 0.95)
        box.strokeColor = SKColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 0.6)
        box.lineWidth = 1.5
        box.zPosition = 51
        box.name = "overlay"
        addChild(box)

        let msg = SKLabelNode(text: "Delete \(profile.name)?")
        msg.fontName = "AvenirNext-Bold"
        msg.fontSize = 18
        msg.fontColor = .white
        msg.position = CGPoint(x: size.width / 2, y: size.height / 2 + 45)
        msg.zPosition = 52
        msg.name = "overlay"
        addChild(msg)

        let sub1 = SKLabelNode(text: "All of \(profile.name)'s progress will be")
        sub1.fontName = "AvenirNext-Regular"
        sub1.fontSize = 12
        sub1.fontColor = SKColor(white: 0.6, alpha: 0.9)
        sub1.position = CGPoint(x: size.width / 2, y: size.height / 2 + 22)
        sub1.zPosition = 52
        sub1.name = "overlay"
        addChild(sub1)

        let sub2 = SKLabelNode(text: "lost forever. This cannot be undone.")
        sub2.fontName = "AvenirNext-Regular"
        sub2.fontSize = 12
        sub2.fontColor = SKColor(white: 0.6, alpha: 0.9)
        sub2.position = CGPoint(x: size.width / 2, y: size.height / 2 + 8)
        sub2.zPosition = 52
        sub2.name = "overlay"
        addChild(sub2)

        // Confirm delete
        let delBtn = createMenuButton(
            text: "Delete",
            color: SKColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1.0),
            position: CGPoint(x: size.width / 2, y: size.height / 2 - 25),
            width: boxW - 40,
            nodeName: "confirmDelete"
        )
        delBtn.zPosition = 52
        addChild(delBtn)

        let cancelLabel = SKLabelNode(text: "Cancel")
        cancelLabel.fontName = "AvenirNext-Medium"
        cancelLabel.fontSize = 14
        cancelLabel.fontColor = SKColor(white: 0.6, alpha: 0.8)
        cancelLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 60)
        cancelLabel.zPosition = 52
        cancelLabel.name = "cancelMenu"
        addChild(cancelLabel)
    }

    // MARK: - Edit Profile

    private func showEditProfile() {
        mode = .editingProfile
        clearContent()
        removeOverlays()

        guard let profile = GameManager.shared.slots[editingSlotIndex] else {
            showSlotGrid()
            return
        }

        pendingName = profile.name
        pendingAvatar = profile.avatar

        let title = SKLabelNode(text: "Edit Player")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = min(size.width * 0.07, 28)
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.88)
        title.zPosition = 10
        title.name = "content"
        addChild(title)

        // Name display
        let nameDisplay = SKLabelNode(text: pendingName)
        nameDisplay.fontName = "AvenirNext-Heavy"
        nameDisplay.fontSize = 28
        nameDisplay.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        nameDisplay.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        nameDisplay.zPosition = 10
        nameDisplay.name = "nameDisplay"
        addChild(nameDisplay)

        // Letter grid + delete (reuse shared builder — "saveEdit" as the next/save action)
        let kbStartY = size.height * 0.68
        buildLetterKeyboard(startY: kbStartY, nextButtonName: "saveEdit", nextButtonLabel: "Save ✓")

        // Avatar row below keyboard
        let btnSize: CGFloat = min(size.width / 9, 42)
        let spacing: CGFloat = 4
        let avatarRowY = kbStartY - 5 * (btnSize + spacing) - 20
        let avatars = GameManager.avatarOptions
        let avatarBtnSize: CGFloat = 48
        let avatarSpacing: CGFloat = 10
        let avatarTotalW = CGFloat(avatars.count) * avatarBtnSize + CGFloat(avatars.count - 1) * avatarSpacing
        let avatarStartX = (size.width - avatarTotalW) / 2 + avatarBtnSize / 2

        for (i, emoji) in avatars.enumerated() {
            let x = avatarStartX + CGFloat(i) * (avatarBtnSize + avatarSpacing)

            let btn = SKNode()
            btn.position = CGPoint(x: x, y: avatarRowY)
            btn.zPosition = 10
            btn.name = "avatar_\(i)"

            let isSelected = emoji == pendingAvatar
            let bg = SKShapeNode(circleOfRadius: avatarBtnSize / 2)
            bg.fillColor = SKColor(white: 0.15, alpha: 0.8)
            bg.strokeColor = isSelected
                ? SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
                : SKColor(white: 0.3, alpha: 0.5)
            bg.lineWidth = isSelected ? 3 : 1.5
            bg.name = "avatarBg_\(i)"
            btn.addChild(bg)

            let label = SKLabelNode(text: emoji)
            label.fontSize = 28
            label.verticalAlignmentMode = .center
            btn.addChild(label)

            addChild(btn)
        }

        addBackButton(action: "backToGrid")
    }

    // MARK: - Helpers

    private func clearContent() {
        children.filter { $0.name != nil && $0.name != "//starField" }
            .filter { $0 !== starField }
            .forEach { $0.removeFromParent() }
        slotNodes.removeAll()
    }

    private func removeOverlays() {
        children.filter { $0.name == "overlay" || $0.name == "editPlayer" || $0.name == "deletePlayer" || $0.name == "cancelMenu" || $0.name == "confirmDelete" }
            .forEach { $0.removeFromParent() }
    }

    private func addBackButton(action: String) {
        let backBtn = SKNode()
        backBtn.position = CGPoint(x: 45, y: size.height - 35)
        backBtn.zPosition = 10
        backBtn.name = action

        let backBg = SKShapeNode(rectOf: CGSize(width: 70, height: 28), cornerRadius: 8)
        backBg.fillColor = SKColor(white: 0.15, alpha: 0.7)
        backBg.strokeColor = SKColor(white: 0.4, alpha: 0.5)
        backBtn.addChild(backBg)

        let backLabel = SKLabelNode(text: "◀ Back")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 14
        backLabel.fontColor = SKColor(white: 0.7, alpha: 0.9)
        backLabel.verticalAlignmentMode = .center
        backBtn.addChild(backLabel)

        addChild(backBtn)
    }

    private func createStyledButton(text: String, color: SKColor, position: CGPoint, buttonSize: CGSize, nodeName: String) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 10
        container.name = nodeName

        let bg = SKShapeNode(rectOf: buttonSize, cornerRadius: 15)
        bg.fillColor = color.withAlphaComponent(0.2)
        bg.strokeColor = color.withAlphaComponent(0.8)
        bg.lineWidth = 2.5
        bg.glowWidth = 2.0
        container.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = min(size.width * 0.045, 20)
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        let glow = SKAction.sequence([
            SKAction.run { bg.glowWidth = 4.0 },
            SKAction.wait(forDuration: 1.0),
            SKAction.run { bg.glowWidth = 2.0 },
            SKAction.wait(forDuration: 1.0)
        ])
        container.run(SKAction.repeatForever(glow))

        return container
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStartTime = CACurrentMediaTime()

        if mode == .slotGrid {
            let location = touch.location(in: self)
            // Check for long press on occupied slots
            for i in 0..<GameManager.maxSlots {
                if let slotNode = slotNodes[i], GameManager.shared.slots[i] != nil {
                    let dist = hypot(location.x - slotNode.position.x, location.y - slotNode.position.y)
                    if dist < 90 {
                        longPressSlot = i
                        longPressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                            self?.handleLongPress()
                        }
                        return
                    }
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        longPressTimer?.invalidate()
        longPressTimer = nil

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let elapsed = CACurrentMediaTime() - touchStartTime

        AudioManager.shared.playMenuTap()

        switch mode {
        case .slotGrid:
            handleSlotGridTap(location: location, elapsed: elapsed)
        case .creatingName:
            handleNameEntryTap(location: location)
        case .creatingAvatar:
            handleAvatarPickerTap(location: location)
        case .creatingAgeGroup:
            handleAgeGroupTap(location: location)
        case .editingProfile:
            handleEditProfileTap(location: location)
        case .actionMenu:
            handleActionMenuTap(location: location)
        case .deleteConfirm:
            handleDeleteConfirmTap(location: location)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        longPressTimer?.invalidate()
        longPressTimer = nil
        longPressSlot = nil
    }

    private func handleLongPress() {
        longPressTimer = nil
        guard let slot = longPressSlot else { return }
        longPressSlot = nil
        showActionMenu(slotIndex: slot)
    }

    // MARK: - Tap Handlers

    private func handleSlotGridTap(location: CGPoint, elapsed: TimeInterval) {
        // Back button
        if let backBtn = childNode(withName: "backButton") {
            let dist = hypot(location.x - backBtn.position.x, location.y - backBtn.position.y)
            if dist < 50 {
                let transition = SKTransition.push(with: .right, duration: 0.5)
                let title = TitleScene(size: size)
                title.scaleMode = .resizeFill
                view?.presentScene(title, transition: transition)
                return
            }
        }

        // Only handle short taps (long press handled by timer)
        guard elapsed < 0.8 else { return }

        // Find closest slot
        let gm = GameManager.shared
        for i in 0..<GameManager.maxSlots {
            guard let slotNode = slotNodes[i] else { continue }
            let dist = hypot(location.x - slotNode.position.x, location.y - slotNode.position.y)
            if dist < 90 {
                if gm.slots[i] != nil {
                    // Select and start game
                    gm.selectSlot(i)
                    gm.startNewGame(ageGroup: gm.ageGroup)
                    transitionToGame()
                } else {
                    // Start creation flow
                    pendingSlotIndex = i
                    showNameEntry()
                }
                return
            }
        }
    }

    private func handleNameEntryTap(location: CGPoint) {
        for child in children {
            guard let name = child.name else { continue }
            let dist = hypot(location.x - child.position.x, location.y - child.position.y)

            if name == "backToGrid" && dist < 50 {
                showSlotGrid()
                return
            }

            if name.starts(with: "letter_") && dist < 30 {
                if pendingName.count < 8 {
                    let letter = String(name.dropFirst(7))
                    pendingName += letter
                    updateNameDisplay()
                }
                return
            }

            if name == "deleteChar" && dist < 40 {
                if !pendingName.isEmpty {
                    pendingName.removeLast()
                    updateNameDisplay()
                }
                return
            }

            if name == "nextFromName" && dist < 50 {
                if !pendingName.isEmpty {
                    showAvatarPicker()
                }
                return
            }
        }
    }

    private func handleAvatarPickerTap(location: CGPoint) {
        for child in children {
            guard let name = child.name else { continue }
            let dist = hypot(location.x - child.position.x, location.y - child.position.y)

            if name == "backToName" && dist < 50 {
                showNameEntry()
                return
            }

            if name.starts(with: "avatar_") && dist < 40 {
                if let index = Int(String(name.dropFirst(7))) {
                    selectAvatar(index)
                }
                return
            }

            if name == "nextFromAvatar" && dist < 60 {
                showAgeGroupPicker()
                return
            }
        }
    }

    private func handleAgeGroupTap(location: CGPoint) {
        for child in children {
            guard let name = child.name else { continue }
            let dist = hypot(location.x - child.position.x, location.y - child.position.y)

            if name == "backToAvatar" && dist < 50 {
                showAvatarPicker()
                return
            }

            if name.starts(with: "ageGroup_") && dist < 100 {
                let groupName = String(name.dropFirst(9))
                if let ageGroup = AgeGroup(rawValue: groupName) {
                    let gm = GameManager.shared
                    gm.createProfile(slotIndex: pendingSlotIndex, name: pendingName, avatar: pendingAvatar, ageGroup: ageGroup)
                    gm.startNewGame(ageGroup: ageGroup)
                    transitionToGame()
                }
                return
            }
        }
    }

    private func handleEditProfileTap(location: CGPoint) {
        for child in children {
            guard let name = child.name else { continue }
            let dist = hypot(location.x - child.position.x, location.y - child.position.y)

            if name == "backToGrid" && dist < 50 {
                showSlotGrid()
                return
            }

            if name.starts(with: "letter_") && dist < 30 {
                if pendingName.count < 8 {
                    let letter = String(name.dropFirst(7))
                    pendingName += letter
                    updateNameDisplay()
                }
                return
            }

            if name == "deleteChar" && dist < 40 {
                if !pendingName.isEmpty {
                    pendingName.removeLast()
                    updateNameDisplay()
                }
                return
            }

            if name.starts(with: "avatar_") && dist < 35 {
                if let index = Int(String(name.dropFirst(7))) {
                    selectAvatar(index)
                }
                return
            }

            if name == "saveEdit" && dist < 60 {
                if !pendingName.isEmpty {
                    GameManager.shared.updateProfile(slotIndex: editingSlotIndex, name: pendingName, avatar: pendingAvatar)
                    showSlotGrid()
                }
                return
            }
        }
    }

    private func handleActionMenuTap(location: CGPoint) {
        for child in children {
            guard let name = child.name else { continue }
            let dist = hypot(location.x - child.position.x, location.y - child.position.y)

            if name == "editPlayer" && dist < 80 {
                showEditProfile()
                return
            }

            if name == "deletePlayer" && dist < 80 {
                showDeleteConfirm()
                return
            }

            if name == "cancelMenu" && dist < 50 {
                removeOverlays()
                mode = .slotGrid
                return
            }
        }

        // Tap outside menu = cancel
        removeOverlays()
        mode = .slotGrid
    }

    private func handleDeleteConfirmTap(location: CGPoint) {
        for child in children {
            guard let name = child.name else { continue }
            let dist = hypot(location.x - child.position.x, location.y - child.position.y)

            if name == "confirmDelete" && dist < 80 {
                GameManager.shared.deleteSlot(editingSlotIndex)
                removeOverlays()
                showSlotGrid()
                return
            }

            if name == "cancelMenu" && dist < 50 {
                removeOverlays()
                showSlotGrid()
                return
            }
        }
    }

    // MARK: - Transitions

    private func transitionToGame() {
        let transition = SKTransition.doorway(withDuration: 1.0)
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .resizeFill
        gameScene.selectedAgeGroup = GameManager.shared.ageGroup
        view?.presentScene(gameScene, transition: transition)
    }

    override func update(_ currentTime: TimeInterval) {
        starField?.update(deltaTime: 1.0 / 60.0)
    }
}
