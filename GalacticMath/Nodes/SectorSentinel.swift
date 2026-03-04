import SpriteKit

final class SectorSentinel: SKNode {
    private var body: SKShapeNode!
    private var glowCore: SKShapeNode!
    private var problemLabel: SKLabelNode!
    private var healthBar: SKShapeNode!
    private var ageGroup: AgeGroup = .cadet
    private var crackNodes: [SKShapeNode] = []
    var problem: MathProblem?

    private let bossRadius: CGFloat = 60

    func setup(ageGroup: AgeGroup, sceneSize: CGSize) {
        self.ageGroup = ageGroup
        removeAllChildren()
        crackNodes.removeAll()

        // Irregular polygon asteroid (10-14 vertices)
        let vertexCount = Int.random(in: 10...14)
        let path = CGMutablePath()

        for i in 0..<vertexCount {
            let angle = (CGFloat(i) / CGFloat(vertexCount)) * .pi * 2
            let radius = bossRadius * CGFloat.random(in: 0.7...1.0)
            let pt = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()

        body = SKShapeNode(path: path)
        body.fillColor = SKColor(white: 0.25, alpha: 1.0)
        body.strokeColor = SKColor(white: 0.5, alpha: 0.8)
        body.lineWidth = 3.0
        body.glowWidth = 4.0
        addChild(body)

        // Glowing core — age-group primary color
        glowCore = SKShapeNode(circleOfRadius: 20)
        let coreColor: SKColor
        switch ageGroup {
        case .cadet:
            coreColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
        case .pilot:
            coreColor = SKColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0)
        case .ace:
            coreColor = SKColor(red: 0.8, green: 0.3, blue: 1.0, alpha: 1.0)
        }
        glowCore.fillColor = coreColor.withAlphaComponent(0.4)
        glowCore.strokeColor = coreColor.withAlphaComponent(0.6)
        glowCore.lineWidth = 1.5
        glowCore.glowWidth = 3.0
        body.addChild(glowCore)

        // Core pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.8),
            SKAction.scale(to: 0.8, duration: 0.8)
        ])
        glowCore.run(SKAction.repeatForever(pulse))

        // Surface cracks (4-5)
        for _ in 0..<Int.random(in: 4...5) {
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let length = bossRadius * CGFloat.random(in: 0.4...0.9)
            let crackPath = CGMutablePath()
            crackPath.move(to: .zero)
            crackPath.addLine(to: CGPoint(x: cos(angle) * length, y: sin(angle) * length))

            let crack = SKShapeNode(path: crackPath)
            crack.strokeColor = SKColor(white: 0.6, alpha: 0.4)
            crack.lineWidth = 1.2
            crack.zPosition = 0.5
            addChild(crack)
            crackNodes.append(crack)
        }

        // Slow rotation (20s per revolution)
        let direction: CGFloat = Bool.random() ? 1 : -1
        let rotate = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2 * direction, duration: 20))
        body.run(rotate, withKey: "rotation")
        for crack in crackNodes {
            crack.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2 * direction, duration: 20)))
        }

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
        // No text on boss body — question shown in HUD panel only
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

    func receiveLaserSpark() {
        // Small spark particle burst at body position
        let spark = SKEmitterNode()
        spark.particleBirthRate = 200
        spark.numParticlesToEmit = 15
        spark.particleLifetime = 0.3
        spark.particleLifetimeRange = 0.1

        spark.particleSize = CGSize(width: 4, height: 4)
        spark.particleScaleSpeed = -2.0

        spark.particleSpeed = 60
        spark.particleSpeedRange = 30
        spark.emissionAngle = 0
        spark.emissionAngleRange = .pi * 2

        spark.particleColor = SKColor(white: 0.8, alpha: 1.0)
        spark.particleAlphaSpeed = -3.0
        spark.particleBlendMode = .add

        addChild(spark)

        spark.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.removeFromParent()
        ]))

        AudioManager.shared.playBossLaserBounce()
    }
}
