//
//  PenNote_EnglishApp.swift
//  PenNote English
//
//  Created by jolin on 2025/3/10.
//

import SwiftUI

@main
struct PenNote_EnglishApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
