import SpriteKit

final class SectorSentinel: SKNode {
    private var body: SKShapeNode!
    private var problemLabel: SKLabelNode!
    private var healthBar: SKShapeNode!
    private var ageGroup: AgeGroup = .cadet
    var problem: MathProblem?

    func setup(ageGroup: AgeGroup, sceneSize: CGSize) {
        self.ageGroup = ageGroup
        removeAllChildren()

        let stationSize = CGSize(width: 120, height: 80)

        // Main body - hexagonal station
        let path = CGMutablePath()
        let hw = stationSize.width / 2
        let hh = stationSize.height / 2
        path.move(to: CGPoint(x: -hw * 0.6, y: hh))
        path.addLine(to: CGPoint(x: hw * 0.6, y: hh))
        path.addLine(to: CGPoint(x: hw, y: 0))
        path.addLine(to: CGPoint(x: hw * 0.6, y: -hh))
        path.addLine(to: CGPoint(x: -hw * 0.6, y: -hh))
        path.addLine(to: CGPoint(x: -hw, y: 0))
        path.closeSubpath()

        body = SKShapeNode(path: path)

        switch ageGroup {
        case .cadet:
            body.fillColor = SKColor(red: 0.6, green: 0.2, blue: 0.0, alpha: 0.9)
            body.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
        case .pilot:
            body.fillColor = SKColor(red: 0.1, green: 0.2, blue: 0.5, alpha: 0.9)
            body.strokeColor = SKColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0)
        case .ace:
            body.fillColor = SKColor(red: 0.3, green: 0.0, blue: 0.4, alpha: 0.9)
            body.strokeColor = SKColor(red: 0.8, green: 0.3, blue: 1.0, alpha: 1.0)
        }

        body.lineWidth = 3.0
        body.glowWidth = 5.0
        addChild(body)

        // Inner detail
        let inner = SKShapeNode(circleOfRadius: 20)
        inner.fillColor = body.strokeColor.withAlphaComponent(0.3)
        inner.strokeColor = body.strokeColor
        inner.lineWidth = 1.5
        body.addChild(inner)

        // Pulsing glow
        let pulse = SKAction.sequence([
            SKAction.run { [weak self] in self?.body.glowWidth = 8.0 },
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in self?.body.glowWidth = 4.0 },
            SKAction.wait(forDuration: 0.5)
        ])
        run(SKAction.repeatForever(pulse))

        // Scale 0 initially
        setScale(0.1)
        alpha = 0
    }

    func appear(at position: CGPoint, completion: @escaping () -> Void) {
        self.position = position
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.8)
        scaleUp.timingMode = .easeOut
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        run(SKAction.group([scaleUp, fadeIn])) {
            completion()
        }
    }

    func showProblem(_ problem: MathProblem) {
        self.problem = problem
        problemLabel?.removeFromParent()

        problemLabel = SKLabelNode(text: problem.question)
        problemLabel.fontName = "AvenirNext-Bold"
        problemLabel.fontSize = 16
        problemLabel.fontColor = .white
        problemLabel.position = CGPoint(x: 0, y: -50)
        problemLabel.zPosition = 1
        addChild(problemLabel)
    }

    func destroy(completion: @escaping () -> Void) {
        let shrink = SKAction.scale(to: 0.0, duration: 0.5)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let group = SKAction.group([shrink, fade])
        run(SKAction.sequence([group, SKAction.run(completion), SKAction.removeFromParent()]))
    }

    func shake() {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -8, y: 0, duration: 0.05),
            SKAction.moveBy(x: 16, y: 0, duration: 0.05),
            SKAction.moveBy(x: -16, y: 0, duration: 0.05),
            SKAction.moveBy(x: 8, y: 0, duration: 0.05)
        ])
        run(shake)
    }
}
