import SwiftUI
import SpriteKit

struct SplashView: View {
    @Binding var isGameStarted: Bool
    
    @State private var splashScene: SplashScene = {
        let screenSize = UIScreen.main.bounds.size
        let scene = SplashScene(size: screenSize)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .black
        return scene
    }()
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: splashScene, preferredFramesPerSecond: 60)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()
                .background(Color.black)
                .onAppear {
                    splashScene.onStartGame = {
                        isGameStarted = true
                    }
                }
        }
    }
} 