import SpriteKit

final class ProblemDisplayNode: SKNode {
    private var background: SKShapeNode!
    private var questionLabel: SKLabelNode!
    private var subtitleLabel: SKLabelNode!
    private var grade: Grade = .kindergarten
    private var panelWidth: CGFloat = 0
    private var currentPanelHeight: CGFloat = 80

    /// Panel is top-anchored: local y=0 is the top edge, panel expands downward.
    func setup(grade: Grade, width: CGFloat) {
        self.grade = grade
        self.panelWidth = min(width * 0.88, 500)
        removeAllChildren()

        buildPanel(height: 80)

        questionLabel = SKLabelNode(text: "")
        questionLabel.fontName = "AvenirNext-Heavy"
        questionLabel.fontSize = grade.rawValue < 2 ? 26 : 22
        questionLabel.fontColor = .white
        questionLabel.verticalAlignmentMode = .center
        questionLabel.horizontalAlignmentMode = .center
        questionLabel.position = CGPoint(x: 0, y: -28)
        questionLabel.zPosition = 1
        background.addChild(questionLabel)

        subtitleLabel = SKLabelNode(text: "")
        subtitleLabel.fontName = "AvenirNext-Medium"
        subtitleLabel.fontSize = 12
        subtitleLabel.fontColor = SKColor(white: 0.65, alpha: 0.9)
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: 0, y: -58)
        subtitleLabel.zPosition = 1
        background.addChild(subtitleLabel)
    }

    private func buildPanel(height: CGFloat) {
        currentPanelHeight = height
        // Top at y=0, bottom at y=-height
        let rect = CGRect(x: -panelWidth / 2, y: -height, width: panelWidth, height: height)
        background = SKShapeNode(rect: rect, cornerRadius: 12)
        background.fillColor = SKColor(red: 0.15, green: 0.05, blue: 0.3, alpha: 0.85)
        background.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.8)
        background.lineWidth = 2.0
        background.glowWidth = 2.0
        addChild(background)
    }

    private func rebuildPanel(height: CGFloat) {
        guard height != currentPanelHeight else { return }

        questionLabel.removeFromParent()
        subtitleLabel.removeFromParent()
        background.removeFromParent()

        buildPanel(height: height)
        background.addChild(questionLabel)
        background.addChild(subtitleLabel)
    }

    func showProblem(_ question: String, topic: String = "") {
        // Clear previous counting emoji nodes
        background.children.filter { $0.name == "countEmoji" }.forEach { $0.removeFromParent() }

        if question.hasPrefix("Count:") {
            let emojiStr = question
                .replacingOccurrences(of: "Count: ", with: "")
                .replacingOccurrences(of: "Count:", with: "")
            // Split on spaces to get individual emoji safely (no broken multi-byte chars)
            let emojis = emojiStr.split(separator: " ").map(String.init)
            let count = emojis.count
            let maxPerRow = 5
            let rowCount = (count + maxPerRow - 1) / maxPerRow

            // Panel height: 80 for 1 row, 112 for 2, 140 for 3, 168 for 4
            let panelHeight: CGFloat = rowCount <= 1 ? 80 : CGFloat(52 + rowCount * 32)

            // Resize panel — expands downward from top
            rebuildPanel(height: panelHeight)

            // "Count:" label — small, subtle, near top
            questionLabel.text = "Count:"
            questionLabel.fontName = "AvenirNext-Medium"
            questionLabel.fontSize = 16
            questionLabel.fontColor = SKColor(white: 0.7, alpha: 0.9)
            questionLabel.position = CGPoint(x: 0, y: -18)

            subtitleLabel.text = ""

            // Lay out individual emoji nodes
            let emojiSize: CGFloat = count > 10 ? 28 : 36
            let hSpacing: CGFloat = emojiSize + 10

            // First row Y starts at -48 for 1-2 rows, or -40 for 3+ rows
            let firstRowY: CGFloat = rowCount <= 2 ? -48 : -40
            let rowSpacing: CGFloat = count > 10 ? 30 : 36

            for (i, emoji) in emojis.enumerated() {
                let row = i / maxPerRow
                let col = i % maxPerRow
                let itemsInRow = min(maxPerRow, count - row * maxPerRow)
                let rowWidth = CGFloat(itemsInRow) * hSpacing - 10
                let startX = -rowWidth / 2 + emojiSize / 2

                let label = SKLabelNode(text: emoji)
                label.fontSize = emojiSize
                label.name = "countEmoji"
                label.verticalAlignmentMode = .center
                label.horizontalAlignmentMode = .center
                label.zPosition = 1

                let y = firstRowY - CGFloat(row) * rowSpacing

                label.position = CGPoint(x: startX + CGFloat(col) * hSpacing, y: y)
                background.addChild(label)
            }
        } else {
            // Regular question
            rebuildPanel(height: 80)

            questionLabel.text = question
            questionLabel.fontName = "AvenirNext-Heavy"
            questionLabel.fontSize = grade.rawValue < 2 ? 26 : 22
            questionLabel.fontColor = .white
            questionLabel.position = CGPoint(x: 0, y: -28)

            subtitleLabel.text = topic
            subtitleLabel.fontSize = 12
            subtitleLabel.fontColor = SKColor(white: 0.65, alpha: 0.9)
            subtitleLabel.position = CGPoint(x: 0, y: -58)
        }

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        run(pulse)
    }

    func startPulse() {
        let pulse = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.background.glowWidth = 4.0
            },
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in
                self?.background.glowWidth = 2.0
            },
            SKAction.wait(forDuration: 0.8)
        ])
        run(SKAction.repeatForever(pulse), withKey: "pulse")
    }

    func stopPulse() {
        removeAction(forKey: "pulse")
        background.glowWidth = 2.0
    }

    func hidePanel() {
        alpha = 0
    }

    func revealPanel() {
        alpha = 1.0
    }
}
