import SpriteKit

final class BeamGrid: SKNode {
    private var beamLines: [SKShapeNode] = []
    private var gridLines: [SKShapeNode] = []
    private var beamCount: Int = 5
    private var sceneSize: CGSize = .zero
    private var ageGroup: AgeGroup = .cadet
    private var activeBeamIndex: Int = 0
    private var gridOffset: CGFloat = 0

    var beamPositions: [CGFloat] = []

    var vanishingPoint: CGPoint {
        return CGPoint(x: sceneSize.width / 2, y: sceneSize.height * 0.85)
    }

    func setup(size: CGSize, ageGroup: AgeGroup) {
        self.sceneSize = size
        self.ageGroup = ageGroup
        self.beamCount = ageGroup.beamCount

        calculateBeamPositions()
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

    private func drawBeams() {
        for line in beamLines {
            line.removeFromParent()
        }
        beamLines.removeAll()

        let colors = ageGroup.beamColors

        for i in 0..<beamCount {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: beamPositions[i], y: 0))
            path.addLine(to: vanishingPoint)

            let line = SKShapeNode(path: path)
            let colorIndex = i % colors.count
            line.strokeColor = colors[colorIndex].withAlphaComponent(0.3)
            line.lineWidth = ageGroup == .cadet ? 3.0 : 2.0
            line.zPosition = -50
            line.glowWidth = ageGroup == .cadet ? 2.0 : 1.0
            addChild(line)
            beamLines.append(line)
        }
    }

    private func drawGridLines() {
        let horizontalCount = 8
        for i in 0..<horizontalCount {
            let t = CGFloat(i) / CGFloat(horizontalCount)
            let y = t * vanishingPoint.y

            let leftX = beamPositions.first! + (vanishingPoint.x - beamPositions.first!) * t
            let rightX = beamPositions.last! + (vanishingPoint.x - beamPositions.last!) * t

            let path = CGMutablePath()
            path.move(to: CGPoint(x: leftX, y: y))
            path.addLine(to: CGPoint(x: rightX, y: y))

            let line = SKShapeNode(path: path)
            line.strokeColor = ageGroup.primaryColor.withAlphaComponent(0.08)
            line.lineWidth = 1.0
            line.zPosition = -51
            addChild(line)
            gridLines.append(line)
        }
    }

    func setActiveBeam(_ index: Int) {
        activeBeamIndex = index
        for (i, line) in beamLines.enumerated() {
            let colors = ageGroup.beamColors
            let colorIndex = i % colors.count
            if i == index {
                line.strokeColor = colors[colorIndex].withAlphaComponent(0.8)
                line.glowWidth = ageGroup == .cadet ? 4.0 : 3.0
            } else {
                line.strokeColor = colors[colorIndex].withAlphaComponent(0.3)
                line.glowWidth = ageGroup == .cadet ? 2.0 : 1.0
            }
        }
    }

    func update(deltaTime: TimeInterval) {
        gridOffset += CGFloat(deltaTime) * 40.0
        if gridOffset > 50.0 {
            gridOffset -= 50.0
        }
    }

    func positionForBeam(_ index: Int) -> CGFloat {
        guard index >= 0 && index < beamPositions.count else {
            return sceneSize.width / 2
        }
        return beamPositions[index]
    }

    func interpolatedPosition(from fromBeam: Int, to toBeam: Int, progress: CGFloat, atY y: CGFloat) -> CGFloat {
        let t = y / vanishingPoint.y
        let fromX = beamPositions[fromBeam] + (vanishingPoint.x - beamPositions[fromBeam]) * t
        let toX = beamPositions[toBeam] + (vanishingPoint.x - beamPositions[toBeam]) * t
        return fromX + (toX - fromX) * progress
    }

    func beamXAtY(_ beamIndex: Int, y: CGFloat) -> CGFloat {
        guard beamIndex >= 0 && beamIndex < beamPositions.count else {
            return sceneSize.width / 2
        }
        let t = min(max(y / vanishingPoint.y, 0), 1)
        return beamPositions[beamIndex] + (vanishingPoint.x - beamPositions[beamIndex]) * t
    }

    func beamAngle(at beamIndex: Int, y: CGFloat) -> CGFloat {
        guard beamIndex >= 0 && beamIndex < beamPositions.count else {
            return 0
        }
        let bottomX = beamPositions[beamIndex]
        let dx = vanishingPoint.x - bottomX
        let dy = vanishingPoint.y
        // Ship sprite is drawn with nose along +Y.
        // To align local +Y with direction (dx, dy): zRotation = -atan2(dx, dy)
        return -atan2(dx, dy)
    }
}
