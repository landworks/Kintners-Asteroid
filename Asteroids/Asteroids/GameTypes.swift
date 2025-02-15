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
        
        // Physics body matching triangle shape
        let physicsBody = SKPhysicsBody(polygonFrom: path)
        physicsBody.categoryBitMask = PhysicsCategory.player
        physicsBody.contactTestBitMask = PhysicsCategory.asteroid
        physicsBody.collisionBitMask = PhysicsCategory.boundary
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = false
        physicsBody.linearDamping = 0.1
        physicsBody.angularDamping = 0.3
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