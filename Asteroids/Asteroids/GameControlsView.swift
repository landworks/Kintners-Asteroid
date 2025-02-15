import SwiftUI

struct GameControlsView: View {
    let onLeft: () -> Void
    let onRight: () -> Void
    let onThrust: () -> Void
    
    var body: some View {
        HStack {
            // Left rotation button
            Button(action: onLeft) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            .padding()
            
            Spacer()
            
            // Thrust button
            Button(action: onThrust) {
                Image(systemName: "arrow.up")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            .padding()
            
            Spacer()
            
            // Right rotation button
            Button(action: onRight) {
                Image(systemName: "arrow.clockwise")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .padding()
    }
} 