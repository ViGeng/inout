//
//  inoutApp.swift
//  inout
//
//  Created by Wei GENG on 23.06.25.
//

import SwiftUI

@main
struct inoutApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
