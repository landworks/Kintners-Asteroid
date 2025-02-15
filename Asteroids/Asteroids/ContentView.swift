//
//  ContentView.swift
//  asteriods
//
//  Created by Michael Kintner on 1/6/25.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var isGameStarted = false
    
    var body: some View {
        if isGameStarted {
            GameView()
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
                .statusBar(hidden: true)
        } else {
            SplashView(isGameStarted: $isGameStarted)
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
                .statusBar(hidden: true)
        }
    }
}

#Preview {
    ContentView()
}
