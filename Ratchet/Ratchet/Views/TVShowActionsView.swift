struct TVShowActionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @ObservedObject var tvShow: TVShow
    
    var body: some View {
        VStack(spacing: 12) {
            Button {
                updateWatchStatus(.watching)
                dismiss()
            } label: {
                Label("Start Watching", systemImage: "play.circle")
            }
            .padding()
            
            Button {
                updateWatchStatus(.watched)
                dismiss()
            } label: {
                Label("Mark as Watched", systemImage: "checkmark.circle")
            }
            .padding()
            
            Button {
                updateWatchStatus(.onHold)
                dismiss()
            } label: {
                Label("Put on Hold", systemImage: "pause.circle")
            }
            .padding()
            
            Button {
                updateWatchStatus(.dropped)
                dismiss()
            } label: {
                Label("Drop Show", systemImage: "xmark.circle")
            }
            .padding()
            
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            .padding()
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
        .shadow(radius: 4)
        .frame(maxWidth: 300)
    }
    
    private func updateWatchStatus(_ status: WatchStatus) {
        tvShow.watchStatus = status.rawValue
        
        switch status {
        case .watching:
            tvShow.isWatching = true
            tvShow.isWatched = false
        case .watched:
            tvShow.isWatched = true
            tvShow.isWatching = false
        case .onHold, .dropped, .notInWatchlist:
            tvShow.isWatching = false
            tvShow.isWatched = false
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
} 