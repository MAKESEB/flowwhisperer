# FlowWhisperer OpenAI API Configuration

**Step 0 - API Validation**: Use `gpt-5-mini` with chat/completions endpoint for validation
**Step 1 - Audio Transcription**: Use `gpt-4o-transcribe` with audio/transcriptions endpoint  
**Step 2 - Text Enhancement**: Use `gpt-5-mini` with chat/completions endpoint, json_object response format, must mention JSON in system prompt for json mode to work