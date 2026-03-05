import SpriteKit

final class SectorSentinel: SKNode {
    private var body: SKShapeNode!
    private var glowCore: SKShapeNode!
    private var problemLabel: SKLabelNode!
    private var healthBar: SKShapeNode!
    private var grade: Grade = .kindergarten
    private var crackNodes: [SKShapeNode] = []
    private(set) var vertices: [CGPoint] = []
    var problem: MathProblem?

    private let bossRadius: CGFloat = 60

    func setup(grade: Grade, sceneSize: CGSize) {
        self.grade = grade
        removeAllChildren()
        crackNodes.removeAll()
        vertices.removeAll()

        // Irregular polygon asteroid (10-14 vertices)
        let vertexCount = Int.random(in: 10...14)
        let path = CGMutablePath()
        var pts: [CGPoint] = []

        for i in 0..<vertexCount {
            let angle = (CGFloat(i) / CGFloat(vertexCount)) * .pi * 2
            let radius = bossRadius * CGFloat.random(in: 0.7...1.0)
            let pt = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            pts.append(pt)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        vertices = pts

        body = SKShapeNode(path: path)
        body.fillColor = SKColor(white: 0.25, alpha: 1.0)
        body.strokeColor = SKColor(white: 0.5, alpha: 0.8)
        body.lineWidth = 3.0
        body.glowWidth = 4.0
        addChild(body)

        // Glowing core — red/orange threatening glow
        glowCore = SKShapeNode(circleOfRadius: 20)
        glowCore.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.4)
        glowCore.strokeColor = SKColor(red: 1.0, green: 0.2, blue: 0.0, alpha: 0.6)
        glowCore.lineWidth = 1.5
        glowCore.glowWidth = 3.0
        body.addChild(glowCore)

        // Core pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.8),
            SKAction.scale(to: 0.8, duration: 0.8)
        ])
        glowCore.run(SKAction.repeatForever(pulse))

        // Body glow cycles red
        let bodyPulse = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.body.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.9)
                self?.body.glowWidth = 8.0
            },
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in
                self?.body.strokeColor = SKColor(red: 0.8, green: 0.2, blue: 0.0, alpha: 0.6)
                self?.body.glowWidth = 4.0
            },
            SKAction.wait(forDuration: 0.6)
        ])
        body.run(SKAction.repeatForever(bodyPulse), withKey: "bossPulse")

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

        // Faster rotation (3s per revolution)
        let direction: CGFloat = Bool.random() ? 1 : -1
        let rotate = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2 * direction, duration: 3.0))
        body.run(rotate, withKey: "rotation")
        for crack in crackNodes {
            crack.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2 * direction, duration: 3.0)))
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

    func shatterIntoChunks(completion: @escaping () -> Void) {
        body.isHidden = true
        glowCore.isHidden = true
        for crack in crackNodes { crack.isHidden = true }

        let chunkCount = max(vertices.count, 10)
        let center = CGPoint.zero
        var chunksRemaining = chunkCount

        for i in 0..<chunkCount {
            let v1 = vertices[i % vertices.count]
            let v2 = vertices[(i + 1) % vertices.count]

            let chunkPath = CGMutablePath()
            chunkPath.move(to: center)
            chunkPath.addLine(to: v1)
            chunkPath.addLine(to: v2)
            chunkPath.closeSubpath()

            let chunk = SKShapeNode(path: chunkPath)
            chunk.fillColor = SKColor(red: 0.6, green: 0.2, blue: 0.0, alpha: 1.0)
            chunk.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 0.6)
            chunk.lineWidth = 0.8
            chunk.position = self.position
            chunk.zPosition = self.zPosition + 1

            parent?.addChild(chunk)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let speed = CGFloat.random(in: 150...300)
            let dx = cos(angle) * speed * 0.6
            let dy = sin(angle) * speed * 0.6

            let moveOut = SKAction.moveBy(x: dx, y: dy, duration: 0.6)
            let scaleDown = SKAction.scale(to: 0, duration: 0.6)
            let fadeOut = SKAction.fadeOut(withDuration: 0.6)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -4...4), duration: 0.6)

            let group = SKAction.group([moveOut, scaleDown, fadeOut, rotate])
            chunk.run(SKAction.sequence([group, SKAction.removeFromParent()])) {
                chunksRemaining -= 1
                if chunksRemaining <= 0 {
                    completion()
                }
            }
        }

        if chunkCount == 0 {
            completion()
        }

        // Remove self after chunks fly out
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.removeFromParent()
        ]))
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
