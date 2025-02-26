import Cocoa
import UserNotifications

// Main App Delegate
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    // Using a strong reference to ensure the status item doesn't get deallocated
private let statusItem: NSStatusItem = {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    return item
}()
    let popover = NSPopover()
    
    // Timer settings
    var pomodoroMinutes = 25
    var breakMinutes = 5
    var longBreakMinutes = 15
    var pomodorosBeforeLongBreak = 4
    
    // Counters
    var completedPomodoros = 0
    var completedBreaks = 0
    var completedLongBreaks = 0
    
    // Timer state
    var timer: Timer?
    var secondsRemaining = 0
    var isRunning = false
    var currentMode: TimerMode = .pomodoro
    
    enum TimerMode {
        case pomodoro
        case break_
        case longBreak
        
        var title: String {
            switch self {
            case .pomodoro: return "Pomodoro"
            case .break_: return "Break"
            case .longBreak: return "Long Break"
            }
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        UNUserNotificationCenter.current().delegate = self
        
        // Setup menu bar item
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Timer")
            button.title = "25:00" // Add initial title text
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        
        // Setup popover
        popover.contentViewController = PomodoroViewController(appDelegate: self)
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 300, height: 280)
        
        // Initialize timer
        resetTimers()
        
        // Update the status bar immediately to ensure it's visible
        updateStatusBarIcon()
        
        // Debug message
        print("Pomodoro app launched and status item initialized")
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    func closePopover(_ sender: Any?) {
        popover.performClose(sender)
    }
    
    func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        updateStatusBarIcon()
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        updateStatusBarIcon()
    }
    
    func resetTimers() {
        pauseTimer()
        currentMode = .pomodoro
        secondsRemaining = pomodoroMinutes * 60
        completedPomodoros = 0
        completedBreaks = 0
        completedLongBreaks = 0
        updateStatusBarIcon()
        NotificationCenter.default.post(name: NSNotification.Name("TimerReset"), object: nil)
    }
    
    func updateSettings(pomodoro: Int, break_: Int, longBreak: Int, pomodorosBeforeLong: Int) {
        pomodoroMinutes = pomodoro
        breakMinutes = break_
        longBreakMinutes = longBreak
        pomodorosBeforeLongBreak = pomodorosBeforeLong
        
        // Update current timer if needed
        switch currentMode {
        case .pomodoro:
            secondsRemaining = pomodoroMinutes * 60
        case .break_:
            secondsRemaining = breakMinutes * 60
        case .longBreak:
            secondsRemaining = longBreakMinutes * 60
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("TimerUpdated"), object: nil)
    }
    
    @objc func updateTimer() {
        if secondsRemaining > 0 {
            secondsRemaining -= 1
            updateStatusBarIcon()
            NotificationCenter.default.post(name: NSNotification.Name("TimerTick"), object: nil)
        } else {
            // Timer finished
            timer?.invalidate()
            timer = nil
            isRunning = false
            
            // Send notification
            sendNotification()
            
            // Move to next timer mode
            switch currentMode {
            case .pomodoro:
                completedPomodoros += 1
                if completedPomodoros % pomodorosBeforeLongBreak == 0 {
                    currentMode = .longBreak
                    secondsRemaining = longBreakMinutes * 60
                } else {
                    currentMode = .break_
                    secondsRemaining = breakMinutes * 60
                }
            case .break_:
                completedBreaks += 1
                currentMode = .pomodoro
                secondsRemaining = pomodoroMinutes * 60
            case .longBreak:
                completedLongBreaks += 1
                currentMode = .pomodoro
                secondsRemaining = pomodoroMinutes * 60
            }
            
            updateStatusBarIcon()
            NotificationCenter.default.post(name: NSNotification.Name("TimerModeChanged"), object: nil)
        }
    }
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        
        switch currentMode {
        case .pomodoro:
            content.title = "Pomodoro Completed!"
            content.body = "Time for a break."
        case .break_:
            content.title = "Break Completed!"
            content.body = "Time to focus again."
        case .longBreak:
            content.title = "Long Break Completed!"
            content.body = "Ready for another pomodoro?"
        }
        
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func updateStatusBarIcon() {
        if let button = statusItem.button {
            let minutes = secondsRemaining / 60
            let seconds = secondsRemaining % 60
            button.title = String(format: "%02d:%02d", minutes, seconds)
            
            // Change icon based on timer state and mode
            var imageName = "timer"
            if isRunning {
                switch currentMode {
                case .pomodoro:
                    imageName = "timer.circle.fill"
                case .break_:
                    imageName = "cup.and.saucer.fill"
                case .longBreak:
                    imageName = "figure.walk"
                }
            }
            
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "Timer")
            } else {
                // Fallback for older macOS versions
                button.image = NSImage(named: NSImage.Name("NSStatusAvailable"))
            }
            
            print("Updated status bar icon: \(button.title ?? "")")
        } else {
            print("ERROR: Status bar button is nil")
        }
    }
}

class PomodoroViewController: NSViewController {
    private var appDelegate: AppDelegate
    
    // UI Elements
    private var currentModeLabel: NSTextField!
    private var timerLabel: NSTextField!
    private var startPauseButton: NSButton!
    private var resetButton: NSButton!
    private var settingsButton: NSButton!
    
    // Stats counters
    private var pomodoroCountLabel: NSTextField!
    private var breakCountLabel: NSTextField!
    private var longBreakCountLabel: NSTextField!
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        // Increase the height to ensure all content is visible
        view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 280))
        view.wantsLayer = true
        
        setupUI()
        updateUI()
        
        // Register for notifications
        NotificationCenter.default.addObserver(self, selector: #selector(timerTick), name: NSNotification.Name("TimerTick"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(timerModeChanged), name: NSNotification.Name("TimerModeChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(timerReset), name: NSNotification.Name("TimerReset"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(timerUpdated), name: NSNotification.Name("TimerUpdated"), object: nil)
    }
    
    private func setupUI() {
        // Current mode label
        currentModeLabel = NSTextField(labelWithString: "Pomodoro")
        currentModeLabel.alignment = .center
        currentModeLabel.font = NSFont.boldSystemFont(ofSize: 18)
        currentModeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentModeLabel)
        
        // Timer label
        timerLabel = NSTextField(labelWithString: "25:00")
        timerLabel.alignment = .center
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 36, weight: .regular)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)
        
        // Start/Pause Button
        startPauseButton = NSButton(title: "Start", target: self, action: #selector(startPauseTimer))
        startPauseButton.bezelStyle = .rounded
        startPauseButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startPauseButton)
        
        // Reset Button
        resetButton = NSButton(title: "Reset", target: self, action: #selector(resetTimer))
        resetButton.bezelStyle = .rounded
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resetButton)
        
        // Settings Button
        settingsButton = NSButton(title: "Settings", target: self, action: #selector(showSettings))
        settingsButton.bezelStyle = .rounded
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsButton)
        
        // Stats Section with styled boxes
        let statsContainer = NSView()
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statsContainer)
        
        // Create stats title
        let statsTitle = NSTextField(labelWithString: "Statistics")
        statsTitle.alignment = .center
        statsTitle.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        statsTitle.textColor = NSColor.secondaryLabelColor
        statsTitle.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.addSubview(statsTitle)
        
        // Create counters with styled boxes
        let pomodoroStatsView = createStatsBox(title: "Pomodoros", value: "0")
        let breakStatsView = createStatsBox(title: "Breaks", value: "0")
        let longBreakStatsView = createStatsBox(title: "Long Breaks", value: "0")
        
        statsContainer.addSubview(pomodoroStatsView)
        statsContainer.addSubview(breakStatsView)
        statsContainer.addSubview(longBreakStatsView)
        
        // Store references to counter values
        pomodoroCountLabel = pomodoroStatsView.subviews.compactMap { $0 as? NSTextField }.last
        breakCountLabel = breakStatsView.subviews.compactMap { $0 as? NSTextField }.last
        longBreakCountLabel = longBreakStatsView.subviews.compactMap { $0 as? NSTextField }.last
        
        // Set constraints
        NSLayoutConstraint.activate([
            currentModeLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            currentModeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            currentModeLabel.widthAnchor.constraint(equalTo: view.widthAnchor),
            
            timerLabel.topAnchor.constraint(equalTo: currentModeLabel.bottomAnchor, constant: 10),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.widthAnchor.constraint(equalTo: view.widthAnchor),
            
            startPauseButton.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 20),
            startPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -60),
            
            resetButton.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 20),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 60),
            
            settingsButton.topAnchor.constraint(equalTo: startPauseButton.bottomAnchor, constant: 15),
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            statsContainer.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 20),
            statsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15),
            
            statsTitle.topAnchor.constraint(equalTo: statsContainer.topAnchor),
            statsTitle.centerXAnchor.constraint(equalTo: statsContainer.centerXAnchor),
            
            pomodoroStatsView.topAnchor.constraint(equalTo: statsTitle.bottomAnchor, constant: 8),
            pomodoroStatsView.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor),
            pomodoroStatsView.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.3),
            pomodoroStatsView.heightAnchor.constraint(equalToConstant: 50),
            
            breakStatsView.topAnchor.constraint(equalTo: statsTitle.bottomAnchor, constant: 8),
            breakStatsView.centerXAnchor.constraint(equalTo: statsContainer.centerXAnchor),
            breakStatsView.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.3),
            breakStatsView.heightAnchor.constraint(equalToConstant: 50),
            
            longBreakStatsView.topAnchor.constraint(equalTo: statsTitle.bottomAnchor, constant: 8),
            longBreakStatsView.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor),
            longBreakStatsView.widthAnchor.constraint(equalTo: statsContainer.widthAnchor, multiplier: 0.3),
            longBreakStatsView.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    // Helper method to create styled stats boxes
    private func createStatsBox(title: String, value: String) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        container.layer?.cornerRadius = 6
        container.layer?.borderWidth = 1
        container.layer?.borderColor = NSColor.separatorColor.cgColor
        
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.alignment = .center
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = NSColor.secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.alignment = .center
        valueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -2),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        
        return container
    }
    
    @objc func startPauseTimer(_ sender: NSButton) {
        if appDelegate.isRunning {
            appDelegate.pauseTimer()
            startPauseButton.title = "Start"
        } else {
            appDelegate.startTimer()
            startPauseButton.title = "Pause"
        }
    }
    
    @objc func resetTimer(_ sender: NSButton) {
        appDelegate.resetTimers()
        updateUI()
    }
    
    @objc func showSettings(_ sender: NSButton) {
        let settingsViewController = SettingsViewController(appDelegate: appDelegate)
        presentAsSheet(settingsViewController)
    }
    
    @objc func timerTick() {
        updateUI()
    }
    
    @objc func timerModeChanged() {
        updateUI()
    }
    
    @objc func timerReset() {
        updateUI()
    }
    
    @objc func timerUpdated() {
        updateUI()
    }
    
    private func updateUI() {
        // Update mode label
        currentModeLabel.stringValue = appDelegate.currentMode.title
        
        // Update timer label
        let minutes = appDelegate.secondsRemaining / 60
        let seconds = appDelegate.secondsRemaining % 60
        timerLabel.stringValue = String(format: "%02d:%02d", minutes, seconds)
        
        // Update button
        startPauseButton.title = appDelegate.isRunning ? "Pause" : "Start"
        
        // Update stats counters
        pomodoroCountLabel.stringValue = "\(appDelegate.completedPomodoros)"
        breakCountLabel.stringValue = "\(appDelegate.completedBreaks)"
        longBreakCountLabel.stringValue = "\(appDelegate.completedLongBreaks)"
    }
}

class SettingsViewController: NSViewController {
    private var appDelegate: AppDelegate
    
    private var pomodoroStepper: NSStepper!
    private var pomodoroLabel: NSTextField!
    private var breakStepper: NSStepper!
    private var breakLabel: NSTextField!
    private var longBreakStepper: NSStepper!
    private var longBreakLabel: NSTextField!
    private var cycleCountStepper: NSStepper!
    private var cycleCountLabel: NSTextField!
    
    private var pomodoroValue: Int
    private var breakValue: Int
    private var longBreakValue: Int
    private var cycleCountValue: Int
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        self.pomodoroValue = appDelegate.pomodoroMinutes
        self.breakValue = appDelegate.breakMinutes
        self.longBreakValue = appDelegate.longBreakMinutes
        self.cycleCountValue = appDelegate.pomodorosBeforeLongBreak
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 280))
        setupUI()
    }
    
    private func setupUI() {
        // Title
        let titleLabel = NSTextField(labelWithString: "Timer Settings")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Pomodoro settings
        let pomodoroTitle = NSTextField(labelWithString: "Pomodoro length (minutes):")
        pomodoroTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pomodoroTitle)
        
        pomodoroLabel = NSTextField(labelWithString: "\(pomodoroValue)")
        pomodoroLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pomodoroLabel)
        
        pomodoroStepper = NSStepper()
        pomodoroStepper.minValue = 1
        pomodoroStepper.maxValue = 60
        pomodoroStepper.increment = 1
        pomodoroStepper.intValue = Int32(pomodoroValue)
        pomodoroStepper.target = self
        pomodoroStepper.action = #selector(pomodoroStepperChanged(_:))
        pomodoroStepper.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pomodoroStepper)
        
        // Break settings
        let breakTitle = NSTextField(labelWithString: "Break length (minutes):")
        breakTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(breakTitle)
        
        breakLabel = NSTextField(labelWithString: "\(breakValue)")
        breakLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(breakLabel)
        
        breakStepper = NSStepper()
        breakStepper.minValue = 1
        breakStepper.maxValue = 30
        breakStepper.increment = 1
        breakStepper.intValue = Int32(breakValue)
        breakStepper.target = self
        breakStepper.action = #selector(breakStepperChanged(_:))
        breakStepper.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(breakStepper)
        
        // Long break settings
        let longBreakTitle = NSTextField(labelWithString: "Long break length (minutes):")
        longBreakTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(longBreakTitle)
        
        longBreakLabel = NSTextField(labelWithString: "\(longBreakValue)")
        longBreakLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(longBreakLabel)
        
        longBreakStepper = NSStepper()
        longBreakStepper.minValue = 1
        longBreakStepper.maxValue = 60
        longBreakStepper.increment = 1
        longBreakStepper.intValue = Int32(longBreakValue)
        longBreakStepper.target = self
        longBreakStepper.action = #selector(longBreakStepperChanged(_:))
        longBreakStepper.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(longBreakStepper)
        
        // Cycle count settings
        let cycleTitle = NSTextField(labelWithString: "Pomodoros before long break:")
        cycleTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cycleTitle)
        
        cycleCountLabel = NSTextField(labelWithString: "\(cycleCountValue)")
        cycleCountLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cycleCountLabel)
        
        cycleCountStepper = NSStepper()
        cycleCountStepper.minValue = 1
        cycleCountStepper.maxValue = 10
        cycleCountStepper.increment = 1
        cycleCountStepper.intValue = Int32(cycleCountValue)
        cycleCountStepper.target = self
        cycleCountStepper.action = #selector(cycleStepperChanged(_:))
        cycleCountStepper.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cycleCountStepper)
        
        // Save button
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.bezelStyle = .rounded
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        // Cancel button
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelSettings))
        cancelButton.bezelStyle = .rounded
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            pomodoroTitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            pomodoroTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            pomodoroLabel.centerYAnchor.constraint(equalTo: pomodoroTitle.centerYAnchor),
            pomodoroLabel.trailingAnchor.constraint(equalTo: pomodoroStepper.leadingAnchor, constant: -10),
            pomodoroLabel.widthAnchor.constraint(equalToConstant: 30),
            
            pomodoroStepper.centerYAnchor.constraint(equalTo: pomodoroTitle.centerYAnchor),
            pomodoroStepper.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            breakTitle.topAnchor.constraint(equalTo: pomodoroTitle.bottomAnchor, constant: 15),
            breakTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            breakLabel.centerYAnchor.constraint(equalTo: breakTitle.centerYAnchor),
            breakLabel.trailingAnchor.constraint(equalTo: breakStepper.leadingAnchor, constant: -10),
            breakLabel.widthAnchor.constraint(equalToConstant: 30),
            
            breakStepper.centerYAnchor.constraint(equalTo: breakTitle.centerYAnchor),
            breakStepper.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            longBreakTitle.topAnchor.constraint(equalTo: breakTitle.bottomAnchor, constant: 15),
            longBreakTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            longBreakLabel.centerYAnchor.constraint(equalTo: longBreakTitle.centerYAnchor),
            longBreakLabel.trailingAnchor.constraint(equalTo: longBreakStepper.leadingAnchor, constant: -10),
            longBreakLabel.widthAnchor.constraint(equalToConstant: 30),
            
            longBreakStepper.centerYAnchor.constraint(equalTo: longBreakTitle.centerYAnchor),
            longBreakStepper.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            cycleTitle.topAnchor.constraint(equalTo: longBreakTitle.bottomAnchor, constant: 15),
            cycleTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            cycleCountLabel.centerYAnchor.constraint(equalTo: cycleTitle.centerYAnchor),
            cycleCountLabel.trailingAnchor.constraint(equalTo: cycleCountStepper.leadingAnchor, constant: -10),
            cycleCountLabel.widthAnchor.constraint(equalToConstant: 30),
            
            cycleCountStepper.centerYAnchor.constraint(equalTo: cycleTitle.centerYAnchor),
            cycleCountStepper.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: cycleTitle.bottomAnchor, constant: 25),
            saveButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            
            cancelButton.topAnchor.constraint(equalTo: cycleTitle.bottomAnchor, constant: 25),
            cancelButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
        ])
    }
    
    @objc func pomodoroStepperChanged(_ sender: NSStepper) {
        pomodoroValue = Int(sender.intValue)
        pomodoroLabel.stringValue = "\(pomodoroValue)"
    }
    
    @objc func breakStepperChanged(_ sender: NSStepper) {
        breakValue = Int(sender.intValue)
        breakLabel.stringValue = "\(breakValue)"
    }
    
    @objc func longBreakStepperChanged(_ sender: NSStepper) {
        longBreakValue = Int(sender.intValue)
        longBreakLabel.stringValue = "\(longBreakValue)"
    }
    
    @objc func cycleStepperChanged(_ sender: NSStepper) {
        cycleCountValue = Int(sender.intValue)
        cycleCountLabel.stringValue = "\(cycleCountValue)"
    }
    
    @objc func saveSettings() {
        appDelegate.updateSettings(
            pomodoro: pomodoroValue,
            break_: breakValue,
            longBreak: longBreakValue,
            pomodorosBeforeLong: cycleCountValue
        )
        dismiss(nil)
    }
    
    @objc func cancelSettings() {
        dismiss(nil)
    }
}
