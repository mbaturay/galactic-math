import SpriteKit

// MARK: - Reading Difficulty

enum ReadingDifficulty: Int, CaseIterable {
    case easy = 0
    case normal = 1
    case hard = 2

    var readTime: TimeInterval {
        switch self {
        case .easy:   return 8.0
        case .normal: return 5.0
        case .hard:   return 3.0
        }
    }

    var label: String {
        switch self {
        case .easy:   return "EASY"
        case .normal: return "NORMAL"
        case .hard:   return "HARD"
        }
    }

    var color: SKColor {
        switch self {
        case .easy:   return SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        case .normal: return SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        case .hard:   return SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        }
    }

    static var current: ReadingDifficulty = .normal
}

// MARK: - QuestionRevealNode

final class QuestionRevealNode: SKNode {

    // All child nodes — created once at setup, never replaced
    private var dimOverlay: SKShapeNode!
    private var modalBox: SKShapeNode!
    private var topicLabel: SKLabelNode!
    private var expressionLabel: SKLabelNode!
    private var promptLabel: SKLabelNode!
    private var compactLabel: SKLabelNode!
    private var timerBar: SKShapeNode!
    private var timerBarBg: SKShapeNode!

    private var sceneSize: CGSize = .zero
    private var difficulty: ReadingDifficulty = .normal
    private var onComplete: (() -> Void)?

    private var targetPosition: CGPoint = .zero
    private var targetSize: CGSize = .zero

    // Modal geometry (stored for the flight interpolation)
    private var modalStartW: CGFloat = 0
    private var modalStartH: CGFloat = 200
    private var modalStartPos: CGPoint = .zero

    func present(
        fullQuestion: String,
        coreExpression: String,
        topicName: String,
        narrativePrompt: String,
        sceneSize: CGSize,
        difficulty: ReadingDifficulty,
        hudPanelPosition: CGPoint,
        hudPanelSize: CGSize,
        completion: @escaping () -> Void
    ) {
        self.sceneSize = sceneSize
        self.difficulty = difficulty
        self.targetPosition = hudPanelPosition
        self.targetSize = hudPanelSize
        self.onComplete = completion
        self.zPosition = 500

        modalStartW = min(sceneSize.width * 0.85, 460.0)
        modalStartH = 200
        modalStartPos = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2 + 20)

        // --- Dim overlay ---
        dimOverlay = SKShapeNode(rectOf: sceneSize)
        dimOverlay.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        dimOverlay.fillColor = SKColor(white: 0.0, alpha: 0.7)
        dimOverlay.strokeColor = .clear
        dimOverlay.zPosition = 0
        addChild(dimOverlay)

        // --- Modal box (center-anchored rect) ---
        let rect = CGRect(x: -modalStartW / 2, y: -modalStartH / 2,
                          width: modalStartW, height: modalStartH)
        modalBox = SKShapeNode(rect: rect, cornerRadius: 18)
        modalBox.fillColor = SKColor(red: 0.12, green: 0.04, blue: 0.28, alpha: 0.95)
        modalBox.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.9)
        modalBox.lineWidth = 2.5
        modalBox.glowWidth = 3.0
        modalBox.position = modalStartPos
        modalBox.zPosition = 1
        addChild(modalBox)

        // --- Line 1: Topic (small, gold) ---
        topicLabel = SKLabelNode(text: topicName.uppercased())
        topicLabel.fontName = "AvenirNext-Medium"
        topicLabel.fontSize = 14
        topicLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.8)
        topicLabel.verticalAlignmentMode = .center
        topicLabel.horizontalAlignmentMode = .center
        topicLabel.position = CGPoint(x: 0, y: 60)
        topicLabel.zPosition = 2
        modalBox.addChild(topicLabel)

        // --- Line 2: Core expression (large, white) ---
        let exprSize: CGFloat = coreExpression.count > 30 ? 28
            : (coreExpression.count > 18 ? 34 : 42)
        expressionLabel = SKLabelNode(text: coreExpression)
        expressionLabel.fontName = "AvenirNext-Heavy"
        expressionLabel.fontSize = exprSize
        expressionLabel.fontColor = .white
        expressionLabel.numberOfLines = 0
        expressionLabel.preferredMaxLayoutWidth = modalStartW - 40
        expressionLabel.verticalAlignmentMode = .center
        expressionLabel.horizontalAlignmentMode = .center
        expressionLabel.position = CGPoint(x: 0, y: 10)
        expressionLabel.zPosition = 2
        modalBox.addChild(expressionLabel)

        // --- Line 3: Narrative prompt (medium, grey) ---
        promptLabel = SKLabelNode(text: narrativePrompt)
        promptLabel.fontName = "AvenirNext-DemiBold"
        promptLabel.fontSize = narrativePrompt.count > 35 ? 15 : 18
        promptLabel.fontColor = SKColor(white: 0.75, alpha: 0.9)
        promptLabel.numberOfLines = 0
        promptLabel.preferredMaxLayoutWidth = modalStartW - 50
        promptLabel.verticalAlignmentMode = .center
        promptLabel.horizontalAlignmentMode = .center
        promptLabel.position = CGPoint(x: 0, y: -40)
        promptLabel.zPosition = 2
        modalBox.addChild(promptLabel)

        // --- Compact label (pre-built at center, starts invisible) ---
        compactLabel = SKLabelNode(text: coreExpression)
        compactLabel.fontName = "AvenirNext-Heavy"
        compactLabel.fontSize = 22
        compactLabel.fontColor = .white
        compactLabel.verticalAlignmentMode = .center
        compactLabel.horizontalAlignmentMode = .center
        compactLabel.position = CGPoint(x: 0, y: 0)
        compactLabel.zPosition = 2
        compactLabel.alpha = 0
        modalBox.addChild(compactLabel)

        // --- Timer bar ---
        let barW = modalStartW - 40
        let barH: CGFloat = 8

        timerBarBg = SKShapeNode(rectOf: CGSize(width: barW, height: barH), cornerRadius: 4)
        timerBarBg.fillColor = SKColor(white: 0.2, alpha: 0.6)
        timerBarBg.strokeColor = .clear
        timerBarBg.position = CGPoint(x: 0, y: -78)
        timerBarBg.zPosition = 2
        modalBox.addChild(timerBarBg)

        timerBar = SKShapeNode(rectOf: CGSize(width: barW, height: barH), cornerRadius: 4)
        timerBar.fillColor = difficulty.color
        timerBar.strokeColor = .clear
        timerBar.position = CGPoint(x: 0, y: -78)
        timerBar.zPosition = 3
        modalBox.addChild(timerBar)

        // --- Entrance animation ---
        modalBox.setScale(0.3)
        modalBox.alpha = 0
        let appear = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.35),
            SKAction.fadeIn(withDuration: 0.25)
        ])
        appear.timingMode = .easeOut
        modalBox.run(appear)

        // --- Countdown timer depletion ---
        let deplete = SKAction.scaleX(to: 0.001, duration: difficulty.readTime)
        deplete.timingMode = .linear
        timerBar.run(deplete)

        run(SKAction.sequence([
            SKAction.wait(forDuration: difficulty.readTime),
            SKAction.run { [weak self] in self?.animateToHUD() }
        ]))
    }

    // MARK: - Flight Animation
    //
    // Uses SKAction.customAction to morph the SKShapeNode path every frame.
    // No node swaps, no scale transforms, no discrete layout changes mid-flight.

    private func animateToHUD() {
        let duration: TimeInterval = 0.45

        // Start geometry (center-anchored)
        let sW = modalStartW
        let sH = modalStartH
        let sCorner: CGFloat = 18
        let sPos = modalBox.position

        // End geometry (center-anchored, matching compact panel visual)
        let eW = targetSize.width
        let eH = targetSize.height
        let eCorner: CGFloat = 12
        // targetPosition is the top-anchor of ProblemDisplayNode;
        // offset Y by half panel height so our center-anchored box aligns visually
        let ePos = CGPoint(x: targetPosition.x,
                           y: targetPosition.y - targetSize.height / 2)

        // Capture label refs for the closure
        let exprLabel = expressionLabel!
        let topLabel = topicLabel!
        let narLabel = promptLabel!
        let cmpLabel = compactLabel!
        let tmBar = timerBar!
        let tmBarBg = timerBarBg!
        let dimBg = dimOverlay!

        // Expression label start Y (relative to box center)
        let exprStartY: CGFloat = 10

        // --- Single custom action: morphs path, position, rotation, labels every frame ---
        let morphFlight = SKAction.customAction(withDuration: duration) {
            node, elapsed in
            guard let box = node as? SKShapeNode else { return }

            let rawT = CGFloat(elapsed / duration)
            // Smoothstep (easeInEaseOut)
            let t = rawT * rawT * (3.0 - 2.0 * rawT)

            // --- Interpolate position ---
            box.position = CGPoint(
                x: sPos.x + (ePos.x - sPos.x) * t,
                y: sPos.y + (ePos.y - sPos.y) * t
            )

            // --- Interpolate path (morph the actual shape, no scale transform) ---
            let w = sW + (eW - sW) * t
            let h = sH + (eH - sH) * t
            let corner = sCorner + (eCorner - sCorner) * t
            let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
            box.path = CGPath(roundedRect: rect,
                              cornerWidth: corner, cornerHeight: corner,
                              transform: nil)

            // --- Rotation: one full spin ---
            box.zRotation = rawT * CGFloat.pi * 2

            // --- Cross-fade labels (over first ~0.2s of flight) ---
            let fadeT = min(rawT / 0.44, 1.0)  // 0→1 over ~0.2s of the 0.45s duration

            topLabel.alpha = max(1.0 - fadeT * 2.5, 0)    // fades out 0→0.4 of fadeT
            narLabel.alpha = max(1.0 - fadeT * 2.5, 0)
            exprLabel.alpha = max(1.0 - fadeT * 2.5, 0)
            tmBar.alpha = max(1.0 - fadeT * 3.0, 0)
            tmBarBg.alpha = max(1.0 - fadeT * 3.0, 0)

            // Compact label fades in (slightly delayed, over 0.15–0.45 of flight)
            let compactFadeT = max((rawT - 0.15) / 0.30, 0)
            cmpLabel.alpha = min(compactFadeT, 1.0)

            // --- Reposition expression label toward center as box shrinks ---
            exprLabel.position.y = exprStartY * (1.0 - t)

            // --- Keep compact label pinned to vertical center of the morphing rect ---
            cmpLabel.position = CGPoint(x: 0, y: 0)

            // --- Dim overlay fades out ---
            dimBg.alpha = max(1.0 - fadeT * 1.5, 0)
        }

        // --- Bounce at arrival ---
        let bounceUp = SKAction.customAction(withDuration: 0.07) {
            node, elapsed in
            guard let box = node as? SKShapeNode else { return }
            let bt = CGFloat(elapsed / 0.07)
            let scale = 1.0 + 0.06 * bt
            box.xScale = scale
            box.yScale = scale
            // Keep compact label centered during bounce
            cmpLabel.position = CGPoint(x: 0, y: 0)
        }
        let bounceDown = SKAction.customAction(withDuration: 0.07) {
            node, elapsed in
            guard let box = node as? SKShapeNode else { return }
            let bt = CGFloat(elapsed / 0.07)
            let scale = 1.06 - 0.06 * bt
            box.xScale = scale
            box.yScale = scale
            // Keep compact label centered during bounce
            cmpLabel.position = CGPoint(x: 0, y: 0)
        }

        let finish = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.modalBox.zRotation = 0
            self.modalBox.xScale = 1.0
            self.modalBox.yScale = 1.0
            // Final enforcement: compact label centered in the settled panel
            self.compactLabel.position = CGPoint(x: 0, y: 0)
            self.compactLabel.verticalAlignmentMode = .center
            self.compactLabel.horizontalAlignmentMode = .center
            self.finishReveal()
        }

        modalBox.run(SKAction.sequence([morphFlight, bounceUp, bounceDown, finish]))
    }

    private func finishReveal() {
        removeAllChildren()
        removeFromParent()
        onComplete?()
    }
}
