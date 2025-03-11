import SwiftUI

@main
struct PenNote_EnglishApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                WordListView()
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}