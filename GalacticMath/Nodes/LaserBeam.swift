import SpriteKit

final class LaserBeam: SKNode {
    private var beam: SKShapeNode!
    var beamIndex: Int = 0

    func setup(ageGroup: AgeGroup) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 20))

        beam = SKShapeNode(path: path)
        beam.lineWidth = 3.0
        beam.glowWidth = 4.0

        switch ageGroup {
        case .cadet:
            beam.strokeColor = SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case .pilot:
            beam.strokeColor = SKColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case .ace:
            beam.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 1.0, alpha: 1.0)
        }

        addChild(beam)

        let trail = SKEmitterNode()
        trail.particleBirthRate = 40
        trail.particleLifetime = 0.2
        trail.particleSize = CGSize(width: 4, height: 4)
        trail.particleColor = beam.strokeColor
        trail.particleAlphaSpeed = -3.0
        trail.particleSpeed = 10
        trail.emissionAngle = -.pi / 2
        trail.particleBlendMode = .add
        trail.position = CGPoint(x: 0, y: 0)
        addChild(trail)
    }

    func fire(from startPos: CGPoint, toY targetY: CGFloat, beamGrid: BeamGrid, duration: TimeInterval = 0.3) {
        position = startPos
        let targetX = beamGrid.beamXAtY(beamIndex, y: targetY)
        let target = CGPoint(x: targetX, y: targetY)

        let move = SKAction.move(to: target, duration: duration)
        let scaleDown = SKAction.scale(to: 0.5, duration: duration)
        let group = SKAction.group([move, scaleDown])

        run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }
}
