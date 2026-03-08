import SpriteKit

final class ParallaxBackgroundNode: SKNode {

    private var bg: SKSpriteNode!

    func setup(size: CGSize) {
        bg = SKSpriteNode(color: .black, size: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -110
        addChild(bg)
    }

    func update(shipX: CGFloat, sceneWidth: CGFloat, currentTime: TimeInterval) {}
    func triggerExplosion(at position: CGPoint) {}
    func triggerBankImpulse(direction: Int) {}
    func triggerShockwave(at position: CGPoint, intensity: CGFloat) {}
}
