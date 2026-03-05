import SpriteKit

final class BeamGrid: SKNode {
    private var baseBeamLines: [SKShapeNode] = []   // Grey, always visible
    private var colorBeamLines: [SKShapeNode] = []  // Colored overlay, animated
    private var gridLineNodes: [SKShapeNode] = []
    private var beamCount: Int = 5
    private var sceneSize: CGSize = .zero
    private var grade: Grade = .kindergarten
    private var activeBeamIndex: Int = -1

    // Grid line animation
    private let gridLineCount = 14
    private var gridPhases: [CGFloat] = []

    var beamPositions: [CGFloat] = []

    /// Per-beam vanishing points spread across the vanishing zone
    private var vanishingPoints: [CGPoint] = []

    /// Width of the vanishing zone at the top (beams spread across this)
    private var vanishingZoneWidth: CGFloat = 0

    /// Center of the vanishing zone — used by GameScene for enemyStartY
    var vanishingPoint: CGPoint {
        return CGPoint(x: sceneSize.width / 2, y: sceneSize.height * 0.85)
    }

    func setup(size: CGSize, grade: Grade) {
        self.sceneSize = size
        self.grade = grade
        self.beamCount = grade.beamCount

        // 3 beams (K, G1): 12% width — 5 beams (G2+): 18% width
        vanishingZoneWidth = size.width * (beamCount <= 3 ? 0.12 : 0.18)

        calculateBeamPositions()
        calculateVanishingPoints()
        drawBeams()
        drawGridLines()
    }

    private func calculateBeamPositions() {
        beamPositions.removeAll()
        let margin: CGFloat = sceneSize.width * 0.05
        let availableWidth = sceneSize.width - margin * 2
        let spacing = availableWidth / CGFloat(beamCount - 1)

        for i in 0..<beamCount {
            beamPositions.append(margin + spacing * CGFloat(i))
        }
    }

    private func calculateVanishingPoints() {
        vanishingPoints.removeAll()
        let midX = sceneSize.width / 2
        let topY = vanishingPoint.y

        if beamCount == 1 {
            vanishingPoints.append(CGPoint(x: midX, y: topY))
            return
        }

        // Spread vanishing points evenly across the zone
        let zoneLeft = midX - vanishingZoneWidth / 2
        let zoneSpacing = vanishingZoneWidth / CGFloat(beamCount - 1)

        for i in 0..<beamCount {
            let x = zoneLeft + zoneSpacing * CGFloat(i)
            vanishingPoints.append(CGPoint(x: x, y: topY))
        }
    }

    // MARK: - Vertical Beams

    private func drawBeams() {
        for line in baseBeamLines { line.removeFromParent() }
        for line in colorBeamLines { line.removeFromParent() }
        baseBeamLines.removeAll()
        colorBeamLines.removeAll()

        let colors = grade.beamColors

        for i in 0..<beamCount {
            let vp = vanishingPoints[i]

            let path = CGMutablePath()
            path.move(to: CGPoint(x: beamPositions[i], y: 0))
            path.addLine(to: vp)

            // Base layer: light grey, always visible
            let base = SKShapeNode(path: path)
            base.strokeColor = SKColor(white: 0.7, alpha: 0.38)
            base.lineWidth = 1.5
            base.glowWidth = 0
            base.zPosition = -50
            addChild(base)
            baseBeamLines.append(base)

            // Color overlay: beam-specific color, hidden by default
            let colorLine = SKShapeNode(path: path)
            colorLine.strokeColor = colors[i % colors.count]
            colorLine.lineWidth = 2.8
            colorLine.glowWidth = 0
            colorLine.alpha = 0
            colorLine.zPosition = -49
            addChild(colorLine)
            colorBeamLines.append(colorLine)
        }
    }

    func setActiveBeam(_ index: Int) {
        let prevIndex = activeBeamIndex
        activeBeamIndex = index

        // Fade out previous beam color
        if prevIndex >= 0 && prevIndex < colorBeamLines.count && prevIndex != index {
            colorBeamLines[prevIndex].removeAction(forKey: "beamTransition")
            colorBeamLines[prevIndex].run(
                SKAction.fadeAlpha(to: 0, duration: 0.2),
                withKey: "beamTransition"
            )
        }

        // Fade in new beam color
        if index >= 0 && index < colorBeamLines.count {
            colorBeamLines[index].removeAction(forKey: "beamTransition")
            colorBeamLines[index].run(
                SKAction.fadeAlpha(to: 0.88, duration: 0.2),
                withKey: "beamTransition"
            )
        }
    }

    /// Brief brighten when laser fires along a beam
    func flashBeam(_ index: Int) {
        guard index >= 0 && index < colorBeamLines.count else { return }
        let line = colorBeamLines[index]

        line.removeAction(forKey: "beamFlash")
        line.alpha = 1.0

        let restore = SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.fadeAlpha(to: index == activeBeamIndex ? 0.88 : 0, duration: 0.15)
        ])
        line.run(restore, withKey: "beamFlash")
    }

    // MARK: - Horizontal Grid Lines (animated top → bottom)

    private func drawGridLines() {
        for line in gridLineNodes { line.removeFromParent() }
        gridLineNodes.removeAll()

        gridPhases = (0..<gridLineCount).map { CGFloat($0) / CGFloat(gridLineCount) }

        for _ in 0..<gridLineCount {
            let line = SKShapeNode()
            line.strokeColor = SKColor(white: 0.85, alpha: 1.0)
            line.lineWidth = 0.8
            line.zPosition = -51
            addChild(line)
            gridLineNodes.append(line)
        }
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval) {
        let scrollSpeed: CGFloat = 0.28

        guard !gridPhases.isEmpty, !vanishingPoints.isEmpty else { return }

        let leftBase = beamPositions.first ?? 0
        let rightBase = beamPositions.last ?? sceneSize.width
        let leftVP = vanishingPoints.first!
        let rightVP = vanishingPoints.last!
        let vpY = vanishingPoint.y

        for i in 0..<gridPhases.count {
            gridPhases[i] += CGFloat(deltaTime) * scrollSpeed
            if gridPhases[i] >= 1.0 {
                gridPhases[i] -= 1.0
            }

            let phase = gridPhases[i]
            let y = vpY * (1.0 - phase)
            let t = y / vpY

            // Left edge interpolates toward left vanishing point
            let leftX = leftBase + (leftVP.x - leftBase) * t
            // Right edge interpolates toward right vanishing point
            let rightX = rightBase + (rightVP.x - rightBase) * t

            let path = CGMutablePath()
            path.move(to: CGPoint(x: leftX, y: y))
            path.addLine(to: CGPoint(x: rightX, y: y))
            gridLineNodes[i].path = path

            // Subtle: 8% near vanishing point, 18% near player
            gridLineNodes[i].alpha = 0.08 + (1.0 - t) * 0.10
        }
    }

    // MARK: - Utilities

    func positionForBeam(_ index: Int) -> CGFloat {
        guard index >= 0 && index < beamPositions.count else {
            return sceneSize.width / 2
        }
        return beamPositions[index]
    }

    func interpolatedPosition(from fromBeam: Int, to toBeam: Int, progress: CGFloat, atY y: CGFloat) -> CGFloat {
        let fromVP = vanishingPoints[fromBeam]
        let toVP = vanishingPoints[toBeam]
        let t = y / vanishingPoint.y
        let fromX = beamPositions[fromBeam] + (fromVP.x - beamPositions[fromBeam]) * t
        let toX = beamPositions[toBeam] + (toVP.x - beamPositions[toBeam]) * t
        return fromX + (toX - fromX) * progress
    }

    func beamXAtY(_ beamIndex: Int, y: CGFloat) -> CGFloat {
        guard beamIndex >= 0 && beamIndex < beamPositions.count else {
            return sceneSize.width / 2
        }
        let vp = vanishingPoints[beamIndex]
        let t = min(max(y / vanishingPoint.y, 0), 1)
        return beamPositions[beamIndex] + (vp.x - beamPositions[beamIndex]) * t
    }

    // MARK: - Beam Cannon

    func chargeAllBeams() {
        for line in colorBeamLines {
            line.removeAction(forKey: "beamTransition")
            line.removeAction(forKey: "beamFlash")
            line.alpha = 1.0
            line.glowWidth = 8
            line.strokeColor = .white

            let pulse = SKAction.sequence([
                SKAction.run { [weak line] in line?.glowWidth = 12 },
                SKAction.wait(forDuration: 0.08),
                SKAction.run { [weak line] in line?.glowWidth = 6 },
                SKAction.wait(forDuration: 0.08)
            ])
            line.run(SKAction.repeatForever(pulse), withKey: "beamCharge")
        }
    }

    func resetAllBeams() {
        let colors = grade.beamColors
        for (i, line) in colorBeamLines.enumerated() {
            line.removeAction(forKey: "beamCharge")
            line.strokeColor = colors[i % colors.count]
            line.lineWidth = 2.8
            line.glowWidth = 0
            line.alpha = i == activeBeamIndex ? 0.88 : 0
        }
    }

    func beamAngle(at beamIndex: Int, y: CGFloat) -> CGFloat {
        guard beamIndex >= 0 && beamIndex < beamPositions.count else {
            return 0
        }
        let vp = vanishingPoints[beamIndex]
        let bottomX = beamPositions[beamIndex]
        let dx = vp.x - bottomX
        let dy = vp.y
        return -atan2(dx, dy)
    }
}
