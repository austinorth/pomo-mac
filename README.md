# pomo-mac

A Pomodoro Timer for macOS that lives in your menu bar.

## Features

- Simple menu bar timer for the Pomodoro Technique
- Configurable work, break, and long break durations
- Automatic cycling between work and break periods
- Desktop notifications when timers complete
- Statistics tracking for completed pomodoros and breaks

## Requirements

- macOS 15.2+
- Xcode 16.2+
- Swift 5.0+

## Installation

### Clone the Repository

1. Open Terminal
2. Clone the repository using git:
   ```
   git clone https://github.com/austinorth/pomo-mac.git
   cd pomo-mac
   ```

### Build and Run with Xcode

1. Open the project in Xcode:
   ```
   open pomo-mac/pomo-mac.xcodeproj
   ```

   Or simply double-click the `pomo-mac.xcodeproj` file in Finder.

2. Select the appropriate build target and device (your Mac)
   - In Xcode's toolbar, ensure "pomo-mac" is selected as the scheme
   - Make sure your Mac is selected as the destination

3. Build and run the app:
   - Click the Play button in the top-left corner of Xcode
   - Or use the keyboard shortcut ⌘+R

4. The app will compile and run, appearing as an icon in your menu bar

## Usage

- Click the timer icon in the menu bar to access the Pomodoro interface
- Start/pause the timer using the respective buttons
- Configure timer durations in the Settings menu
- The app will automatically cycle between work and break periods
- You'll receive notifications when a timer completes

## License

This project is licensed under the MIT License - see the LICENSE file for details.
