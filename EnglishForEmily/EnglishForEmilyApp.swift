import SwiftUI

@main
struct EnglishForEmilyApp: App {
    @StateObject private var store = WordStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
