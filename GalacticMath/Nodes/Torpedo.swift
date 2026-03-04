import SpriteKit

final class Torpedo: SKNode {
    var beamIndex: Int = 0

    func setup(grade: Grade) {
        let body = SKShapeNode(ellipseOf: CGSize(width: 10, height: 18))
        body.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        body.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        body.lineWidth = 2.0
        body.glowWidth = 4.0
        addChild(body)

        let trail = SKEmitterNode()
        trail.particleBirthRate = 100
        trail.particleLifetime = 0.4
        trail.particleLifetimeRange = 0.1
        trail.particleSize = CGSize(width: 8, height: 8)
        trail.particleScaleSpeed = -2.0
        trail.particleColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
        trail.particleColorRedRange = 0.3
        trail.particleAlphaSpeed = -2.0
        trail.particleSpeed = 30
        trail.emissionAngle = -.pi / 2
        trail.emissionAngleRange = .pi / 4
        trail.particleBlendMode = .add
        trail.position = CGPoint(x: 0, y: -10)
        addChild(trail)
    }

    func fire(from startPos: CGPoint, toY targetY: CGFloat, beamGrid: BeamGrid, duration: TimeInterval = 0.5) {
        position = startPos
        let targetX = beamGrid.beamXAtY(beamIndex, y: targetY)
        let target = CGPoint(x: targetX, y: targetY)

        let move = SKAction.move(to: target, duration: duration)
        let scaleDown = SKAction.scale(to: 0.3, duration: duration)
        let group = SKAction.group([move, scaleDown])

        run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }
}
