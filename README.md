# FlowWhisperer 🎙️

Voice-to-clipboard transcription app with AI enhancement support for OpenAI and Groq.

## How It Works

**Keyboard Shortcut**: ⇧ + ⌘ (customizable)

Press shortcut → **Black** (idle) → **Blue** (recording) → **Purple** (transcribing) → **Green** (ready) → Text automatically copied to clipboard

## Features

- 🤖 **Dual AI Provider Support**: Choose between OpenAI or Groq for transcription and enhancement
- 🎯 **Visual Feedback**: Floating indicator shows real-time status with color-coded feedback
- ✨ **Smart Enhancement**: AI improves transcribed speech for clarity and readability
- ⌨️ **Customizable Shortcuts**: Set your preferred key combination
- 🔐 **Secure Storage**: Independent API key validation for each provider

## Requirements

- macOS 13.0 or later
- Microphone permissions  
- OpenAI or Groq API key

## Installation

### Option 1: Build from Source
```bash
git clone <repository-url>
cd flowwhisperer
./build.sh
```

### Option 2: Download DMG
Download `FlowWhisperer.dmg` from this repository and drag to Applications.

## Quick Setup

1. Install FlowWhisperer
2. Open Settings and select your AI provider (OpenAI or Groq)
3. Enter your API key
4. Set keyboard shortcut
5. Start recording with your shortcut!

## API Provider Options

### OpenAI
- Transcription: `gpt-4o-transcribe`
- Enhancement: `gpt-5-mini`
- Validation: `gpt-5-nano`

### Groq
- Transcription: `whisper-large-v3-turbo`
- Enhancement: `openai/gpt-oss-120b`
- Validation: `openai/gpt-oss-120b`

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

MIT License - See [LICENSE](LICENSE) file for details.

## Contributing

Contributions welcome! Please read our contributing guidelines and submit pull requests.

---

Built with ❤️ using Swift and SwiftUI