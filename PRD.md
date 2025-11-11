# FlowWhisperer - Simple Voice-to-Clipboard

## Overview
FlowWhisperer is a simple macOS application that transcribes speech to enhanced text via keyboard shortcut and copies it to clipboard.

## User Interface
Simple settings window with three fields:
1. **OpenAI API Key** - Text input for API authentication
2. **Keyboard Shortcut** - Configurable hotkey (default: `fn+w`)
3. **Context** - Text field for user context/instructions

## Workflow
1. User presses keyboard shortcut
2. Records audio while key is held
3. Transcribes audio using OpenAI API:
   ```
   POST https://api.openai.com/v1/audio/transcriptions
   - model: gpt-4o-transcribe
   - file: audio.mp3 (or other supported formats)
   ```
4. Enhances transcription using GPT-4o-mini:
   ```
   POST https://api.openai.com/v1/chat/completions
   - model: gpt-4o-mini
   - Prompt includes user context
   - response_format: json_object
   - Returns structured JSON with enhanced text
   ```
5. Extracts text from JSON response
6. Copies enhanced text to system clipboard

## Technical Requirements
- Electron-based macOS application (.dmg)
- Global keyboard shortcut registration
- Audio recording capabilities
- OpenAI API integration
- System clipboard access
- Settings persistence

## Success Criteria
- User can configure API key, shortcut, and context
- Press shortcut → record → transcribe → enhance → clipboard
- Distributable as .dmg file