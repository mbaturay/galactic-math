import SpriteKit

final class MotherMeteorNode: SKNode {

    // MARK: - Child nodes

    private var body: SKShapeNode!
    private var labelContainer: SKNode!  // counter-rotated so text stays upright
    private var topicLabel: SKLabelNode!
    private var expressionLabel: SKLabelNode!
    private var promptLabel: SKLabelNode!
    private var compactLabel: SKLabelNode!
    private var timerBar: SKShapeNode!
    private var timerBarBg: SKShapeNode!
    private var dimOverlay: SKShapeNode!

    // MARK: - Geometry state

    private var sceneSize: CGSize = .zero
    private var difficulty: ReadingDifficulty = .normal
    private var onEnemiesReady: (([NumberEnemy]) -> Void)?
    private var onComplete: (() -> Void)?

    private var motherRadius: CGFloat = 120
    private var motherCenter: CGPoint = .zero
    private var motherVertices: [CGPoint] = []

    // HUD target
    private var targetPosition: CGPoint = .zero
    private var targetSize: CGSize = .zero

    // Enemy data
    private var grade: Grade = .kindergarten
    private var problem: MathProblem!
    private var beamGrid: BeamGrid!
    private var enemyStartY: CGFloat = 0

    // MARK: - Present

    func present(
        problem: MathProblem,
        grade: Grade,
        beamGrid: BeamGrid,
        enemyStartY: CGFloat,
        sceneSize: CGSize,
        difficulty: ReadingDifficulty,
        hudPanelPosition: CGPoint,
        hudPanelSize: CGSize,
        onEnemiesReady: @escaping ([NumberEnemy]) -> Void,
        completion: @escaping () -> Void
    ) {
        self.problem = problem
        self.grade = grade
        self.beamGrid = beamGrid
        self.enemyStartY = enemyStartY
        self.sceneSize = sceneSize
        self.difficulty = difficulty
        self.targetPosition = hudPanelPosition
        self.targetSize = hudPanelSize
        self.onEnemiesReady = onEnemiesReady
        self.onComplete = completion
        self.zPosition = 500

        motherRadius = min(sceneSize.width * 0.28, 140)
        motherCenter = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 + 20)

        buildMotherShape()
        buildLabelContainer()
        buildTimerBar()
        buildDimOverlay()

        // Phase 1: Entrance (no rotation)
        animateEntrance()
    }

    // MARK: - Build Mother Shape

    private func buildMotherShape() {
        let vertexCount = 12
        let path = CGMutablePath()
        var pts: [CGPoint] = []

        for i in 0..<vertexCount {
            let angle = (CGFloat(i) / CGFloat(vertexCount)) * .pi * 2
            let r = motherRadius * CGFloat.random(in: 0.8...1.0)
            let pt = CGPoint(
                x: cos(angle) * r * 1.2,
                y: sin(angle) * r * 0.9
            )
            pts.append(pt)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        motherVertices = pts

        body = SKShapeNode(path: path)
        body.fillColor = SKColor(white: 0.22, alpha: 1.0)
        body.strokeColor = SKColor(white: 0.5, alpha: 0.8)
        body.lineWidth = 2.0
        body.glowWidth = 2.0
        body.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height + motherRadius + 20)
        body.zPosition = 1
        addChild(body)

        // Static cracks for rocky look
        for _ in 0..<3 {
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let length = motherRadius * CGFloat.random(in: 0.4...0.7)
            let cp = CGMutablePath()
            cp.move(to: .zero)
            cp.addLine(to: CGPoint(
                x: cos(angle) * length * 1.2,
                y: sin(angle) * length * 0.9
            ))
            let crack = SKShapeNode(path: cp)
            crack.strokeColor = SKColor(white: 0.6, alpha: 0.3)
            crack.lineWidth = 0.8
            crack.zPosition = 0.5
            body.addChild(crack)
        }
    }

    // MARK: - Label Container (counter-rotated for upright text)

    private func buildLabelContainer() {
        let coreExpr = problem.coreExpression
        let topicName = problem.topic.displayName
        let narrative = problem.topic.narrativePrompt

        // Container sits at body center, will be counter-rotated
        labelContainer = SKNode()
        labelContainer.zPosition = 2
        body.addChild(labelContainer)

        // Topic label (small, gold, near top)
        topicLabel = SKLabelNode(text: topicName.uppercased())
        topicLabel.fontName = "AvenirNext-Medium"
        topicLabel.fontSize = 13
        topicLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.8)
        topicLabel.verticalAlignmentMode = .center
        topicLabel.horizontalAlignmentMode = .center
        topicLabel.position = CGPoint(x: 0, y: motherRadius * 0.45)
        labelContainer.addChild(topicLabel)

        // Core expression (large, white, center — always single line)
        expressionLabel = SKLabelNode(text: coreExpr)
        expressionLabel.fontName = "AvenirNext-Heavy"
        expressionLabel.fontColor = .white
        expressionLabel.numberOfLines = 1
        expressionLabel.lineBreakMode = .byClipping
        expressionLabel.verticalAlignmentMode = .center
        expressionLabel.horizontalAlignmentMode = .center
        expressionLabel.position = CGPoint(x: 0, y: 5)

        // Auto-size font to fit within meteor width
        let maxLabelWidth = motherRadius * 2 - 40
        var fontSize: CGFloat = 42
        expressionLabel.fontSize = fontSize
        while expressionLabel.frame.width > maxLabelWidth && fontSize > 24 {
            fontSize -= 2
            expressionLabel.fontSize = fontSize
        }

        labelContainer.addChild(expressionLabel)

        // Narrative prompt (medium, grey, below)
        promptLabel = SKLabelNode(text: narrative)
        promptLabel.fontName = "AvenirNext-DemiBold"
        promptLabel.fontSize = narrative.count > 35 ? 13 : 16
        promptLabel.fontColor = SKColor(white: 0.75, alpha: 0.9)
        promptLabel.numberOfLines = 0
        promptLabel.preferredMaxLayoutWidth = motherRadius * 2 - 50
        promptLabel.verticalAlignmentMode = .center
        promptLabel.horizontalAlignmentMode = .center
        promptLabel.position = CGPoint(x: 0, y: -motherRadius * 0.35)
        labelContainer.addChild(promptLabel)

        // Compact label (for HUD panel — starts invisible)
        compactLabel = SKLabelNode(text: coreExpr)
        compactLabel.fontName = "AvenirNext-Heavy"
        compactLabel.fontSize = 22
        compactLabel.fontColor = .white
        compactLabel.verticalAlignmentMode = .center
        compactLabel.horizontalAlignmentMode = .center
        compactLabel.position = .zero
        compactLabel.alpha = 0
        labelContainer.addChild(compactLabel)
    }

    // MARK: - Timer Bar

    private func buildTimerBar() {
        let barW = motherRadius * 1.6
        let barH: CGFloat = 6

        timerBarBg = SKShapeNode(rectOf: CGSize(width: barW, height: barH), cornerRadius: 3)
        timerBarBg.fillColor = SKColor(white: 0.2, alpha: 0.6)
        timerBarBg.strokeColor = .clear
        timerBarBg.position = CGPoint(x: 0, y: -motherRadius * 0.6)
        timerBarBg.zPosition = 2
        labelContainer.addChild(timerBarBg)

        timerBar = SKShapeNode(rectOf: CGSize(width: barW, height: barH), cornerRadius: 3)
        timerBar.fillColor = difficulty.color
        timerBar.strokeColor = .clear
        timerBar.position = CGPoint(x: 0, y: -motherRadius * 0.6)
        timerBar.zPosition = 3
        labelContainer.addChild(timerBar)
    }

    // MARK: - Dim Overlay

    private func buildDimOverlay() {
        dimOverlay = SKShapeNode(rectOf: sceneSize)
        dimOverlay.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        dimOverlay.fillColor = SKColor(white: 0.0, alpha: 0.6)
        dimOverlay.strokeColor = .clear
        dimOverlay.zPosition = 0
        dimOverlay.alpha = 0
        addChild(dimOverlay)
    }

    // MARK: - Phase 1: Entrance (NO rotation — completely stable)

    private func animateEntrance() {
        let entranceDuration: TimeInterval = 1.0

        // Dim overlay fades in
        dimOverlay.run(SKAction.fadeAlpha(to: 1.0, duration: 0.4))

        // Descend from top to center — NO rotation
        let descend = SKAction.move(to: motherCenter, duration: entranceDuration)
        descend.timingMode = .easeOut

        body.setScale(0.4)
        let scaleUp = SKAction.scale(to: 1.0, duration: entranceDuration)
        scaleUp.timingMode = .easeOut

        body.run(SKAction.group([descend, scaleUp])) { [weak self] in
            self?.startCountdown()
        }
    }

    // MARK: - Countdown (reading time — NO rotation, stable)

    private func startCountdown() {
        // Gentle settle wobble
        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.03, duration: 0.08),
            SKAction.rotate(byAngle: -0.06, duration: 0.08),
            SKAction.rotate(byAngle: 0.03, duration: 0.08)
        ])
        body.run(wobble)

        // Timer bar depletion
        let deplete = SKAction.scaleX(to: 0.001, duration: difficulty.readTime)
        deplete.timingMode = .linear
        timerBar.run(deplete)

        // After read time → Phase 2: travel to HUD
        run(SKAction.sequence([
            SKAction.wait(forDuration: difficulty.readTime),
            SKAction.run { [weak self] in self?.morphToHUD() }
        ]))
    }

    // MARK: - Phase 2: Morph & Travel to HUD Panel (with spin)

    private func morphToHUD() {
        let duration: TimeInterval = 0.5

        let sPos = body.position
        let sR = motherRadius
        let sVertices = motherVertices

        let eW = targetSize.width
        let eH = targetSize.height
        let eCorner: CGFloat = 12
        let ePos = CGPoint(x: targetPosition.x,
                           y: targetPosition.y - targetSize.height / 2)

        let bodyRef = body!
        let lblContainer = labelContainer!
        let cmpLabel = compactLabel!
        let dimBg = dimOverlay!
        let topLbl = topicLabel!
        let promptLbl = promptLabel!
        let exprLbl = expressionLabel!
        let tmBar = timerBar!
        let tmBarBg = timerBarBg!

        // Fade out reading labels, fade in compact
        cmpLabel.alpha = 0

        let morphFlight = SKAction.customAction(withDuration: duration) {
            node, elapsed in
            guard let box = node as? SKShapeNode else { return }

            let rawT = CGFloat(elapsed / duration)
            let t = rawT * rawT * (3.0 - 2.0 * rawT)  // smoothstep

            // Position
            box.position = CGPoint(
                x: sPos.x + (ePos.x - sPos.x) * t,
                y: sPos.y + (ePos.y - sPos.y) * t
            )

            // Morph path
            let w = sR * 2.4 + (eW - sR * 2.4) * t
            let h = sR * 1.8 + (eH - sR * 1.8) * t
            let corner = eCorner * t

            if t < 0.5 {
                let morphPath = CGMutablePath()
                let rectLeft = -w / 2
                let rectRight = w / 2
                let rectTop = h / 2
                let rectBottom = -h / 2

                for (i, sv) in sVertices.enumerated() {
                    let pct = CGFloat(i) / CGFloat(sVertices.count)
                    let targetPt: CGPoint
                    if pct < 0.25 {
                        let f = pct / 0.25
                        targetPt = CGPoint(x: rectRight, y: rectBottom + f * h)
                    } else if pct < 0.5 {
                        let f = (pct - 0.25) / 0.25
                        targetPt = CGPoint(x: rectRight - f * w, y: rectTop)
                    } else if pct < 0.75 {
                        let f = (pct - 0.5) / 0.25
                        targetPt = CGPoint(x: rectLeft, y: rectTop - f * h)
                    } else {
                        let f = (pct - 0.75) / 0.25
                        targetPt = CGPoint(x: rectLeft + f * w, y: rectBottom)
                    }

                    let localT = t * 2
                    let pt = CGPoint(
                        x: sv.x + (targetPt.x - sv.x) * localT,
                        y: sv.y + (targetPt.y - sv.y) * localT
                    )
                    if i == 0 { morphPath.move(to: pt) } else { morphPath.addLine(to: pt) }
                }
                morphPath.closeSubpath()
                box.path = morphPath
            } else {
                let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
                box.path = CGPath(roundedRect: rect,
                                  cornerWidth: corner, cornerHeight: corner,
                                  transform: nil)
            }

            // One full spin during travel
            box.zRotation = rawT * CGFloat.pi * 2

            // Counter-rotate labels so text stays upright
            lblContainer.zRotation = -box.zRotation

            // Cross-fade labels
            let fadeT = min(rawT / 0.4, 1.0)
            topLbl.alpha = max(1.0 - fadeT * 2.5, 0)
            promptLbl.alpha = max(1.0 - fadeT * 2.5, 0)
            exprLbl.alpha = max(1.0 - fadeT * 2.5, 0)
            tmBar.alpha = max(1.0 - fadeT * 3.0, 0)
            tmBarBg.alpha = max(1.0 - fadeT * 3.0, 0)

            let compactFadeT = max((rawT - 0.3) / 0.4, 0)
            cmpLabel.alpha = min(compactFadeT, 1.0)
            cmpLabel.position = .zero

            // Dim overlay fades out
            dimBg.alpha = max(1.0 - rawT * 2.0, 0)

            // Color transition: rocky grey → panel purple
            let r = 0.22 + (0.15 - 0.22) * t
            let g = 0.22 + (0.05 - 0.22) * t
            let b = 0.22 + (0.30 - 0.22) * t
            box.fillColor = SKColor(red: r, green: g, blue: b, alpha: 0.95)
            box.strokeColor = SKColor(
                red: 0.5 + 0.5 * t,
                green: 0.5 + 0.35 * t,
                blue: 0.5 * (1 - t),
                alpha: 0.8 + 0.1 * t
            )
        }

        // Bounce at arrival
        let bounceUp = SKAction.customAction(withDuration: 0.07) {
            node, elapsed in
            guard let box = node as? SKShapeNode else { return }
            let bt = CGFloat(elapsed / 0.07)
            let scale = 1.0 + 0.06 * bt
            box.xScale = scale
            box.yScale = scale
            cmpLabel.position = .zero
        }
        let bounceDown = SKAction.customAction(withDuration: 0.07) {
            node, elapsed in
            guard let box = node as? SKShapeNode else { return }
            let bt = CGFloat(elapsed / 0.07)
            let scale = 1.06 - 0.06 * bt
            box.xScale = scale
            box.yScale = scale
            cmpLabel.position = .zero
        }

        let settle = SKAction.run { [weak self] in
            guard let self = self else { return }
            bodyRef.zRotation = 0
            bodyRef.xScale = 1.0
            bodyRef.yScale = 1.0
            lblContainer.zRotation = 0
            cmpLabel.position = .zero
            cmpLabel.verticalAlignmentMode = .center
            cmpLabel.horizontalAlignmentMode = .center

            // Final path: exact panel rect
            let finalRect = CGRect(x: -eW / 2, y: -eH / 2, width: eW, height: eH)
            bodyRef.path = CGPath(roundedRect: finalRect,
                                  cornerWidth: eCorner, cornerHeight: eCorner,
                                  transform: nil)
            bodyRef.fillColor = SKColor(red: 0.15, green: 0.05, blue: 0.3, alpha: 0.85)
            bodyRef.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.8)
            bodyRef.lineWidth = 2.0
            bodyRef.glowWidth = 2.0

            // Phase 3: Explosion from HUD position
            self.explodeFromHUD()
        }

        body.run(SKAction.sequence([morphFlight, bounceUp, bounceDown, settle]))
    }

    // MARK: - Phase 3: Explosion from HUD Panel Position

    private func explodeFromHUD() {
        let explosionPos = body.position

        // Shockwave ring from HUD position
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.8)
        ring.lineWidth = 3.0
        ring.glowWidth = 5.0
        ring.fillColor = .clear
        ring.position = explosionPos
        ring.zPosition = 10
        addChild(ring)

        let expandRing = SKAction.group([
            SKAction.scale(to: 25, duration: 0.5),
            SKAction.fadeOut(withDuration: 0.5)
        ])
        ring.run(SKAction.sequence([expandRing, SKAction.removeFromParent()]))

        // Screen shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -6, y: 3, duration: 0.04),
            SKAction.moveBy(x: 12, y: -6, duration: 0.04),
            SKAction.moveBy(x: -12, y: 6, duration: 0.04),
            SKAction.moveBy(x: 6, y: -3, duration: 0.04)
        ])
        scene?.run(SKAction.repeat(shake, count: 3))

        // Debris from HUD position
        spawnDebris(at: explosionPos, count: 12)

        // Flash the panel briefly
        let originalFill = body.fillColor
        body.fillColor = SKColor(white: 0.9, alpha: 1.0)
        body.glowWidth = 8.0

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in
                self?.body.fillColor = originalFill
                self?.body.glowWidth = 2.0
            }
        ]))

        // Phase 4: Birth enemies from HUD position after short delay
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in self?.birthEnemiesFromHUD() }
        ]))
    }

    // MARK: - Phase 4: Birth Answer Meteors from HUD Position

    private func birthEnemiesFromHUD() {
        let spawnPos = body.position  // HUD panel position

        let beamCount = grade.beamCount
        let answers = problem.answers(for: beamCount)
        let colors = grade.beamColors
        var enemies: [NumberEnemy] = []

        for i in 0..<beamCount {
            let isCorrect = answers[i] == problem.correctAnswer
            let color = colors[i % colors.count]
            let enemy = NumberEnemy(
                answer: answers[i], beam: i,
                isCorrect: isCorrect, grade: grade, beamColor: color
            )

            // Start at HUD panel position
            enemy.position = spawnPos
            enemy.setScale(0.2)
            enemy.alpha = 0
            enemy.zPosition = 30
            scene?.addChild(enemy)
            enemies.append(enemy)

            // Target: beam lane at enemyStartY
            let targetX = beamGrid.beamXAtY(i, y: enemyStartY)
            let targetPos = CGPoint(x: targetX, y: enemyStartY)

            // Staggered fan-out
            let delay = TimeInterval(i) * 0.08
            let fanDuration: TimeInterval = 0.5

            let moveToLane = SKAction.move(to: targetPos, duration: fanDuration)
            moveToLane.timingMode = .easeOut

            let scaleToNormal = SKAction.scale(to: 0.5, duration: fanDuration)
            scaleToNormal.timingMode = .easeOut

            let fadeIn = SKAction.fadeIn(withDuration: 0.15)

            enemy.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([fadeIn, moveToLane, scaleToNormal])
            ]))
        }

        // Notify scene about the created enemies
        onEnemiesReady?(enemies)

        // After enemies fan out, finish
        let totalFanTime = TimeInterval(beamCount) * 0.08 + 0.5
        run(SKAction.sequence([
            SKAction.wait(forDuration: totalFanTime + 0.1),
            SKAction.run { [weak self] in self?.finishReveal() }
        ]))
    }

    // MARK: - Debris

    private func spawnDebris(at position: CGPoint, count: Int) {
        for _ in 0..<count {
            let size = CGFloat.random(in: 3...8)
            let debris = SKShapeNode(rectOf: CGSize(width: size, height: size))
            debris.fillColor = SKColor(white: CGFloat.random(in: 0.3...0.6), alpha: 1.0)
            debris.strokeColor = .clear
            debris.position = position
            debris.zPosition = 8
            addChild(debris)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let speed = CGFloat.random(in: 80...200)
            let dx = cos(angle) * speed * 0.4
            let dy = sin(angle) * speed * 0.4

            debris.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.6),
                    SKAction.fadeOut(withDuration: 0.6),
                    SKAction.scale(to: 0, duration: 0.6),
                    SKAction.rotate(byAngle: CGFloat.random(in: -4...4), duration: 0.6)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Finish

    private func finishReveal() {
        removeAllChildren()
        removeFromParent()
        onComplete?()
    }
}
