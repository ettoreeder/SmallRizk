import SwiftUI
import Charts // Framework for plotting
import UserNotifications
import Foundation
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static let shared = AppDelegate()
    
    static var orientationLock = UIInterfaceOrientationMask.portrait // Lock to portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        requestNotificationPermission()
        
        // Register background task
        registerBackgroundTask()
        
        // Set delegate to handle foreground notifications
        UNUserNotificationCenter.current().delegate = self
        
        StockDataFetcher.shared.fetchStockData()
        BackgroundTasks.shared.cancelBackgroundTask()
        
        return true
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted!")
            } else {
                print("❌ Notification permission denied!")
            }
        }
    }
    
    // Register the background task for stock data fetching
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "EE.SmallRizk.fetchStockData", using: nil) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
        print("✅ Registered Background Task!")
    }
    
    // Handle background task for fetching stock data
    func handleBackgroundTask(task: BGAppRefreshTask) {
        StockDataFetcher.shared.fetchStockData(usePolygon: true) {
            print("Data fetching is complete! Sending Notification")
            BackgroundNotifications.shared.sendSingleFetchNotification(changed: Variables.shared.regimeChange)
            print("Notification sent.")
        }
        /*StockDataFetcher.shared.fetchStockData{
            /*print(Variables.shared.regimeName,Variables.shared.regimeNameOld,Variables.shared.regimeChange)
            let a = 1
            print(a)
            DispatchQueue.main.async {
                Variables.shared.highestPrice = Variables.shared.prices.max(by: { $0.1 < $1.1 })!
                Variables.shared.lowestPrice = Variables.shared.prices.min(by: { $0.1 < $1.1 })!
                Variables.shared.lastPrice = Variables.shared.prices.last!
                RegimeClassification.shared.get_transition_points_for_plot()
                RegimeClassification.shared.getRegimedescription()
                
                print(Variables.shared.regimeName,Variables.shared.regimeNameOld,Variables.shared.regimeChange)
                BackgroundNotifications.shared.sendSingleFetchNotification(changed: Variables.shared.regimeChange)
            }*/
            BackgroundNotifications.shared.sendSingleFetchNotification(changed: Variables.shared.regimeChange)
        }*/
        print("✅ Background Task Executed!")
        scheduleNextFetch() // Schedule next background task
        
        //StockDataFetcher.fetchStockData()
        print("FUNCTION EXECUTED IN THE BACKGROUND")
        }


    func forTesting(completion: (() -> Void)? = nil){
        DispatchQueue.main.async {
            Variables.shared.highestPrice = Variables.shared.prices.max(by: { $0.1 < $1.1 })!
            Variables.shared.lowestPrice = Variables.shared.prices.min(by: { $0.1 < $1.1 })!
            Variables.shared.lastPrice = Variables.shared.prices.last!
            RegimeClassification.shared.get_transition_points_for_plot()
            RegimeClassification.shared.getRegimedescription()
        }
        completion?()
    }
    
    // Schedule the next background refresh
    func scheduleNextFetch() {
        let interval = Double(Variables.shared.selectedInterval)
        let request = BGAppRefreshTaskRequest(identifier: "EE.SmallRizk.fetchStockData")
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Scheduled next background fetch in \(interval) seconds.")
        } catch {
            print("❌ Failed to schedule background fetch: \(error.localizedDescription)")
        }
    }
    
    // Ensure notifications appear even when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
