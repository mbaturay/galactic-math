import SpriteKit

final class BeamGrid: SKNode {
    private var baseBeamLines: [SKNode] = []    // Grey containers, always visible
    private var colorBeamLines: [SKNode] = []   // Colored containers, animated
    private var gridLineNodes: [SKShapeNode] = []
    private var beamCount: Int = 5
    private var sceneSize: CGSize = .zero
    private var grade: Grade = .kindergarten
    private var activeBeamIndex: Int = -1

    private let beamSegmentCount = 12

    // Grid line animation
    private let gridLineCount = 16
    private var gridPhases: [CGFloat] = []

    var beamPositions: [CGFloat] = []

    /// Per-beam vanishing points spread across the vanishing zone
    private var vanishingPoints: [CGPoint] = []

    /// Width of the vanishing zone at the top (beams spread across this)
    private var vanishingZoneWidth: CGFloat = 0

    /// Center of the vanishing zone — used by GameScene for enemyStartY
    var vanishingPoint: CGPoint {
        return CGPoint(x: sceneSize.width / 2, y: sceneSize.height * 0.92)
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
        for node in baseBeamLines { node.removeFromParent() }
        for node in colorBeamLines { node.removeFromParent() }
        baseBeamLines.removeAll()
        colorBeamLines.removeAll()

        let colors = grade.beamColors

        for i in 0..<beamCount {
            let vp = vanishingPoints[i]
            let bottomX = beamPositions[i]
            let bottomY: CGFloat = 0

            // Base layer container: light grey, always visible
            let baseContainer = SKNode()
            baseContainer.zPosition = -50
            addChild(baseContainer)
            baseBeamLines.append(baseContainer)

            // Color overlay container: hidden by default
            let colorContainer = SKNode()
            colorContainer.zPosition = -49
            colorContainer.alpha = 0
            addChild(colorContainer)
            colorBeamLines.append(colorContainer)

            for s in 0..<beamSegmentCount {
                let t0 = CGFloat(s) / CGFloat(beamSegmentCount)
                let t1 = CGFloat(s + 1) / CGFloat(beamSegmentCount)
                let tMid = (t0 + t1) / 2

                // Interpolate from vanishing point (t=0) to bottom (t=1)
                let x0 = vp.x + (bottomX - vp.x) * t0
                let y0 = vp.y + (bottomY - vp.y) * t0
                let x1 = vp.x + (bottomX - vp.x) * t1
                let y1 = vp.y + (bottomY - vp.y) * t1

                let path = CGMutablePath()
                path.move(to: CGPoint(x: x0, y: y0))
                path.addLine(to: CGPoint(x: x1, y: y1))

                // Quadratic fade: 0 at VP, 1 at bottom
                let segAlpha = tMid * tMid
                let segWidth = 0.3 + 1.2 * tMid

                // Base segment
                let baseSeg = SKShapeNode(path: path)
                baseSeg.strokeColor = SKColor(white: 0.7, alpha: 0.38)
                baseSeg.lineWidth = segWidth
                baseSeg.glowWidth = 0
                baseSeg.alpha = segAlpha
                baseContainer.addChild(baseSeg)

                // Color segment
                let colorSeg = SKShapeNode(path: path)
                colorSeg.strokeColor = colors[i % colors.count]
                colorSeg.lineWidth = segWidth + 1.3
                colorSeg.glowWidth = 0
                colorSeg.alpha = segAlpha
                colorContainer.addChild(colorSeg)
            }
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
        let maxGridY = vpY * 0.60  // Only lower 60% of the grid

        for i in 0..<gridPhases.count {
            gridPhases[i] += CGFloat(deltaTime) * scrollSpeed
            if gridPhases[i] >= 1.0 {
                gridPhases[i] -= 1.0
            }

            let phase = gridPhases[i]
            // Quadratic mapping: bunches lines at the top (perspective foreshortening)
            let mappedPhase = phase * phase
            let y = maxGridY * (1.0 - mappedPhase)
            let t = y / vpY

            // Left edge interpolates toward left vanishing point
            let leftX = leftBase + (leftVP.x - leftBase) * t
            // Right edge interpolates toward right vanishing point
            let rightX = rightBase + (rightVP.x - rightBase) * t

            let path = CGMutablePath()
            path.move(to: CGPoint(x: leftX, y: y))
            path.addLine(to: CGPoint(x: rightX, y: y))
            gridLineNodes[i].path = path

            // Fade: 0 at top of visible range, 0.18 at bottom
            let normalizedHeight = y / maxGridY  // 0 at bottom, 1 at top
            let lineAlpha = max(0, (1.0 - normalizedHeight) * 0.18)
            gridLineNodes[i].alpha = lineAlpha

            // Lines get thinner toward top
            gridLineNodes[i].lineWidth = 0.3 + 0.5 * (1.0 - normalizedHeight)
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
        for container in colorBeamLines {
            container.removeAction(forKey: "beamTransition")
            container.removeAction(forKey: "beamFlash")
            container.alpha = 1.0
            for child in container.children {
                guard let seg = child as? SKShapeNode else { continue }
                seg.glowWidth = 8
                seg.strokeColor = .white
                seg.alpha = 1.0
            }

            let pulse = SKAction.sequence([
                SKAction.run { [weak container] in
                    container?.children.compactMap { $0 as? SKShapeNode }.forEach { $0.glowWidth = 12 }
                },
                SKAction.wait(forDuration: 0.08),
                SKAction.run { [weak container] in
                    container?.children.compactMap { $0 as? SKShapeNode }.forEach { $0.glowWidth = 6 }
                },
                SKAction.wait(forDuration: 0.08)
            ])
            container.run(SKAction.repeatForever(pulse), withKey: "beamCharge")
        }
    }

    func resetAllBeams() {
        let colors = grade.beamColors
        for (i, container) in colorBeamLines.enumerated() {
            container.removeAction(forKey: "beamCharge")
            for (s, child) in container.children.enumerated() {
                guard let seg = child as? SKShapeNode else { continue }
                let tMid = (CGFloat(s) + 0.5) / CGFloat(beamSegmentCount)
                seg.strokeColor = colors[i % colors.count]
                seg.lineWidth = 0.3 + 1.2 * tMid + 1.3
                seg.glowWidth = 0
                seg.alpha = tMid * tMid
            }
            container.alpha = i == activeBeamIndex ? 0.88 : 0
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
