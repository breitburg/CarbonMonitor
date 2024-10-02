//
//  CarbonMonitorApp.swift
//  CarbonMonitor
//
//  Created by Ilia Breitburg on 02/10/2024.
//

import SwiftUI

@main
struct CarbonMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            // Optional settings window
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
        var popover = NSPopover()
        var timer: Timer?

        func applicationDidFinishLaunching(_ notification: Notification) {
            // Create the status bar item
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = statusItem?.button {
                button.image = NSImage(systemSymbolName: "leaf", accessibilityDescription: "Carbon Monitor")
                button.action = #selector(togglePopover(_:))
            }

            // Set up the popover
            popover.contentViewController = NSHostingController(rootView: ContentView())
            popover.behavior = .transient

            // Start the timer to update data periodically
            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(updateData), userInfo: nil, repeats: true)
            updateData()
        }

        @objc func togglePopover(_ sender: AnyObject?) {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                if let button = statusItem?.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }

        @objc func updateData() {
            NotificationCenter.default.post(name: .updateData, object: nil)
        }
}
