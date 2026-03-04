import SpriteKit

final class LaserBeam: SKNode {
    var beamIndex: Int = 0
    private var beamColor: SKColor = .cyan

    func setup(color: SKColor) {
        beamColor = color

        // --- OUTER GLOW: thick, transparent ---
        let glowPath = CGMutablePath()
        glowPath.move(to: CGPoint(x: 0, y: -10))
        glowPath.addLine(to: CGPoint(x: 0, y: 35))

        let outerGlow = SKShapeNode(path: glowPath)
        outerGlow.lineWidth = 16.0
        outerGlow.strokeColor = beamColor.withAlphaComponent(0.2)
        outerGlow.glowWidth = 14.0
        outerGlow.zPosition = -1
        addChild(outerGlow)

        // --- MID LAYER: beam color, medium thickness ---
        let midPath = CGMutablePath()
        midPath.move(to: CGPoint(x: 0, y: -8))
        midPath.addLine(to: CGPoint(x: 0, y: 35))

        let mid = SKShapeNode(path: midPath)
        mid.lineWidth = 10.0
        mid.strokeColor = beamColor.withAlphaComponent(0.6)
        mid.glowWidth = 4.0
        mid.zPosition = 0
        addChild(mid)

        // --- BRIGHT CORE: thin, intense white center ---
        let corePath = CGMutablePath()
        corePath.move(to: CGPoint(x: 0, y: -5))
        corePath.addLine(to: CGPoint(x: 0, y: 35))

        let core = SKShapeNode(path: corePath)
        core.lineWidth = 4.0
        core.strokeColor = SKColor(white: 1.0, alpha: 0.95)
        core.glowWidth = 6.0
        core.zPosition = 1
        addChild(core)

        // --- TRAIL PARTICLES: fire/energy trailing behind ---
        let trail = SKEmitterNode()
        trail.particleBirthRate = 120
        trail.particleLifetime = 0.4
        trail.particleLifetimeRange = 0.15
        trail.particleSize = CGSize(width: 10, height: 10)
        trail.particleScaleRange = 0.4
        trail.particleColor = beamColor
        trail.particleColorBlendFactor = 1.0
        trail.particleAlpha = 0.8
        trail.particleAlphaSpeed = -2.0
        trail.particleSpeed = 20
        trail.particleSpeedRange = 10
        trail.emissionAngle = -.pi / 2
        trail.emissionAngleRange = .pi / 4
        trail.particleBlendMode = .add
        trail.particleScaleSpeed = -1.0
        trail.position = CGPoint(x: 0, y: -5)
        addChild(trail)

        // --- SIDEWAYS SPARKS ---
        let sparks = SKEmitterNode()
        sparks.particleBirthRate = 60
        sparks.particleLifetime = 0.25
        sparks.particleLifetimeRange = 0.1
        sparks.particleSize = CGSize(width: 3, height: 3)
        sparks.particleColor = SKColor.white
        sparks.particleAlpha = 1.0
        sparks.particleAlphaSpeed = -4.0
        sparks.particleSpeed = 80
        sparks.particleSpeedRange = 40
        sparks.emissionAngle = 0
        sparks.emissionAngleRange = .pi
        sparks.particleBlendMode = .add
        sparks.position = CGPoint(x: 0, y: 10)
        addChild(sparks)
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
