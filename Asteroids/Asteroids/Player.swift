import SpriteKit

class Player: SKNode {
    override init() {
        super.init()
        
        let playerShape = SKShapeNode(circleOfRadius: 15)
        playerShape.strokeColor = .white
        playerShape.lineWidth = 2
        addChild(playerShape)
        
        let physicsBody = SKPhysicsBody(circleOfRadius: 15)
        physicsBody.categoryBitMask = PhysicsCategory.player
        physicsBody.contactTestBitMask = PhysicsCategory.asteroid
        physicsBody.collisionBitMask = PhysicsCategory.none
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = false
        physicsBody.linearDamping = 0.5
        physicsBody.angularDamping = 0.5
        self.physicsBody = physicsBody
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
} 