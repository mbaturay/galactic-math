import SpriteKit

final class TouchControlsNode: SKNode {
    private var actionButton: SKNode!
    private var actionBg: SKShapeNode!
    private var actionLabel: SKLabelNode!

    private var sceneSize: CGSize = .zero
    private var grade: Grade = .kindergarten
    private var isBossMode = false
    private var buttonRect: CGRect = .zero

    var onMoveLeft: (() -> Void)?
    var onMoveRight: (() -> Void)?
    var onFire: (() -> Void)?
    var onTorpedo: (() -> Void)?
    var onBackTap: (() -> Void)?
    var shipXProvider: (() -> CGFloat)?

    func setup(size: CGSize, grade: Grade) {
        self.sceneSize = size
        self.grade = grade
        isUserInteractionEnabled = true
        removeAllChildren()
        zPosition = 500

        // Invisible full-screen hit area so this node receives all touches
        let hitArea = SKShapeNode(rectOf: size)
        hitArea.position = CGPoint(x: size.width / 2, y: size.height / 2)
        hitArea.fillColor = .clear
        hitArea.strokeColor = .clear
        addChild(hitArea)

        // Full-width FIRE button at bottom
        let margin: CGFloat = 20
        let btnWidth = size.width - margin * 2
        let btnHeight: CGFloat = 70
        let btnY: CGFloat = btnHeight / 2 + 12

        buttonRect = CGRect(x: margin, y: btnY - btnHeight / 2, width: btnWidth, height: btnHeight)

        actionButton = SKNode()
        actionButton.position = CGPoint(x: size.width / 2, y: btnY)
        actionButton.zPosition = 501
        addChild(actionButton)

        actionBg = SKShapeNode(rectOf: CGSize(width: btnWidth, height: btnHeight), cornerRadius: 14)
        actionBg.fillColor = grade.primaryColor.withAlphaComponent(0.25)
        actionBg.strokeColor = grade.primaryColor.withAlphaComponent(0.6)
        actionBg.lineWidth = 2.0
        actionButton.addChild(actionBg)

        actionLabel = SKLabelNode(text: "FIRE")
        actionLabel.fontName = "AvenirNext-Bold"
        actionLabel.fontSize = grade.rawValue < 2 ? 22 : 20
        actionLabel.fontColor = .white
        actionLabel.verticalAlignmentMode = .center
        actionButton.addChild(actionLabel)
    }

    func switchToBossMode() {
        isBossMode = true
        let flash = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.actionBg.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.35)
                self?.actionBg.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.8)
                self?.actionLabel.text = "TORPEDO"
            },
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.scale(to: 1.05, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        actionButton.run(flash)
    }

    func switchToNormalMode() {
        isBossMode = false
        actionBg.fillColor = grade.primaryColor.withAlphaComponent(0.25)
        actionBg.strokeColor = grade.primaryColor.withAlphaComponent(0.6)
        actionLabel.text = "FIRE"
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

        // Check fire/torpedo button area
        if buttonRect.contains(location) {
            pressButton()
            if isBossMode {
                onTorpedo?()
            } else {
                onFire?()
            }
            return
        }

        // Determine direction: compare touch X to current ship X
        let shipX = shipXProvider?() ?? (sceneSize.width / 2)
        if location.x > shipX {
            onMoveRight?()
        } else {
            onMoveLeft?()
        }
    }

    private func pressButton() {
        let press = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.95, duration: 0.05),
                SKAction.fadeAlpha(to: 0.8, duration: 0.05)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.1),
                SKAction.fadeAlpha(to: 1.0, duration: 0.1)
            ])
        ])
        actionButton.run(press)
    }
}
