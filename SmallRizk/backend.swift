//
//  backend.swift
//  SmallRizk
//
//  Created by Ettore Eder on 07.02.25.
//

import SwiftUI
import Charts // Framework for plotting
import UserNotifications
import Foundation

class RegimeClassification {
    static let shared = RegimeClassification()
    
    func getRegimedescription() {
        let input = Variables.shared.regimeName
        switch input {
        case "A":
            Variables.shared.regimeDescription = "Regime \(input): 80% in ETFs and 20% in cash."
        case "B":
            Variables.shared.regimeDescription = "Regime \(input): 90% in ETFs and 10% in cash."
        case "C":
            Variables.shared.regimeDescription = "Regime \(input): 100% in ETFs and 0% in cash."
        default:
            Variables.shared.regimeDescription = "No input Data."
        }
    }
    
    func loopDecision(givenPrice: (Date, Double), percentage: Double) -> (decision: Bool, (date: Date, price: Double)) {
        let filteredPrices = Variables.shared.prices.filter { $0.0 >= givenPrice.0 }
        for price in filteredPrices {
            let percentageChange = (price.1 / givenPrice.1 - 1) * 100
            if percentage < 0 {
                if percentageChange <= percentage {
                    return (true, (price.0, price.1))
                }
            } else if percentage > 0 {
                if percentageChange >= percentage {
                    return (true, (price.0, price.1))
                }
            }
        }
        return (false, (givenPrice.0, givenPrice.1))
    }
    
    func determineNewState() -> (String, (Date, Double)) {
        // Regime-specific logic
        Variables.shared.regimeChange = false
        switch Variables.shared.regimeName {
        case "A":
            let decision_to_B = loopDecision(givenPrice: (Variables.shared.lastPrice.0, Variables.shared.highestPrice.1), percentage: -20)
            if decision_to_B.0 {
                Variables.shared.regimeChange = true
                Variables.shared.regimeNameOld = "A"
                return ("B", (decision_to_B.1.0, decision_to_B.1.1))
            } else {
                return (Variables.shared.regimeName, Variables.shared.lastPrice)
            }
        case "B":
            let decision_to_C = loopDecision(givenPrice: Variables.shared.lastPrice, percentage: -25)
            let decision_to_A = loopDecision(givenPrice: Variables.shared.lastPrice, percentage: 25)
            if decision_to_C.0 {
                Variables.shared.regimeChange = true
                Variables.shared.regimeNameOld = "B"
                return ("C", (decision_to_C.1.0, decision_to_C.1.1))
            }
            else if decision_to_A.0 {
                Variables.shared.regimeChange = true
                Variables.shared.regimeNameOld = "B"
                return ("A", (decision_to_A.1.0, decision_to_A.1.1))
            }
            else {
                return (Variables.shared.regimeName, Variables.shared.lastPrice)
            }
        case "C":
            let decision_to_B = loopDecision(givenPrice: (Variables.shared.lastPrice.0, Variables.shared.lowestPrice.1), percentage: 50)
            if decision_to_B.0 {
                Variables.shared.regimeChange = true
                Variables.shared.regimeNameOld = "C"
                return ("B", (decision_to_B.1.0, decision_to_B.1.1))
            } else {
                return (Variables.shared.regimeName, Variables.shared.lastPrice)
            }
        default:
            // If no valid regime, return current state
            return (Variables.shared.regimeName, Variables.shared.lastPrice)
        }
    }

    func low_or_high() -> (String, (Date, Double)){
        if Variables.shared.lowestPrice.0 > Variables.shared.highestPrice.0 {
            return ("C", Variables.shared.lowestPrice)
        }
        else if Variables.shared.lowestPrice.0 < Variables.shared.highestPrice.0 {
            return ("A", Variables.shared.highestPrice)
        }
        return ("No Regime", (Date(), 0.0))
    }
    
    func create_transition_list() -> [(String, (Date, Double))] {
        let (start_regime, start_price) = low_or_high()
        
        Variables.shared.lastPrice = start_price
        Variables.shared.regimeName = start_regime
        
        let (new_regime, new_price) = determineNewState()
        var results = [(new_regime, new_price)]
        while new_regime != start_regime && results.count < 50 {
            
            Variables.shared.lastPrice = new_price
            Variables.shared.regimeName = new_regime
            
            let (new_regime, new_price) = determineNewState()
            results.append((new_regime, new_price))
        }
        return results
    }
    
    func get_transition_points_for_plot(){
        //let highest = prices.max(by: { $0.1 < $1.1 })
        //let lowest = prices.min(by: { $0.1 < $1.1 })
        //let current = prices.last
        
        if Variables.shared.highestPrice.0==Variables.shared.lastPrice.0 {
            Variables.shared.transitionPoints = [("A", Variables.shared.highestPrice)]
        }
        else if Variables.shared.lowestPrice.0==Variables.shared.lastPrice.0 {
            Variables.shared.transitionPoints = [("C", Variables.shared.lowestPrice)]
        }
        else {
            let listoftransitions = create_transition_list()
            Variables.shared.transitionPoints = listoftransitions
        }
    }    
}

class StockDataFetcher {
    static let shared = StockDataFetcher()
    
    private let alphaVantageKey = "TS2RRUC8XE1BN5ZI"
    private let polygonKey = "VgoEnGP37W554lpr7pF47vNA8Q0TXUGN"
    
    func fetchStockData(usePolygon: Bool = false, completion: (() -> Void)? = nil) {
        print("FETCHING STOCK DATA... (Using \(usePolygon ? "Polygon" : "Alpha Vantage"))")

        let urlString: String
        if usePolygon {
            urlString = "https://api.polygon.io/v2/aggs/ticker/SPY/range/1/day/2000-01-01/2025-12-31?adjusted=true&sort=asc&apiKey=VgoEnGP37W554lpr7pF47vNA8Q0TXUGN"
        } else {
            urlString = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=SPY&apikey=TS2RRUC8XE1BN5ZI&outputsize=full"
        }

        guard let url = URL(string: urlString) else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        
                        // Check for rate limit error in Alpha Vantage
                        if !usePolygon, json["Information"] != nil {
                            print("Alpha Vantage API Limit Reached. Trying Polygon API...")
                            self.fetchStockData(usePolygon: true, completion: completion) // Retry with Polygon API
                            return
                        }
                        
                        var tempPrices: [(Date, Double)] = []
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"

                        // 🔹 Calculate the date 19 years ago from today
                        let a = Calendar.current.date(byAdding: .year, value: -3, to: Date())!
                        let b = Calendar.current.date(byAdding: .year, value: +3, to: a)!

                        if usePolygon, let results = json["results"] as? [[String: Any]] {
                            for entry in results {
                                if let closePrice = entry["c"] as? Double,
                                   let timestamp = entry["t"] as? TimeInterval {
                                    let date = Date(timeIntervalSince1970: timestamp / 1000)
                                    
                                    // ✅ Only add data from the last 19 years
                                    if date >= a, date <= b {
                                        tempPrices.append((date, closePrice))
                                    }
                                }
                            }
                        } else if let timeSeries = json["Time Series (Daily)"] as? [String: [String: String]] {
                            for (dateString, values) in timeSeries {
                                if let date = dateFormatter.date(from: dateString),
                                   let closePrice = values["4. close"],
                                   let price = Double(closePrice) {
                                    
                                    // ✅ Only add data from the last 19 years
                                    if date >= a, date <= b {
                                        tempPrices.append((date, price))
                                    }
                                }
                            }
                        }
                        
                        tempPrices.sort { $0.0 < $1.0 }
                        //tempPrices[tempPrices.count - 1].1 = 400
                        DispatchQueue.main.async {
                            Variables.shared.prices = tempPrices
                            Variables.shared.highestPrice = tempPrices.max(by: { $0.1 < $1.1 })!
                            Variables.shared.lowestPrice = tempPrices.min(by: { $0.1 < $1.1 })!
                            Variables.shared.lastPrice = tempPrices.last!
                            RegimeClassification.shared.get_transition_points_for_plot()
                            RegimeClassification.shared.getRegimedescription()
                            
                            // ✅ Call the completion handler after data fetching is complete
                            completion?()
                        }
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            } else if let error = error {
                print("Request failed: \(error)")
            }
        }.resume()
    }
}
