import SpriteKit

final class ParallaxBackgroundNode: SKNode {

    private struct Layer {
        let node: SKNode          // SKSpriteNode or SKEffectNode wrapper
        let speedFactor: CGFloat
        let joltMagnitude: CGFloat
        let verticalFreq: CGFloat
        let verticalAmp: CGFloat
        var currentOffsetX: CGFloat = 0
    }

    private var layers: [Layer] = []
    private var sceneSize: CGSize = .zero
    private var maxOffset: CGFloat = 0

    func setup(size: CGSize) {
        self.sceneSize = size
        self.maxOffset = size.width * 0.20

        let texture = SKTexture(imageNamed: "bg_1")
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        // Layer configs: (overflowFactor, alpha, zPos, speedFactor, joltMag, vFreq, vAmp, blur)
        let configs: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, Bool)] = [
            (0.25, 1.0,  -100, 0.15, 8,  0.08, 4,  false),  // far
            (0.20, 0.35, -99,  0.35, 18, 0.12, 7,  true),   // mid (blurred)
            (0.15, 0.15, -98,  0.60, 30, 0.18, 10, false),  // near
        ]

        for cfg in configs {
            let coverW = size.width * (1 + cfg.0)
            let coverH = size.height * (1 + cfg.0)

            let sprite = SKSpriteNode(texture: texture)
            // Aspect-fill: scale so the image covers the entire coverSize
            let scaleX = coverW / texture.size().width
            let scaleY = coverH / texture.size().height
            let fillScale = max(scaleX, scaleY)
            sprite.setScale(fillScale)
            sprite.position = center

            let layerNode: SKNode
            if cfg.7 {
                // Wrap in SKEffectNode for blur
                let effect = SKEffectNode()
                effect.shouldEnableEffects = true
                effect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 1.5])
                effect.shouldRasterize = true
                effect.addChild(sprite)
                effect.zPosition = cfg.2
                effect.alpha = cfg.1
                addChild(effect)
                layerNode = effect
            } else {
                sprite.zPosition = cfg.2
                sprite.alpha = cfg.1
                addChild(sprite)
                layerNode = sprite
            }

            layers.append(Layer(
                node: layerNode,
                speedFactor: cfg.3,
                joltMagnitude: cfg.4,
                verticalFreq: cfg.5,
                verticalAmp: cfg.6
            ))
        }
    }

    func update(shipX: CGFloat, sceneWidth: CGFloat, currentTime: TimeInterval) {
        let normalizedX = (shipX / sceneWidth) - 0.5
        // Smoothstep for eased feel
        let absN = abs(normalizedX) * 2 // 0..1
        let smooth = absN * absN * (3 - 2 * absN) * 0.5
        let smoothX = normalizedX < 0 ? -smooth : smooth

        let centerX = sceneSize.width / 2
        let centerY = sceneSize.height / 2

        for i in 0..<layers.count {
            let targetX = -smoothX * maxOffset * layers[i].speedFactor
            layers[i].currentOffsetX += (targetX - layers[i].currentOffsetX) * 0.12

            let vertY = sin(currentTime * Double(layers[i].verticalFreq)) * Double(layers[i].verticalAmp)

            layers[i].node.position = CGPoint(
                x: centerX + layers[i].currentOffsetX,
                y: centerY + CGFloat(vertY)
            )
        }
    }

    func triggerExplosion(at position: CGPoint) {
        let center = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        let dx = position.x - center.x
        let dy = position.y - center.y
        let dist = max(hypot(dx, dy), 1)

        for layer in layers {
            let joltX = -(dx / dist) * layer.joltMagnitude
            let joltY = -(dy / dist) * layer.joltMagnitude * 0.5

            let jolt = SKAction.moveBy(x: joltX, y: joltY, duration: 0.05)
            let recover = SKAction.moveBy(x: -joltX, y: -joltY, duration: 0.35)
            recover.timingMode = .easeOut
            layer.node.run(SKAction.sequence([jolt, recover]), withKey: "bgJolt")
        }
    }

    func triggerShockwave(at position: CGPoint, intensity: CGFloat) {
        for layer in layers {
            let drop = -intensity * 14
            let down = SKAction.moveBy(x: 0, y: drop, duration: 0.06)
            let up = SKAction.moveBy(x: 0, y: -drop, duration: 0.44)
            up.timingMode = .easeOut
            layer.node.run(SKAction.sequence([down, up]), withKey: "bgShock")
        }
    }
}
