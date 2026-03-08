import SpriteKit

final class StarField: SKNode {
    private var layerContainers: [SKNode] = []
    private var layerStars: [[SKShapeNode]] = [[], [], []]
    private var speeds: [CGFloat] = [15, 30, 60]
    private var sceneSize: CGSize = .zero
    private var grade: Grade = .kindergarten

    // Horizontal parallax
    private var targetOffsetX: CGFloat = 0
    private var currentOffsetX: CGFloat = 0
    private var lastShipBeam: Int = -1
    private let layerParallaxX: [CGFloat] = [18, 38, 65]
    private let layerParallaxY: [CGFloat] = [5, 10, 18]

    func setup(size: CGSize, grade: Grade) {
        self.sceneSize = size
        self.grade = grade

        // Create layer containers
        for i in 0..<3 {
            let container = SKNode()
            container.zPosition = -100 + CGFloat(i)
            addChild(container)
            layerContainers.append(container)
        }

        let starCounts = [40, 25, 15]
        let starSizes: [CGFloat] = [1.0, 1.5, 2.5]

        for layer in 0..<3 {
            for _ in 0..<starCounts[layer] {
                let star = SKShapeNode(circleOfRadius: starSizes[layer])
                star.position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                )

                if grade.rawValue < 2 {
                    let colors: [SKColor] = [.white, .yellow, .cyan, SKColor(red: 1, green: 0.7, blue: 0.7, alpha: 1)]
                    star.fillColor = colors.randomElement()!
                    if layer == 2 {
                        let twinkle = SKAction.sequence([
                            SKAction.fadeAlpha(to: 0.3, duration: Double.random(in: 0.5...1.5)),
                            SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 0.5...1.5))
                        ])
                        star.run(SKAction.repeatForever(twinkle))
                    }
                } else {
                    let brightness = CGFloat.random(in: 0.6...1.0)
                    star.fillColor = SKColor(red: brightness, green: brightness, blue: min(1.0, brightness + 0.1), alpha: 1.0)
                }

                star.strokeColor = .clear
                star.alpha = CGFloat(layer + 1) / 3.0
                layerContainers[layer].addChild(star)
                layerStars[layer].append(star)
            }
        }

        runShootingStarLoop()
    }

    func update(deltaTime: TimeInterval) {
        let dt = CGFloat(deltaTime)
        for layer in 0..<3 {
            for star in layerStars[layer] {
                star.position.y -= speeds[layer] * dt
                if star.position.y < -5 {
                    star.position.y = sceneSize.height + 5
                    star.position.x = CGFloat.random(in: 0...sceneSize.width)
                }
            }
        }
    }

    // MARK: - Horizontal Parallax

    func updateHorizontalParallax(shipBeam: Int, totalBeams: Int) {
        guard shipBeam != lastShipBeam else { return }
        lastShipBeam = shipBeam
        let normalized = totalBeams > 1
            ? (CGFloat(shipBeam) / CGFloat(totalBeams - 1)) * 2 - 1
            : 0
        targetOffsetX = normalized
    }

    func updateParallaxFrame() {
        let lerpFactor: CGFloat = 0.06
        currentOffsetX += (targetOffsetX - currentOffsetX) * lerpFactor
        applyLayerOffsets(normalized: currentOffsetX)
    }

    private func applyLayerOffsets(normalized: CGFloat) {
        for i in 0..<layerContainers.count {
            layerContainers[i].position.x = -normalized * layerParallaxX[i]
            layerContainers[i].position.y = normalized * layerParallaxY[i]
        }
    }

    func triggerBankImpulse(direction: Int) {
        let impulse = CGFloat(direction) * -25
        layerContainers[2].position.x += impulse
        layerContainers[1].position.x += impulse * 0.6
        layerContainers[0].position.x += impulse * 0.3
    }

    private func runShootingStarLoop() {
        let wait = SKAction.wait(forDuration: 5.0, withRange: 8.0)
        let spawn = SKAction.run { [weak self] in
            self?.spawnShootingStar()
        }
        run(SKAction.repeatForever(SKAction.sequence([wait, spawn])))
    }

    private func spawnShootingStar() {
        let star = SKShapeNode(circleOfRadius: 2.0)
        star.fillColor = .white
        star.strokeColor = .clear
        star.glowWidth = 3.0
        star.position = CGPoint(
            x: CGFloat.random(in: 0...sceneSize.width),
            y: sceneSize.height + 10
        )
        star.zPosition = -90
        addChild(star)

        let endX = star.position.x + CGFloat.random(in: -200...200)
        let move = SKAction.move(to: CGPoint(x: endX, y: -10), duration: 0.8)
        let fade = SKAction.fadeOut(withDuration: 0.8)
        let group = SKAction.group([move, fade])
        star.run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }
}
