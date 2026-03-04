import SpriteKit

final class ProblemDisplayNode: SKNode {
    private var background: SKShapeNode!
    private var questionLabel: SKLabelNode!
    private var ageGroup: AgeGroup = .cadet
    private var decorLeft: SKLabelNode?
    private var decorRight: SKLabelNode?

    func setup(ageGroup: AgeGroup, width: CGFloat) {
        self.ageGroup = ageGroup
        removeAllChildren()

        let panelHeight: CGFloat = ageGroup == .cadet ? 60 : 50
        let panelWidth = min(width * 0.88, 500)

        let rect = CGRect(x: -panelWidth / 2, y: -panelHeight / 2, width: panelWidth, height: panelHeight)
        background = SKShapeNode(rect: rect, cornerRadius: 12)

        switch ageGroup {
        case .cadet:
            background.fillColor = SKColor(red: 0.15, green: 0.05, blue: 0.3, alpha: 0.85)
            background.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.8)
        case .pilot:
            background.fillColor = SKColor(red: 0.05, green: 0.1, blue: 0.25, alpha: 0.85)
            background.strokeColor = SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8)
        case .ace:
            background.fillColor = SKColor(red: 0.12, green: 0.02, blue: 0.2, alpha: 0.85)
            background.strokeColor = SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 0.8)
        }

        background.lineWidth = 2.0
        background.glowWidth = 2.0
        addChild(background)

        questionLabel = SKLabelNode(text: "")
        questionLabel.fontName = "AvenirNext-Heavy"
        questionLabel.fontSize = ageGroup == .cadet ? 30 : 24
        questionLabel.fontColor = .white
        questionLabel.verticalAlignmentMode = .center
        questionLabel.horizontalAlignmentMode = .center
        questionLabel.position = .zero
        questionLabel.zPosition = 1
        background.addChild(questionLabel)

        if ageGroup == .cadet {
            decorLeft = SKLabelNode(text: "\u{1F680}")
            decorLeft!.fontSize = 22
            decorLeft!.position = CGPoint(x: -panelWidth / 2 + 25, y: -4)
            decorLeft!.zPosition = 1
            background.addChild(decorLeft!)

            decorRight = SKLabelNode(text: "\u{1F31F}")
            decorRight!.fontSize = 22
            decorRight!.position = CGPoint(x: panelWidth / 2 - 25, y: -4)
            decorRight!.zPosition = 1
            background.addChild(decorRight!)
        }
    }

    func showProblem(_ question: String) {
        questionLabel.text = question

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
