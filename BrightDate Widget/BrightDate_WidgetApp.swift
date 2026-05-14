//
//  BrightDate_WidgetApp.swift
//  BrightDate Widget
//
//  Created by Jessica Mulein on 5/13/26.
//

import SwiftUI
import CoreData

@main
struct BrightDate_WidgetApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
