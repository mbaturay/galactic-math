import SpriteKit

// MARK: - Configuration

struct ShipBankingConfig {
    /// Bank angles per lane index (in degrees). Mapped by position: far-left to far-right.
    let bankAnglesDeg: [CGFloat]

    /// Duration of the lane-switch animation.
    let moveDuration: TimeInterval

    /// Optional scale pulse intensity (0 = disabled). Typical value: 0.03–0.06.
    let scalePulse: CGFloat

    /// Rotation overshoot factor (0 = disabled). Adds a subtle overshoot then settle.
    let overshootFactor: CGFloat

    // MARK: - Presets

    /// Default 5-lane banking: -30, -15, 0, +15, +30
    static let fiveLane = ShipBankingConfig(
        bankAnglesDeg: [-15, -5, 0, 5, 15],
        moveDuration: 0.14,
        scalePulse: 0.04,
        overshootFactor: 0.12
    )

    /// 3-lane banking: -20, 0, +20
    static let threeLane = ShipBankingConfig(
        bankAnglesDeg: [-10, 0, 10],
        moveDuration: 0.14,
        scalePulse: 0.04,
        overshootFactor: 0.12
    )

    /// Auto-generate evenly spaced bank angles for any lane count.
    /// maxAngle is the angle at the outermost lanes (in degrees).
    static func symmetric(laneCount: Int, maxAngleDeg: CGFloat = 30, moveDuration: TimeInterval = 0.14) -> ShipBankingConfig {
        guard laneCount > 1 else {
            return ShipBankingConfig(bankAnglesDeg: [0], moveDuration: moveDuration, scalePulse: 0.04, overshootFactor: 0.12)
        }
        let step = (2 * maxAngleDeg) / CGFloat(laneCount - 1)
        let angles = (0..<laneCount).map { -maxAngleDeg + step * CGFloat($0) }
        return ShipBankingConfig(bankAnglesDeg: angles, moveDuration: moveDuration, scalePulse: 0.04, overshootFactor: 0.12)
    }

    // MARK: - Helpers

    func bankAngle(for laneIndex: Int) -> CGFloat {
        guard laneIndex >= 0 && laneIndex < bankAnglesDeg.count else { return 0 }
        return bankAnglesDeg[laneIndex] * .pi / 180
    }
}

// MARK: - SKNode Extension

private let kShipBankingMoveKey = "shipBanking_move"

extension SKNode {

    /// Move this node to the given lane with banking rotation and optional polish.
    ///
    /// - Parameters:
    ///   - laneIndex: Target lane (0-based).
    ///   - xPosition: The screen x-coordinate for that lane.
    ///   - config: Banking configuration (angles, timing, polish).
    ///   - baseAngle: Additional rotation offset (e.g. beam perspective angle). Default 0.
    func moveToLane(_ laneIndex: Int, xPosition: CGFloat, config: ShipBankingConfig, baseAngle: CGFloat = 0) {
        guard laneIndex >= 0 && laneIndex < config.bankAnglesDeg.count else { return }

        // Cancel any in-flight banking animation to prevent stacking
        removeAction(forKey: kShipBankingMoveKey)

        let targetAngle = config.bankAngle(for: laneIndex) + baseAngle
        let duration = config.moveDuration

        // -- Horizontal slide --
        let slide = SKAction.moveTo(x: xPosition, duration: duration)
        slide.timingMode = .easeOut

        // -- Rotation with optional overshoot --
        let rotation: SKAction
        if config.overshootFactor > 0 {
            let overshootAngle = targetAngle + (targetAngle - zRotation) * config.overshootFactor
            let bankTo = SKAction.rotate(toAngle: overshootAngle, duration: duration * 0.55, shortestUnitArc: true)
            bankTo.timingMode = .easeOut
            let settle = SKAction.rotate(toAngle: targetAngle, duration: duration * 0.45, shortestUnitArc: true)
            settle.timingMode = .easeInEaseOut
            rotation = SKAction.sequence([bankTo, settle])
        } else {
            let bankTo = SKAction.rotate(toAngle: targetAngle, duration: duration, shortestUnitArc: true)
            bankTo.timingMode = .easeOut
            rotation = bankTo
        }

        // -- Optional scale pulse --
        var actions: [SKAction] = [slide, rotation]
        if config.scalePulse > 0 {
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.0 + config.scalePulse, duration: duration * 0.4),
                SKAction.scale(to: 1.0, duration: duration * 0.6)
            ])
            pulse.timingMode = .easeOut
            actions.append(pulse)
        }

        run(SKAction.group(actions), withKey: kShipBankingMoveKey)
    }

    /// Instantly set the banking angle for a lane (no animation). Useful for initial placement.
    func setBankAngle(for laneIndex: Int, config: ShipBankingConfig, baseAngle: CGFloat = 0) {
        zRotation = config.bankAngle(for: laneIndex) + baseAngle
    }
}
