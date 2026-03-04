import SpriteKit

final class NumberEnemy: SKNode {
    let answerValue: Int
    let beamIndex: Int
    let isCorrect: Bool

    private var background: SKShapeNode!
    private var label: SKLabelNode!
    private var ageGroup: AgeGroup

    init(answer: Int, beam: Int, isCorrect: Bool, ageGroup: AgeGroup, beamColor: SKColor) {
        self.answerValue = answer
        self.beamIndex = beam
        self.isCorrect = isCorrect
        self.ageGroup = ageGroup
        super.init()

        let size = ageGroup == .cadet ? CGSize(width: 55, height: 45) : CGSize(width: 50, height: 40)
        let rect = CGRect(origin: CGPoint(x: -size.width / 2, y: -size.height / 2), size: size)
        background = SKShapeNode(rect: rect, cornerRadius: 10)
        background.fillColor = beamColor.withAlphaComponent(0.7)
        background.strokeColor = beamColor
        background.lineWidth = 2.0
        background.glowWidth = 1.5
        addChild(background)

        label = SKLabelNode(text: "\(answer)")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = ageGroup == .cadet ? 24 : 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)

        if isCorrect {
            let shimmer = SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.background.glowWidth = 3.0
                },
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    self?.background.glowWidth = 1.5
                },
                SKAction.wait(forDuration: 0.5)
            ])
            run(SKAction.repeatForever(shimmer))
        }

        let float = SKAction.sequence([
            SKAction.moveBy(x: CGFloat.random(in: -3...3), y: 0, duration: 0.8),
            SKAction.moveBy(x: CGFloat.random(in: -3...3), y: 0, duration: 0.8)
        ])
        run(SKAction.repeatForever(float), withKey: "float")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bounceBack() {
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 30, duration: 0.2),
            SKAction.moveBy(x: 0, y: -30, duration: 0.3)
        ])
        run(bounce)
    }

    func explodeCorrect(completion: @escaping () -> Void) {
        removeAction(forKey: "float")

        let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let group = SKAction.group([scaleUp, fadeOut])

        run(SKAction.sequence([group, SKAction.run(completion), SKAction.removeFromParent()]))
    }

    func explodeWrong() {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
            SKAction.moveBy(x: 5, y: 0, duration: 0.05)
        ])
        background.fillColor = SKColor.red.withAlphaComponent(0.7)
        run(shake) { [weak self] in
            self?.background.fillColor = self?.ageGroup.beamColors[self?.beamIndex ?? 0 % (self?.ageGroup.beamColors.count ?? 1)].withAlphaComponent(0.7) ?? .gray
        }
    }
}
