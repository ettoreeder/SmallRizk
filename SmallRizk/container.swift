import SwiftUI
import Charts // Framework for plotting
import UserNotifications
import Foundation

class Variables: ObservableObject {
    static let shared = Variables() // Singleton for global access

    @Published var prices: [(Date, Double)] = []
    @Published var selectedInterval: Int = 60
    @Published var regimeName: String = "No Regime"
    @Published var regimeNameOld: String = "No Regime"
    @Published var regimeChange: Bool = false
    @Published var regimeDescription: String = "No Input Data."
    @Published var isBGFetchEnabled:Bool = false
    @Published var transitionPoints: [(String, (Date, Double))] = []
    //RegimeClassification.shared.get_transition_points_for_plot(prices: prices)
    @Published var lastPrice: (Date, Double) = (Date(), 0.0)
    @Published var highestPrice: (Date, Double) = (Date(), 0.0)
    @Published var lowestPrice: (Date, Double) = (Date(), 0.0)
}
