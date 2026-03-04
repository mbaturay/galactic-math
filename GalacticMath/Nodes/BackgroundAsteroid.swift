import SpriteKit

final class BackgroundAsteroid: SKNode {

    static func spawn(in sceneSize: CGSize, startY: CGFloat? = nil) -> BackgroundAsteroid {
        let asteroid = BackgroundAsteroid()

        let radius = CGFloat.random(in: 8...25)
        let vertexCount = Int.random(in: 6...8)
        let path = CGMutablePath()

        for i in 0..<vertexCount {
            let angle = (CGFloat(i) / CGFloat(vertexCount)) * .pi * 2
            let r = radius * CGFloat.random(in: 0.7...1.0)
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()

        let body = SKShapeNode(path: path)
        body.fillColor = SKColor(white: 0.2, alpha: 1.0)
        body.strokeColor = SKColor(white: 0.35, alpha: 0.5)
        body.lineWidth = 0.8
        asteroid.addChild(body)

        asteroid.alpha = CGFloat.random(in: 0.15...0.30)
        asteroid.zPosition = -5

        // Position
        let x = CGFloat.random(in: 0...sceneSize.width)
        let y = startY ?? sceneSize.height + radius + CGFloat.random(in: 0...100)
        asteroid.position = CGPoint(x: x, y: y)

        // Slow rotation
        let rotDuration = TimeInterval.random(in: 15...30)
        let direction: CGFloat = Bool.random() ? 1 : -1
        body.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2 * direction, duration: rotDuration)))

        // Drift downward with slight horizontal movement
        let driftSpeed = CGFloat.random(in: 10...25)
        let hDrift = CGFloat.random(in: -5...5)
        let drift = SKAction.moveBy(x: hDrift, y: -driftSpeed, duration: 1.0)
        asteroid.run(SKAction.repeatForever(drift), withKey: "drift")

        return asteroid
    }

    var isOffScreen: Bool {
        position.y < -50
    }
}
