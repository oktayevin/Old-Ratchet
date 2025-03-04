import SwiftUI
import Foundation

struct WatchStatusButton: View {
    let status: WatchStatus
    let accentColor: Color
    let onStatusChange: (WatchStatus) -> Void
    
    @State private var isPressed = false
    @State private var showingMenu = false
    
    var body: some View {
        Button(action: {
            showingMenu = true
        }) {
            HStack(spacing: 8) {
                switch status {
                case .notInWatchlist:
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Add to Watchlist")
                        .font(.system(size: 14, weight: .semibold))
                    
                case .watching(let progress):
                    ZStack {
                        Circle()
                            .stroke(accentColor.opacity(0.3), lineWidth: 3)
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(accentColor, lineWidth: 3)
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(-90))
                    }
                    Text("Watching")
                        .font(.system(size: 14, weight: .semibold))
                    
                case .watched:
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                    Text("Watched")
                        .font(.system(size: 14, weight: .semibold))
                    
                case .onHold:
                    Image(systemName: "pause")
                        .font(.system(size: 14, weight: .bold))
                    Text("On Hold")
                        .font(.system(size: 14, weight: .semibold))
                    
                case .dropped:
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                    Text("Dropped")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(accentColor.opacity(0.15))
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed = pressing
            }
        }, perform: {})
        .confirmationDialog("Watch Status", isPresented: $showingMenu) {
            Button("Add to Watchlist") {
                withAnimation(.spring()) {
                    onStatusChange(.notInWatchlist)
                }
            }
            Button("Watching") {
                withAnimation(.spring()) {
                    onStatusChange(.watching(progress: 0.0))
                }
            }
            Button("Watched") {
                withAnimation(.spring()) {
                    onStatusChange(.watched)
                }
            }
            Button("On Hold") {
                withAnimation(.spring()) {
                    onStatusChange(.onHold)
                }
            }
            Button("Dropped") {
                withAnimation(.spring()) {
                    onStatusChange(.dropped)
                }
            }
        }
    }
}
