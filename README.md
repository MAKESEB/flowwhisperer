# FlowWhisperer 🎙️

A native macOS application that transcribes speech to enhanced text via keyboard shortcut and copies it to clipboard.

## Features

- 🎤 **Voice Recording**: Press and hold a keyboard shortcut to record audio
- 🤖 **AI Transcription**: Uses OpenAI Whisper for accurate speech-to-text
- ✨ **Text Enhancement**: AI-powered text improvement with customizable context
- 📋 **Clipboard Integration**: Automatically copies enhanced text to clipboard
- ⌨️ **Global Shortcuts**: Configurable keyboard shortcuts (default: fn+w)
- 🎨 **Native Dark Mode**: Beautiful SwiftUI interface that adapts to system theme
- 🔒 **Secure Storage**: API keys stored securely in macOS Keychain

## Requirements

- macOS 13.0 or later
- Microphone permissions
- OpenAI API key

## Installation

### Option 1: Build from Source
```bash
git clone <repository-url>
cd flowwhisperer
./build.sh
```

### Option 2: Download DMG
Download the latest `.dmg` file from releases and drag to Applications.

## Setup

1. **Get OpenAI API Key**
   - Visit [OpenAI Platform](https://platform.openai.com/api-keys)
   - Create a new API key
   - Copy the key for setup

2. **Configure FlowWhisperer**
   - Launch the app
   - Add your OpenAI API key in settings
   - Customize keyboard shortcut if desired
   - Set your context prompt for text enhancement

3. **Grant Permissions**
   - Allow microphone access when prompted
   - Enable accessibility permissions for global shortcuts

## Usage

1. **Press and hold** your keyboard shortcut (default: fn+w)
2. **Speak** while holding the key
3. **Release** the key to stop recording
4. **Wait** for AI processing (transcription + enhancement)
5. **Paste** - the enhanced text is automatically copied to clipboard

## Technical Details

### Architecture
- **Native Swift/SwiftUI** - No web wrapper, pure macOS performance
- **AVFoundation** - Professional audio recording
- **Carbon Framework** - Global keyboard shortcut handling
- **Keychain Services** - Secure API key storage
- **UserNotifications** - System notifications

### API Integration
- **OpenAI Whisper** - Speech transcription (`whisper-1` model)
- **OpenAI GPT** - Text enhancement (`gpt-3.5-turbo`)
- **Secure HTTP** - All API calls use HTTPS with proper authentication

### Privacy & Security
- ✅ API keys encrypted in macOS Keychain
- ✅ Audio files automatically deleted after processing
- ✅ No data stored remotely (except OpenAI API calls)
- ✅ Sandboxed application with minimal permissions

## Building

### Prerequisites
```bash
# Install Xcode command line tools
xcode-select --install

# Install create-dmg for DMG generation (optional)
brew install create-dmg
```

### Build Process
```bash
# Clone and build
git clone <repository-url>
cd flowwhisperer
./build.sh

# The script will:
# 1. Build the app with xcodebuild
# 2. Create a DMG file (if create-dmg is installed)
# 3. Output build artifacts
```

### Development
```bash
# Open in Xcode
open FlowWhisperer.xcodeproj

# Or build from command line
xcodebuild -project FlowWhisperer.xcodeproj -scheme FlowWhisperer build
```

## Project Structure
```
FlowWhisperer/
├── FlowWhispererApp.swift          # Main app entry point
├── Views/
│   ├── ContentView.swift           # Main window
│   ├── SettingsView.swift          # Settings interface
│   ├── KeyboardShortcutPicker.swift # Shortcut configuration
│   └── StatusMenuView.swift        # Menu bar interface
├── Models/
│   └── AppSettings.swift           # Settings data model
├── Services/
│   ├── AudioRecordingService.swift # Audio recording logic
│   ├── OpenAIService.swift         # API integration
│   └── KeyboardService.swift       # Global shortcuts
├── Utils/
│   ├── KeychainHelper.swift        # Secure storage
│   ├── ClipboardHelper.swift       # Clipboard operations
│   └── NotificationHelper.swift    # System notifications
└── Resources/
    ├── Info.plist                  # App configuration
    └── FlowWhisperer.entitlements  # Security permissions
```

## Troubleshooting

### Common Issues

**Microphone Permission Denied**
- Go to System Settings → Privacy & Security → Microphone
- Enable FlowWhisperer

**Keyboard Shortcut Not Working**  
- Go to System Settings → Privacy & Security → Accessibility
- Enable FlowWhisperer

**API Errors**
- Verify your OpenAI API key is valid
- Check your OpenAI account has sufficient credits
- Ensure stable internet connection

**Build Errors**
- Make sure Xcode command line tools are installed
- Verify macOS version is 13.0 or later
- Check all source files are present

### Getting Help

1. Check the menu bar status indicator for app state
2. Use "Test Recording" from the menu bar to verify setup
3. Check Console.app for detailed error logs
4. Verify all permissions in System Settings

## License

[Your License Here]

## Contributing

Contributions welcome! Please read our contributing guidelines and submit pull requests.

---

Built with ❤️ using Swift and SwiftUI