//
//  ContentView.swift
//  CarbonMonitor
//
//  Created by Ilia Breitburg on 02/10/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CarbonViewModel()

        var body: some View {
            VStack(alignment: .leading) {
                Text("Carbon Emissions")
                    .font(.headline)
                Text("Estimated Power Usage: \(String(format: "%.2f", viewModel.powerUsage)) W")
                Text("Carbon Intensity: \(viewModel.carbonIntensity) gCO₂/kWh")
                Text("Carbon Emission: \(String(format: "%.2f", viewModel.co2Emission)) g/h")
                Divider()
                Button("Refresh") {
                    viewModel.updateData()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            .padding()
            .frame(width: 250)
            .onAppear {
                viewModel.updateData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .updateData)) { _ in
                viewModel.updateData()
            }
        }
}

#Preview {
    ContentView()
}
