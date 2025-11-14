import Foundation
import UserNotifications
import BackgroundTasks

class BackgroundTasks {
    static let shared = BackgroundTasks()

    func scheduleDataFetch() {
        let request = BGAppRefreshTaskRequest(identifier: "EE.SmallRizk.fetchStockData")
        request.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(Variables.shared.selectedInterval))
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled data fetch")
        } catch {
            print("Failed to schedule background fetch: \(error.localizedDescription)")
        }
    }

    //func fetchAndUpdateData() {
    //    DispatchQueue.main.async {
    //        StockDataFetcher.fetchStockData()
    //    }
    //}
    
    func cancelBackgroundTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "EE.SmallRizk.fetchStockData")
        print("❌ Background task cancelled")
    }

}
