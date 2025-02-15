import SpriteKit

class Player: SKSpriteNode {
    // MARK: - Properties
    private let thrustSpeed: CGFloat = 40
    private let rotationSpeed: CGFloat = 3.0
    private var velocity: CGVector = .zero
    
    // MARK: - Initialization
    init() {
        // Temporary: Use a triangle shape instead of an image
        super.init(texture: nil, color: .clear, size: CGSize(width: 20, height: 20))
        
        // Create a triangle path
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -10, y: -10))
        path.addLine(to: CGPoint(x: 10, y: 0))
        path.addLine(to: CGPoint(x: -10, y: 10))
        path.closeSubpath()
        
        let shape = SKShapeNode(path: path)
        shape.strokeColor = .white
        shape.fillColor = .white
        shape.lineWidth = 2
        addChild(shape)
        
        print("Player: Initialized")
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: 10)
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.contactTestBitMask = PhysicsCategory.asteroid
        physicsBody?.collisionBitMask = PhysicsCategory.boundary
        physicsBody?.isDynamic = true
        physicsBody?.linearDamping = 0.5
        physicsBody?.angularDamping = 0.5
        physicsBody?.restitution = 0.5
        physicsBody?.mass = 0.1
    }
    
    // MARK: - Actions
    func thrust() {
        print("Player: Thrust called")
        let angle = zRotation
        let vector = CGVector(dx: cos(angle) * thrustSpeed,
                            dy: sin(angle) * thrustSpeed)
        physicsBody?.applyForce(vector)
    }
    
    func rotate(direction: RotationDirection) {
        print("Player: Rotate called with direction: \(direction)")
        let rotation = direction == .left ? rotationSpeed : -rotationSpeed
        zRotation += rotation
    }
} 