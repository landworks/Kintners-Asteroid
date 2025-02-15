import SwiftUI
import SpriteKit

struct GameView: View {
    private let gameScene: GameScene = {
        let screenSize = UIScreen.main.bounds.size
        let scene = GameScene(size: screenSize)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .black
        return scene
    }()
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: gameScene, preferredFramesPerSecond: 60)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()
                .background(Color.black)
        }
        .onAppear {
            print("GameView appeared")
        }
    }
}

#Preview {
    GameView()
} 