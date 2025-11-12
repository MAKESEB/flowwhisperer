# FlowWhisperer Triple API Provider Configuration

## OpenAI Configuration
- **API Validation**: `gpt-5-nano` with chat/completions endpoint
- **Audio Transcription**: `gpt-4o-transcribe` with audio/transcriptions endpoint  
- **Text Enhancement**: `gpt-5-mini` with chat/completions endpoint, json_object response format (must mention JSON in system prompt)

## Groq Configuration  
- **API Validation**: `openai/gpt-oss-120b` with chat/completions endpoint
- **Audio Transcription**: `whisper-large-v3-turbo` with audio/transcriptions endpoint, verbose_json response format
- **Text Enhancement**: `openai/gpt-oss-120b` with chat/completions endpoint, direct text response

## Google Gemini Configuration
- **API Validation**: `gemini-2.0-flash-exp` with models/:generateContent endpoint
- **Audio Transcription**: `gemini-2.0-flash-exp` with 2-step process:
  1. File upload via /upload/v1beta/files (resumable upload protocol)
  2. Transcription via models/:generateContent with file_uri reference
- **Text Enhancement**: `gemini-2.0-flash-exp` with models/:generateContent endpoint, direct text response
- **Authentication**: Uses `x-goog-api-key` header (not Bearer token)
- **Response Format**: `candidates[].content.parts[].text` structure

## Provider Architecture
- Uses `ProviderConfig` protocol for extensible API integration
- Dynamic provider switching via `AIService` 
- Independent API key validation for each provider
- Provider-specific error handling and response parsing
- Special handling for Google's unique file upload system for audio transcription