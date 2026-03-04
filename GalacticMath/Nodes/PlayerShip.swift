import SpriteKit

final class PlayerShip: SKNode {
    private var shipBody: SKShapeNode!
    private var engineTrail: SKEmitterNode?
    private var shieldNode: SKShapeNode?
    private var grade: Grade = .kindergarten
    var currentBeam: Int = 0
    var isInvincible: Bool = false
    private var isMoving: Bool = false

    func setup(grade: Grade) {
        self.grade = grade
        removeAllChildren()

        switch grade.rawValue {
        case 0...1:
            buildCadetShip()
        case 2...3:
            buildPilotShip()
        default:
            buildAceShip()
        }

        addEngineTrail()
        startIdleAnimation()
    }

    private func buildCadetShip() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 25))
        path.addQuadCurve(to: CGPoint(x: -15, y: -10), control: CGPoint(x: -10, y: 15))
        path.addQuadCurve(to: CGPoint(x: -20, y: -18), control: CGPoint(x: -18, y: -12))
        path.addLine(to: CGPoint(x: -8, y: -15))
        path.addLine(to: CGPoint(x: -8, y: -20))
        path.addLine(to: CGPoint(x: 8, y: -20))
        path.addLine(to: CGPoint(x: 8, y: -15))
        path.addLine(to: CGPoint(x: 20, y: -18))
        path.addQuadCurve(to: CGPoint(x: 15, y: -10), control: CGPoint(x: 18, y: -12))
        path.addQuadCurve(to: CGPoint(x: 0, y: 25), control: CGPoint(x: 10, y: 15))
        path.closeSubpath()

        shipBody = SKShapeNode(path: path)
        shipBody.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        shipBody.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
        shipBody.lineWidth = 2.0
        shipBody.glowWidth = 1.0
        addChild(shipBody)

        let window = SKShapeNode(circleOfRadius: 5)
        window.fillColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 1.0)
        window.strokeColor = .white
        window.lineWidth = 1.0
        window.position = CGPoint(x: 0, y: 5)
        shipBody.addChild(window)
    }

    private func buildPilotShip() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 28))
        path.addLine(to: CGPoint(x: -8, y: 10))
        path.addLine(to: CGPoint(x: -22, y: -12))
        path.addLine(to: CGPoint(x: -25, y: -18))
        path.addLine(to: CGPoint(x: -10, y: -14))
        path.addLine(to: CGPoint(x: -6, y: -22))
        path.addLine(to: CGPoint(x: 6, y: -22))
        path.addLine(to: CGPoint(x: 10, y: -14))
        path.addLine(to: CGPoint(x: 25, y: -18))
        path.addLine(to: CGPoint(x: 22, y: -12))
        path.addLine(to: CGPoint(x: 8, y: 10))
        path.closeSubpath()

        shipBody = SKShapeNode(path: path)
        shipBody.fillColor = SKColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 1.0)
        shipBody.strokeColor = SKColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0)
        shipBody.lineWidth = 1.5
        shipBody.glowWidth = 2.0
        addChild(shipBody)

        let cockpit = SKShapeNode(ellipseOf: CGSize(width: 8, height: 12))
        cockpit.fillColor = SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.8)
        cockpit.strokeColor = .clear
        cockpit.position = CGPoint(x: 0, y: 6)
        shipBody.addChild(cockpit)
    }

    private func buildAceShip() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 30))
        path.addLine(to: CGPoint(x: -5, y: 18))
        path.addLine(to: CGPoint(x: -12, y: 5))
        path.addLine(to: CGPoint(x: -28, y: -10))
        path.addLine(to: CGPoint(x: -30, y: -20))
        path.addLine(to: CGPoint(x: -15, y: -15))
        path.addLine(to: CGPoint(x: -8, y: -18))
        path.addLine(to: CGPoint(x: -5, y: -25))
        path.addLine(to: CGPoint(x: 5, y: -25))
        path.addLine(to: CGPoint(x: 8, y: -18))
        path.addLine(to: CGPoint(x: 15, y: -15))
        path.addLine(to: CGPoint(x: 30, y: -20))
        path.addLine(to: CGPoint(x: 28, y: -10))
        path.addLine(to: CGPoint(x: 12, y: 5))
        path.addLine(to: CGPoint(x: 5, y: 18))
        path.closeSubpath()

        shipBody = SKShapeNode(path: path)
        shipBody.fillColor = SKColor(red: 0.3, green: 0.1, blue: 0.5, alpha: 1.0)
        shipBody.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        shipBody.lineWidth = 1.5
        shipBody.glowWidth = 2.0
        addChild(shipBody)

        let cockpit = SKShapeNode(ellipseOf: CGSize(width: 6, height: 10))
        cockpit.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.8)
        cockpit.strokeColor = .clear
        cockpit.position = CGPoint(x: 0, y: 8)
        shipBody.addChild(cockpit)
    }

    private func addEngineTrail() {
        let emitter = createEngineEmitter()
        emitter.position = CGPoint(x: 0, y: -22)
        emitter.zPosition = -1
        addChild(emitter)
        engineTrail = emitter
    }

    private func createEngineEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2

        emitter.particleSize = CGSize(width: 6, height: 6)
        emitter.particleScaleRange = 0.5
        emitter.particleScaleSpeed = -1.0

        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 6
        emitter.particleSpeed = 60
        emitter.particleSpeedRange = 20

        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -1.5

        switch grade.rawValue {
        case 0...1:
            emitter.particleColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
            emitter.particleColorBlueRange = 0.0
            emitter.particleColorRedRange = 0.3
        case 2...3:
            emitter.particleColor = SKColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1.0)
            emitter.particleColorBlueRange = 0.3
        default:
            emitter.particleColor = grade.primaryColor
            emitter.particleColorRedRange = 0.3
        }

        emitter.particleBlendMode = .add

        return emitter
    }

    private func startIdleAnimation() {
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 1.2),
            SKAction.moveBy(x: 0, y: -3, duration: 1.2)
        ])
        shipBody.run(SKAction.repeatForever(bob), withKey: "idle")
    }

    func moveToBeam(_ beam: Int, x: CGFloat, beamAngle: CGFloat, duration: TimeInterval = 0.15) {
        // Determine movement direction before updating currentBeam
        let movingRight = beam > currentBeam
        currentBeam = beam

        removeAction(forKey: "move")

        // Bank slightly in the movement direction, then settle to beam angle.
        // Moving right → nose tilts right (negative offset); left → tilts left (positive).
        let bankOffset: CGFloat = movingRight ? -0.18 : 0.18
        let bankedAngle = beamAngle + bankOffset

        let move = SKAction.moveTo(x: x, duration: duration)
        let bank = SKAction.rotate(toAngle: bankedAngle, duration: duration * 0.5, shortestUnitArc: true)
        let settle = SKAction.rotate(toAngle: beamAngle, duration: duration * 0.5, shortestUnitArc: true)
        let rotateSeq = SKAction.sequence([bank, settle])

        run(SKAction.group([move, rotateSeq]), withKey: "move")
    }

    func setBeamAngle(_ angle: CGFloat) {
        zRotation = angle
    }

    func showShield() {
        guard shieldNode == nil else { return }
        isInvincible = true

        let shield = SKShapeNode(circleOfRadius: 35)
        shield.fillColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.15)
        shield.strokeColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.6)
        shield.lineWidth = 2.0
        shield.glowWidth = 3.0
        addChild(shield)
        shieldNode = shield

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 0.9, duration: 0.5)
        ])
        shield.run(SKAction.repeatForever(pulse))

        let removeAfter = SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.removeShield()
            }
        ])
        shield.run(removeAfter, withKey: "shieldTimer")
    }

    func removeShield() {
        isInvincible = false
        shieldNode?.removeFromParent()
        shieldNode = nil
    }

    func victorySpin() {
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.5)
        shipBody.run(spin)
    }

    func hitFlash() {
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1),
            SKAction.fadeAlpha(to: 0.2, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        run(flash)
    }
}
