import SpriteKit

final class StarRatingNode: SKNode {
    func setup(rating: Int, size: CGFloat = 40) {
        removeAllChildren()

        let spacing: CGFloat = size * 1.3

        for i in 0..<3 {
            let star: SKNode
            if i < rating {
                star = createFilledStar(size: size)
            } else {
                star = createEmptyStar(size: size)
            }
            star.position = CGPoint(x: CGFloat(i - 1) * spacing, y: 0)
            addChild(star)

            if i < rating {
                let delay = SKAction.wait(forDuration: Double(i) * 0.2)
                let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                star.setScale(0.1)
                star.run(SKAction.sequence([delay, SKAction.scale(to: 1.3, duration: 0.2), scaleDown]))
                _ = scaleUp
            }
        }
    }

    private func createFilledStar(size: CGFloat) -> SKNode {
        let star = SKShapeNode(path: starPath(size: size))
        star.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        star.strokeColor = SKColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1.0)
        star.lineWidth = 2.0
        star.glowWidth = 3.0
        return star
    }

    private func createEmptyStar(size: CGFloat) -> SKNode {
        let star = SKShapeNode(path: starPath(size: size))
        star.fillColor = SKColor(white: 0.3, alpha: 0.5)
        star.strokeColor = SKColor(white: 0.5, alpha: 0.5)
        star.lineWidth = 1.5
        return star
    }

    private func starPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let points = 5
        let outerRadius = size / 2
        let innerRadius = outerRadius * 0.4

        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let x = cos(angle) * radius
            let y = sin(angle) * radius

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}
