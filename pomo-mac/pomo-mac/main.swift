// This file serves as the application entry point
// It replaces the @NSApplicationMain attribute

import Cocoa

// Enable sandboxing-compatible menu bar support
NSApplication.shared.setActivationPolicy(.accessory)

// Create the application and delegate
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Print confirmation
print("Starting Pomodoro Timer app")

// Run the application
app.run()
