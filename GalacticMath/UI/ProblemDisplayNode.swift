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
            let emojis = Array(emojiStr)
            let count = emojis.count
            let needsTwoRows = count > 5

            // Resize panel — expands downward from top
            rebuildPanel(height: needsTwoRows ? 112 : 80)

            // "Count:" label — small, subtle, near top
            questionLabel.text = "Count:"
            questionLabel.fontName = "AvenirNext-Medium"
            questionLabel.fontSize = 16
            questionLabel.fontColor = SKColor(white: 0.7, alpha: 0.9)
            questionLabel.position = CGPoint(x: 0, y: -18)

            subtitleLabel.text = ""

            // Lay out individual emoji nodes — large and spaced
            let emojiSize: CGFloat = 36
            let hSpacing: CGFloat = emojiSize + 10
            let maxPerRow = 5

            for (i, emoji) in emojis.enumerated() {
                let row = i / maxPerRow
                let col = i % maxPerRow
                let itemsInRow = min(maxPerRow, count - row * maxPerRow)
                let rowWidth = CGFloat(itemsInRow) * hSpacing - 10
                let startX = -rowWidth / 2 + emojiSize / 2

                let label = SKLabelNode(text: String(emoji))
                label.fontSize = emojiSize
                label.name = "countEmoji"
                label.verticalAlignmentMode = .center
                label.horizontalAlignmentMode = .center
                label.zPosition = 1

                let y: CGFloat
                if needsTwoRows {
                    y = row == 0 ? -48 : -84
                } else {
                    y = -50
                }

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
}
