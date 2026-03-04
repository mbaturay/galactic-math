import SpriteKit

final class StarField: SKNode {
    private var layers: [[SKShapeNode]] = [[], [], []]
    private var speeds: [CGFloat] = [15, 30, 60]
    private var sceneSize: CGSize = .zero
    private var ageGroup: AgeGroup = .cadet

    func setup(size: CGSize, ageGroup: AgeGroup) {
        self.sceneSize = size
        self.ageGroup = ageGroup

        let starCounts = [40, 25, 15]
        let starSizes: [CGFloat] = [1.0, 1.5, 2.5]

        for layer in 0..<3 {
            for _ in 0..<starCounts[layer] {
                let star = SKShapeNode(circleOfRadius: starSizes[layer])
                star.position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                )

                if ageGroup == .cadet {
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
                star.zPosition = -100 + CGFloat(layer)
                addChild(star)
                layers[layer].append(star)
            }
        }

        runShootingStarLoop()
    }

    func update(deltaTime: TimeInterval) {
        let dt = CGFloat(deltaTime)
        for layer in 0..<3 {
            for star in layers[layer] {
                star.position.y -= speeds[layer] * dt
                if star.position.y < -5 {
                    star.position.y = sceneSize.height + 5
                    star.position.x = CGFloat.random(in: 0...sceneSize.width)
                }
            }
        }
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
