import SwiftUI

@main
struct FitPetWatchApp: App {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(viewModel)
        }
    }
}
