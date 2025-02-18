import Foundation
import SpriteKit

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let asteroid: UInt32 = 0b10
    static let bullet: UInt32 = 0b100
    static let boundary: UInt32 = 0b1000
}

class Player: SKNode {
    private var thrustFlame: SKShapeNode?
    
    override init() {
        super.init()
        
        // Create triangle ship shape
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 15))     // Nose (top)
        path.addLine(to: CGPoint(x: -10, y: -10))  // Left
        path.addLine(to: CGPoint(x: 10, y: -10))   // Right
        path.closeSubpath()
        
        let playerShape = SKShapeNode(path: path)
        playerShape.strokeColor = .white
        playerShape.lineWidth = 2
        playerShape.fillColor = .clear
        addChild(playerShape)
        
        // Add thrust flame (hidden by default)
        let flamePath = CGMutablePath()
        flamePath.move(to: CGPoint(x: 0, y: -10))  // Top of flame
        flamePath.addLine(to: CGPoint(x: -5, y: -20))  // Left point
        flamePath.addLine(to: CGPoint(x: 0, y: -25))   // Bottom point
        flamePath.addLine(to: CGPoint(x: 5, y: -20))   // Right point
        flamePath.closeSubpath()
        
        let flame = SKShapeNode(path: flamePath)
        flame.strokeColor = .orange
        flame.fillColor = .yellow
        flame.alpha = 0  // Start hidden
        addChild(flame)
        thrustFlame = flame
        
        // Physics body matching triangle shape
        let physicsBody = SKPhysicsBody(polygonFrom: path)
        physicsBody.categoryBitMask = PhysicsCategory.player
        physicsBody.contactTestBitMask = PhysicsCategory.asteroid
        physicsBody.collisionBitMask = PhysicsCategory.boundary
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = false
        physicsBody.linearDamping = 0.5
        physicsBody.angularDamping = 0.8
        self.physicsBody = physicsBody
    }
    
    func getNosePosition() -> CGPoint {
        let angle = zRotation + CGFloat.pi/2  // Adjust for ship's orientation
        let distance: CGFloat = 15
        return CGPoint(
            x: position.x + cos(angle) * distance,
            y: position.y + sin(angle) * distance
        )
    }
    
    func showThrust(_ active: Bool) {
        if active {
            thrustFlame?.alpha = 1.0
            
            // Add pulsing animation if not already pulsing
            if thrustFlame?.action(forKey: "pulse") == nil {
                let pulseAction = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.4, duration: 0.1),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.1)
                ])
                thrustFlame?.run(SKAction.repeatForever(pulseAction), withKey: "pulse")
            }
        } else {
            thrustFlame?.removeAction(forKey: "pulse")
            thrustFlame?.alpha = 0
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum PlayerType {
    case one
}

enum GameState {
    case ready
    case playing
    case gameOver
}