import SpriteKit

final class TouchControlsNode: SKNode {
    private var fireButton: SKShapeNode!
    private var torpedoButton: SKShapeNode!

    private var sceneSize: CGSize = .zero
    private var ageGroup: AgeGroup = .cadet

    var onMoveLeft: (() -> Void)?
    var onMoveRight: (() -> Void)?
    var onFire: (() -> Void)?
    var onTorpedo: (() -> Void)?
    var onBackTap: (() -> Void)?

    func setup(size: CGSize, ageGroup: AgeGroup) {
        self.sceneSize = size
        self.ageGroup = ageGroup
        isUserInteractionEnabled = true
        removeAllChildren()
        zPosition = 500

        // Invisible full-screen hit area so this node receives all touches
        let hitArea = SKShapeNode(rectOf: size)
        hitArea.position = CGPoint(x: size.width / 2, y: size.height / 2)
        hitArea.fillColor = .clear
        hitArea.strokeColor = .clear
        addChild(hitArea)

        let buttonSize: CGFloat = ageGroup == .cadet ? 60 : 52
        let buttonAlpha: CGFloat = 0.25
        let bottomY: CGFloat = buttonSize / 2 + 12
        let centerX = size.width / 2
        let actionSpacing: CGFloat = buttonSize * 0.7

        // FIRE button - bottom center-left
        fireButton = SKShapeNode(circleOfRadius: buttonSize / 2)
        fireButton.position = CGPoint(x: centerX - actionSpacing, y: bottomY)
        fireButton.fillColor = ageGroup.primaryColor.withAlphaComponent(buttonAlpha)
        fireButton.strokeColor = ageGroup.primaryColor.withAlphaComponent(0.6)
        fireButton.lineWidth = 2.0
        fireButton.name = "fireButton"
        addChild(fireButton)

        let fireLabel = SKLabelNode(text: "FIRE")
        fireLabel.fontName = "AvenirNext-Bold"
        fireLabel.fontSize = ageGroup == .cadet ? 13 : 11
        fireLabel.fontColor = .white
        fireLabel.verticalAlignmentMode = .center
        fireButton.addChild(fireLabel)

        // TORP button - bottom center-right
        torpedoButton = SKShapeNode(circleOfRadius: buttonSize / 2)
        torpedoButton.position = CGPoint(x: centerX + actionSpacing, y: bottomY)
        torpedoButton.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: buttonAlpha)
        torpedoButton.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.6)
        torpedoButton.lineWidth = 2.0
        torpedoButton.name = "torpedoButton"
        addChild(torpedoButton)

        let torpLabel = SKLabelNode(text: "TORP")
        torpLabel.fontName = "AvenirNext-Bold"
        torpLabel.fontSize = ageGroup == .cadet ? 13 : 11
        torpLabel.fontColor = .white
        torpLabel.verticalAlignmentMode = .center
        torpedoButton.addChild(torpLabel)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            handleTouch(touch)
        }
    }

    private func handleTouch(_ touch: UITouch) {
        let location = touch.location(in: self)

        // Back button area — top-left corner
        if location.x < 60 && location.y > sceneSize.height - 100 {
            onBackTap?()
            return
        }

        let buttonRadius: CGFloat = ageGroup == .cadet ? 38 : 32

        // FIRE button — check first so it takes priority over tap zones
        let fireDistance = hypot(location.x - fireButton.position.x, location.y - fireButton.position.y)
        if fireDistance < buttonRadius {
            pressButton(fireButton)
            onFire?()
            return
        }

        // TORP button
        let torpDistance = hypot(location.x - torpedoButton.position.x, location.y - torpedoButton.position.y)
        if torpDistance < buttonRadius {
            pressButton(torpedoButton)
            onTorpedo?()
            return
        }

        // Left/right tap zones — entire screen halves
        let midX = sceneSize.width / 2
        if location.x < midX {
            onMoveLeft?()
        } else {
            onMoveRight?()
        }
    }

    private func pressButton(_ button: SKShapeNode) {
        let press = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.9, duration: 0.05),
                SKAction.fadeAlpha(to: 0.8, duration: 0.05)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.1),
                SKAction.fadeAlpha(to: 1.0, duration: 0.1)
            ])
        ])
        button.run(press)
    }
}
