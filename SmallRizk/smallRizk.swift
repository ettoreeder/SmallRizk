//
//  SmallRizk.swift
//  SmallRizk
//
//  Created by Ettore Eder on 22.12.24.
//

import SwiftUI
import UserNotifications
import BackgroundTasks

@main
struct MyApp: App {  // Entry point
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
