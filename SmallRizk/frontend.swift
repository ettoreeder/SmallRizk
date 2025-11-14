import SwiftUI
import Charts
import BackgroundTasks

struct ContentView: View {
    @State private var isBGFetchEnabledLocal = Variables.shared.isBGFetchEnabled
    @State private var selectedInterval = Variables.shared.selectedInterval
    
    @ObservedObject var variables = Variables.shared
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    let intervals = [0, 60, 120, 3600, 3660, 86400, 604800]
    var body: some View {
        VStack {
            HStack{
                Spacer()
                Image(systemName: networkMonitor.isConnected ? (networkMonitor.isWiFi ? "wifi" : "antenna.radiowaves.left.and.right") : "wifi.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(networkMonitor.isConnected ? (networkMonitor.isWiFi ? .green : .green) : .red)
                .padding()
            }
            // Notifications & Interval Picker
            HStack {
                Toggle("BG Fetch", isOn: $isBGFetchEnabledLocal)
                    .padding()
                    .onChange(of: isBGFetchEnabledLocal) {
                        if isBGFetchEnabledLocal {
                            BackgroundTasks.shared.scheduleDataFetch()
                            
                        } else {
                            BackgroundTasks.shared.cancelBackgroundTask()
                        }
                        variables.isBGFetchEnabled = isBGFetchEnabledLocal
                    }

                Picker("Notification Interval", selection: $selectedInterval) {
                    ForEach(intervals, id: \.self) { interval in
                        Text(BackgroundNotifications.shared.intervalLabel(interval)).tag(interval)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .onChange(of: selectedInterval) { oldValue, newValue in
                    variables.selectedInterval = newValue
                    if isBGFetchEnabledLocal {
                        BackgroundTasks.shared.cancelBackgroundTask()
                        BackgroundTasks.shared.scheduleDataFetch()
                    }
                }
            }
            
            // Stock Chart Component
            StockChartView()

            // Fetch Data Button
            Button(action: {
                StockDataFetcher.shared.fetchStockData()
            }) {
                Text("Fetch Data")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Button(action: {
                variables.prices = []
                variables.highestPrice = (Date(), 0.0)
                variables.lowestPrice = (Date(), 0.0)
                variables.regimeName = "No Regime"
                variables.regimeDescription = "No Input Data."
                BGTaskScheduler.shared.getPendingTaskRequests { tasks in
                    for task in tasks {
                        print("Current time: \(Date())")
                        print("📌 Pending task: \(task.identifier), scheduled for \(task.earliestBeginDate ?? Date())")
                    }
                    if tasks.isEmpty {
                        print("NO TASKS")
                    }
                }
            }) {
                Text("Delete Prices")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Text(variables.regimeDescription)
        }
        .padding()
    }
}

struct StockChartView: View {
    @ObservedObject var variables = Variables.shared
    
    var body: some View {
        Chart {
            // Line Chart
            ForEach(variables.prices, id: \.0) { date, price in
                LineMark(
                    x: .value("Date", date),
                    y: .value("Price (USD)", price)
                )
            }
            if variables.highestPrice.1 != 0.0 {
                PointMark(
                    x: .value("Date", variables.highestPrice.0),
                    y: .value("Price (USD)", variables.highestPrice.1)
                )
                .foregroundStyle(.green)
                .annotation(position: .top, alignment: .center) {
                VStack {
                    Text("Highest: \(variables.highestPrice.1, specifier: "%.2f")$")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(variables.highestPrice.0, format: .dateTime.year().month().day())
                        .font(.caption2)
                        .foregroundColor(.gray)
                    }
                }

                PointMark(
                    x: .value("Date", variables.lowestPrice.0),
                    y: .value("Price (USD)", variables.lowestPrice.1)
                )
                .foregroundStyle(.red)
                .annotation(position: .bottom, alignment: .center) {
                    VStack {
                        Text("Lowest: \(variables.lowestPrice.1, specifier: "%.2f")$")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text(variables.lowestPrice.0, format: .dateTime.year().month().day())
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .frame(height: 300)
        .padding()
    }
}
