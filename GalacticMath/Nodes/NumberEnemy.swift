import SpriteKit

final class NumberEnemy: SKNode {
    let answerValue: Int
    let beamIndex: Int
    let isCorrect: Bool

    private var body: SKShapeNode!
    private var label: SKLabelNode!
    private var ageGroup: AgeGroup
    private var dustEmitter: SKEmitterNode?
    private var crackNodes: [SKShapeNode] = []
    private(set) var vertices: [CGPoint] = []
    private let baseRadius: CGFloat = 50

    init(answer: Int, beam: Int, isCorrect: Bool, ageGroup: AgeGroup, beamColor: SKColor) {
        self.answerValue = answer
        self.beamIndex = beam
        self.isCorrect = isCorrect
        self.ageGroup = ageGroup
        super.init()

        buildAsteroid()
        buildLabel(answer: answer)
        addCracks(count: Int.random(in: 2...3))
        startRotation()
        addDustTrail()

        if isCorrect {
            let shimmer = SKAction.sequence([
                SKAction.run { [weak self] in self?.body.glowWidth = 3.0 },
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in self?.body.glowWidth = 1.0 },
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

    // MARK: - Build

    private let horizontalStretch: CGFloat = 1.3
    private let verticalStretch: CGFloat = 0.85

    private func buildAsteroid() {
        let vertexCount = Int.random(in: 8...12)
        let path = CGMutablePath()
        var pts: [CGPoint] = []

        for i in 0..<vertexCount {
            let angle = (CGFloat(i) / CGFloat(vertexCount)) * .pi * 2
            let radius = baseRadius * CGFloat.random(in: 0.7...1.0)
            let pt = CGPoint(
                x: cos(angle) * radius * horizontalStretch,
                y: sin(angle) * radius * verticalStretch
            )
            pts.append(pt)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        vertices = pts

        body = SKShapeNode(path: path)
        body.fillColor = SKColor(white: 0.25, alpha: 1.0)
        body.strokeColor = SKColor(white: 0.5, alpha: 0.8)
        body.lineWidth = 1.5
        body.glowWidth = 1.0
        addChild(body)
    }

    private func buildLabel(answer: Int) {
        // Shadow label for legibility
        let shadow = SKLabelNode(text: "\(answer)")
        shadow.fontName = "AvenirNext-Heavy"
        shadow.fontSize = ageGroup == .cadet ? 32 : 30
        shadow.fontColor = SKColor(white: 0, alpha: 0.8)
        shadow.verticalAlignmentMode = .center
        shadow.horizontalAlignmentMode = .center
        shadow.position = CGPoint(x: 1.5, y: -1.5)
        shadow.zPosition = 0.9
        addChild(shadow)

        label = SKLabelNode(text: "\(answer)")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = ageGroup == .cadet ? 32 : 30
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        addChild(label)
    }

    private func addCracks(count: Int) {
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let length = baseRadius * CGFloat.random(in: 0.4...0.8)
            let crackPath = CGMutablePath()
            crackPath.move(to: .zero)
            crackPath.addLine(to: CGPoint(
                x: cos(angle) * length * horizontalStretch,
                y: sin(angle) * length * verticalStretch
            ))

            let crack = SKShapeNode(path: crackPath)
            crack.strokeColor = SKColor(white: 0.6, alpha: 0.4)
            crack.lineWidth = 0.8
            crack.zPosition = 0.5
            addChild(crack)
            crackNodes.append(crack)
        }
    }

    private func startRotation() {
        let duration = TimeInterval.random(in: 8...15)
        let direction: CGFloat = Bool.random() ? 1 : -1
        let rotate = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2 * direction, duration: duration))
        body.run(rotate, withKey: "rotation")
        for crack in crackNodes {
            crack.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2 * direction, duration: duration)))
        }
    }

    private func addDustTrail() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 15
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.2

        emitter.particleSize = CGSize(width: 4, height: 4)
        emitter.particleScaleSpeed = -0.5

        emitter.particleSpeed = 8
        emitter.particleSpeedRange = 4
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = 0.5

        emitter.particleColor = SKColor(white: 0.6, alpha: 1.0)
        emitter.particleAlpha = 0.3
        emitter.particleAlphaSpeed = -0.4

        emitter.particleBlendMode = .alpha

        addChild(emitter)
        dustEmitter = emitter
    }

    // MARK: - Actions

    func bounceBack() {
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 30, duration: 0.2),
            SKAction.moveBy(x: 0, y: -30, duration: 0.3)
        ])
        run(bounce)
    }

    func showDamage() {
        // Add extra cracks
        addCracks(count: 2)

        // Red tint overlay
        let overlay = SKShapeNode(path: body.path!)
        overlay.fillColor = SKColor.red.withAlphaComponent(0.3)
        overlay.strokeColor = .clear
        overlay.zPosition = 0.8
        addChild(overlay)

        overlay.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))

        // Wobble
        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.15, duration: 0.08),
            SKAction.rotate(byAngle: -0.30, duration: 0.08),
            SKAction.rotate(byAngle: 0.30, duration: 0.08),
            SKAction.rotate(byAngle: -0.30, duration: 0.08),
            SKAction.rotate(byAngle: 0.30, duration: 0.08),
            SKAction.rotate(byAngle: -0.15, duration: 0.08)
        ])
        run(wobble)
    }

    func shatterIntoChunks(completion: @escaping () -> Void) {
        removeAction(forKey: "float")
        dustEmitter?.removeFromParent()
        dustEmitter = nil

        body.isHidden = true
        label.isHidden = true
        for crack in crackNodes { crack.isHidden = true }

        let chunkCount = min(vertices.count, Int.random(in: 3...5))
        let center = CGPoint.zero
        var chunksRemaining = chunkCount

        for i in 0..<chunkCount {
            let v1 = vertices[i]
            let v2 = vertices[(i + 1) % vertices.count]

            let chunkPath = CGMutablePath()
            chunkPath.move(to: center)
            chunkPath.addLine(to: v1)
            chunkPath.addLine(to: v2)
            chunkPath.closeSubpath()

            let chunk = SKShapeNode(path: chunkPath)
            chunk.fillColor = SKColor(white: 0.25, alpha: 1.0)
            chunk.strokeColor = SKColor(white: 0.5, alpha: 0.6)
            chunk.lineWidth = 0.8
            chunk.position = self.position
            chunk.zPosition = self.zPosition + 1

            parent?.addChild(chunk)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let speed = CGFloat.random(in: 100...200)
            let dx = cos(angle) * speed * 0.5
            let dy = sin(angle) * speed * 0.5

            let moveOut = SKAction.moveBy(x: dx, y: dy, duration: 0.5)
            let scaleDown = SKAction.scale(to: 0, duration: 0.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: 0.5)

            let group = SKAction.group([moveOut, scaleDown, fadeOut, rotate])
            chunk.run(SKAction.sequence([group, SKAction.removeFromParent()])) {
                chunksRemaining -= 1
                if chunksRemaining <= 0 {
                    completion()
                }
            }
        }

        // Safety: if no chunks created, call completion immediately
        if chunkCount == 0 {
            completion()
        }
    }
}
