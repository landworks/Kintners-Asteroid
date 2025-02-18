import SpriteKit

protocol HelpScreenProvider: SKScene {
    var helpOverlay: SKNode? { get set }
}

extension HelpScreenProvider {
    // Default implementation
    func shouldUseOpaqueBackground() -> Bool {
        return false
    }
    
    func showHelpScreen() {
        // Create help overlay container
        let overlay = SKNode()
        overlay.zPosition = 200  // Ensure it's above game over overlay
        addChild(overlay)
        helpOverlay = overlay
        
        // Add solid black background with absolutely no transparency
        let background = SKShapeNode(rectOf: size)
        background.fillColor = .black
        background.alpha = 1.0  // Ensure full opacity
        background.strokeColor = .clear
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.addChild(background)
        
        // Create content container for centered alignment
        let content = SKNode()
        content.position = CGPoint(x: frame.midX, y: frame.height * 0.85)
        overlay.addChild(content)
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Welcome to"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 0)
        content.addChild(titleLabel)
        
        let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        subtitleLabel.text = "Kintner's Asteroids"
        subtitleLabel.fontSize = 40
        subtitleLabel.fontColor = .white
        subtitleLabel.position = CGPoint(x: 0, y: -50)
        content.addChild(subtitleLabel)
        
        // Tips section
        let tipsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        tipsLabel.text = "Here are some quick Tips"
        tipsLabel.fontSize = 28
        tipsLabel.fontColor = .white
        tipsLabel.position = CGPoint(x: 0, y: -120)
        content.addChild(tipsLabel)
        
        // Controls list
        let controls = [
            "> Tap to Shoot",
            "> Slide Left or Right to Turn",
            "> Slide Finger up for Thurst",
            "> Tap and Hold for Rapid Fire",
            "> Two Finger Tap and Hold for",
            "Force Shield (SHD) You Get 10",
            "> Three Finger Tap and Hold for",
            "Super Fire and Force Shield",
            "(SPR) You Get 5 of these."
        ]
        
        for (index, text) in controls.enumerated() {
            let label = SKLabelNode(fontNamed: "AvenirNext-Regular")
            label.text = text
            label.fontSize = 24
            label.fontColor = .white
            label.position = CGPoint(x: 0, y: -180 - CGFloat(index * 35))
            content.addChild(label)
        }
        
        // Footer
        let enjoyLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        enjoyLabel.text = "Enjoy and thank you for playing"
        enjoyLabel.fontSize = 24
        enjoyLabel.fontColor = .white
        enjoyLabel.position = CGPoint(x: 0, y: -500)
        content.addChild(enjoyLabel)
        
        let gameNameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameNameLabel.text = "Kintner's Asteroids"
        gameNameLabel.fontSize = 28
        gameNameLabel.fontColor = .white
        gameNameLabel.position = CGPoint(x: 0, y: -540)
        content.addChild(gameNameLabel)
        
        // Fade in animation
        overlay.alpha = 0
        overlay.run(SKAction.fadeIn(withDuration: 0.3))
    }
    
    func hideHelpScreen() {
        helpOverlay?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        helpOverlay = nil
    }
} 
