//
//  exerciseModelingApp.swift
//  exerciseModeling
//
//  Created by Jacob Snapp on 8/4/24.
//

import SwiftUI

@main
struct exerciseModelingApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
