//
//  breedyApp.swift
//  breedy
//
//  Created by Álvaro García Pizarro on 27/4/26.
//

import SwiftUI
import CoreData

@main
struct breedyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
