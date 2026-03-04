import SpriteKit

final class StarRatingNode: SKNode {
    func setup(rating: Int, size: CGFloat = 40) {
        removeAllChildren()

        let spacing: CGFloat = size * 1.3

        for i in 0..<3 {
            let star = SKLabelNode(text: "⭐")
            star.fontSize = size
            star.verticalAlignmentMode = .center
            star.horizontalAlignmentMode = .center
            star.position = CGPoint(x: CGFloat(i - 1) * spacing, y: 0)

            if i < rating {
                star.alpha = 1.0
                star.setScale(0.1)
                let delay = SKAction.wait(forDuration: Double(i) * 0.2)
                let scaleUp = SKAction.scale(to: 1.3, duration: 0.2)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                star.run(SKAction.sequence([delay, scaleUp, scaleDown]))
            } else {
                star.alpha = 0.25
            }

            addChild(star)
        }
    }
}
