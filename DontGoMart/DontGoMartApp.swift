//
//  DontGoMartApp.swift
//  DontGoMart
//
//  Created by hyunho lee on 2023/06/15.
//

import SwiftUI

@main
struct DontGoMartApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    tasks.append(contentsOf: generateSundayTasks(forYear: 2024))
                    tasks.append(contentsOf: costcoTasks)
                }
        }
    }
}
