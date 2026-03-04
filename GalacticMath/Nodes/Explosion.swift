import SpriteKit

final class Explosion: SKNode {
    static func correctExplosion(at position: CGPoint, ageGroup: AgeGroup) -> Explosion {
        let explosion = Explosion()
        explosion.position = position

        // Bright flash circle
        let flash = SKShapeNode(circleOfRadius: 25)
        flash.fillColor = SKColor.white
        flash.strokeColor = .clear
        flash.alpha = 0.9
        flash.zPosition = 99
        explosion.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.5, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        // Main particle burst — asteroid debris feel (orange tint)
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 400
        emitter.numParticlesToEmit = 80
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.4

        emitter.particleSize = CGSize(width: 14, height: 14)
        emitter.particleScaleSpeed = -0.8

        emitter.particleSpeed = 180
        emitter.particleSpeedRange = 80
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2

        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.0

        switch ageGroup {
        case .cadet:
            emitter.particleColor = SKColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0)
            emitter.particleColorRedRange = 0.3
            emitter.particleColorGreenRange = 0.4
            emitter.particleColorBlueRange = 0.2
        case .pilot:
            emitter.particleColor = SKColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0)
            emitter.particleColorBlueRange = 0.3
        case .ace:
            emitter.particleColor = SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0)
            emitter.particleColorRedRange = 0.3
        }

        emitter.particleBlendMode = .add
        explosion.addChild(emitter)

        let label = SKLabelNode(text: "CORRECT!")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = ageGroup == .cadet ? 28 : 22
        label.fontColor = SKColor(red: 0.2, green: 1.0, blue: 0.3, alpha: 1.0)
        label.position = CGPoint(x: 0, y: 30)
        label.zPosition = 100
        explosion.addChild(label)

        let floatUp = SKAction.moveBy(x: 0, y: 40, duration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        label.run(SKAction.group([floatUp, fadeOut]))

        let wait = SKAction.wait(forDuration: 1.2)
        explosion.run(SKAction.sequence([wait, SKAction.removeFromParent()]))

        return explosion
    }

    static func wrongExplosion(at position: CGPoint, ageGroup: AgeGroup) -> Explosion {
        let explosion = Explosion()
        explosion.position = position

        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 15
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2

        emitter.particleSize = CGSize(width: 6, height: 6)
        emitter.particleScaleSpeed = -1.0

        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 40
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2

        emitter.particleColor = SKColor.red
        emitter.particleAlphaSpeed = -1.5
        emitter.particleBlendMode = .add
        explosion.addChild(emitter)

        let msg = ageGroup == .cadet ? "Try again!" : "TRY AGAIN!"
        let label = SKLabelNode(text: msg)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = ageGroup == .cadet ? 22 : 18
        label.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        label.position = CGPoint(x: 0, y: 30)
        label.zPosition = 100
        explosion.addChild(label)

        let floatUp = SKAction.moveBy(x: 0, y: 30, duration: 0.6)
        let fadeOut = SKAction.fadeOut(withDuration: 0.6)
        label.run(SKAction.group([floatUp, fadeOut]))

        let wait = SKAction.wait(forDuration: 0.8)
        explosion.run(SKAction.sequence([wait, SKAction.removeFromParent()]))

        return explosion
    }

    static func bossExplosion(at position: CGPoint) -> Explosion {
        let explosion = Explosion()
        explosion.position = position

        for i in 0..<3 {
            let delay = Double(i) * 0.2
            let emitter = SKEmitterNode()
            emitter.particleBirthRate = 300
            emitter.numParticlesToEmit = 60
            emitter.particleLifetime = 1.0
            emitter.particleLifetimeRange = 0.3

            emitter.particleSize = CGSize(width: 10, height: 10)
            emitter.particleScaleSpeed = -0.8

            emitter.particleSpeed = 150
            emitter.particleSpeedRange = 80
            emitter.emissionAngle = 0
            emitter.emissionAngleRange = .pi * 2

            emitter.particleColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
            emitter.particleColorRedRange = 0.5
            emitter.particleColorGreenRange = 0.5
            emitter.particleAlphaSpeed = -0.8
            emitter.particleBlendMode = .add

            let delayAction = SKAction.wait(forDuration: delay)
            let addEmitter = SKAction.run { [weak explosion] in
                explosion?.addChild(emitter)
            }
            explosion.run(SKAction.sequence([delayAction, addEmitter]))
        }

        let wait = SKAction.wait(forDuration: 1.5)
        explosion.run(SKAction.sequence([wait, SKAction.removeFromParent()]))

        return explosion
    }

    // MARK: - Chain Explosion

    static func chainExplosion(at position: CGPoint, color: SKColor, sizeFactor: CGFloat = 1.0, completion: @escaping () -> Void) -> Explosion {
        let explosion = Explosion()
        explosion.position = position

        // Large particle burst
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 500 * sizeFactor
        emitter.numParticlesToEmit = Int(100 * sizeFactor)
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2

        let pSize = 8 * sizeFactor
        emitter.particleSize = CGSize(width: pSize, height: pSize)
        emitter.particleScaleSpeed = -1.0

        emitter.particleSpeed = 200 * sizeFactor
        emitter.particleSpeedRange = 80
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2

        emitter.particleColor = color
        emitter.particleColorRedRange = 0.3
        emitter.particleColorGreenRange = 0.3
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.5
        emitter.particleBlendMode = .add

        explosion.addChild(emitter)

        // White flash circle
        let flash = SKShapeNode(circleOfRadius: 30 * sizeFactor)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 0.9
        flash.zPosition = 99
        explosion.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 3.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        // Completion after 0.8s, self-remove
        explosion.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.run(completion),
            SKAction.removeFromParent()
        ]))

        return explosion
    }

    // MARK: - Bottom Impact Flash

    static func bottomImpactFlash(across sceneSize: CGSize) -> Explosion {
        let explosion = Explosion()
        explosion.position = CGPoint(x: sceneSize.width / 2, y: 20)
        explosion.zPosition = 90

        let bar = SKShapeNode(rectOf: CGSize(width: sceneSize.width, height: 40))
        bar.fillColor = SKColor.red.withAlphaComponent(0.25)
        bar.strokeColor = .clear
        explosion.addChild(bar)

        explosion.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ]))

        return explosion
    }
}
