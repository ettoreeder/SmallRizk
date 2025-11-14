
import UserNotifications

class BackgroundNotifications {
    static let shared = BackgroundNotifications()
    
    func sendSingleFetchNotification(changed: Bool) {
        //a=1//replace regimeChange with regimeName == regimeNameOld
        let content = UNMutableNotificationContent()
        var message = "No input Data."
        switch Variables.shared.regimeName {
        case "A":
            message = "80% in ETFs and 20% in cash."
        case "B":
            message = "90% in ETFs and 10% in cash."
        case "C":
            message = "100% in ETFs and 0% in cash."
        default:
            message = "No input Data."
        }
        if NetworkMonitor.shared.isConnected == false {
            content.title = "No Internet Connection!"
            message = "Please check your internet connection."
        }
        else if changed {
            content.title = "Regime has changed from \(Variables.shared.regimeName) to \(Variables.shared.regimeName)!"
        } else {
            content.title = "Still in Regime \(Variables.shared.regimeName)"
        }
        
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: "singleFetchNotification", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification Error: \(error.localizedDescription)")
            } else {
                print("✅ Notification sent successfully!")
            }
        }
    }

    func intervalLabel(_ interval: Int) -> String {
        switch interval {
        case 60: return "1 Minute"
        case 3600: return "1 Hour"
        case 86400: return "1 Day"
        case 604800: return "1 Week"
        default: return "\(interval) s"
        }
    }
}
