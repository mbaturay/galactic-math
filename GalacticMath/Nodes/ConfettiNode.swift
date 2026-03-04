import SpriteKit

final class ConfettiNode: SKNode {
    func burst(in size: CGSize) {
        let colors: [SKColor] = [
            .red, .green, .blue, .yellow, .cyan, .magenta, .orange,
            SKColor(red: 1, green: 0.5, blue: 0.8, alpha: 1),
            SKColor(red: 0.5, green: 1, blue: 0.5, alpha: 1)
        ]

        for _ in 0..<60 {
            let confetti = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 3...6)), cornerRadius: 1)
            confetti.fillColor = colors.randomElement()!
            confetti.strokeColor = .clear
            confetti.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: size.height + 20
            )
            confetti.zPosition = 200
            addChild(confetti)

            let fallDuration = Double.random(in: 1.5...3.0)
            let endX = confetti.position.x + CGFloat.random(in: -100...100)
            let fall = SKAction.move(to: CGPoint(x: endX, y: -20), duration: fallDuration)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -6...6), duration: fallDuration)
            let fade = SKAction.fadeOut(withDuration: fallDuration * 0.8)
            let group = SKAction.group([fall, rotate, fade])

            confetti.run(SKAction.sequence([
                SKAction.wait(forDuration: Double.random(in: 0...0.5)),
                group,
                SKAction.removeFromParent()
            ]))
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: 4.0),
            SKAction.removeFromParent()
        ]))
    }
}
