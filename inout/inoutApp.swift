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

    init() {
        SubscriptionManager.shared.generateTransactions()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
