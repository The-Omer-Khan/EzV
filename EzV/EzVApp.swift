//
//  EzVApp.swift
//  EzV
//
//  Created by Omer Khan on 23/08/2026.
//

import SwiftUI


@main
struct EzVApp: App {
    @StateObject private var engine = ConversionEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .frame(minWidth: 720, minHeight: 640)
        }
        .windowResizability(.contentMinSize)
    }
}
