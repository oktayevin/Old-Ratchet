//
//  RatchetApp.swift
//  Ratchet
//
//  Created by Oktay Evin on 2/25/25.
//

import SwiftUI

@main
struct RatchetApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // Set appearance to match modern iOS design
                    UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.label]
                    UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.label]
                }
        }
    }
}
