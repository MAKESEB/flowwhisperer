import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var showingKeyboardShortcutPicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // API Provider Selection Section
                SettingsCard(
                    title: "AI Provider",
                    description: "",
                    icon: "brain"
                ) {
                    Picker("Provider", selection: $appSettings.selectedProvider) {
                        ForEach(APIProvider.allCases, id: \.self) { provider in
                            Text(provider.displayName)
                                .tag(provider)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // API Key Section - Dynamic based on selected provider
                apiKeySection
                
                // Keyboard Shortcut Section  
                SettingsCard(
                    title: "Keyboard Shortcut",
                    description: "",
                    icon: "keyboard"
                ) {
                    HStack {
                        Button(action: {
                            showingKeyboardShortcutPicker.toggle()
                        }) {
                            HStack {
                                Text(appSettings.keyboardShortcut.displayString)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(CustomButtonStyle())
                    }
                }
                
                // Context Prompt Section
                SettingsCard(
                    title: "Context Prompt", 
                    description: "",
                    icon: "text.bubble"
                ) {
                    TextEditor(text: $appSettings.contextPrompt)
                        .frame(minHeight: 80)
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                        .font(.system(.body))
                }
                
                // Status Section
                if appSettings.isProcessing || !appSettings.lastTranscription.isEmpty {
                    SettingsCard(
                        title: "Last Transcription",
                        description: "",
                        icon: "doc.text"
                    ) {
                        if appSettings.isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Transcribing and enhancing...")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                Text(appSettings.lastTranscription)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                    )
                            }
                            .frame(maxHeight: 100)
                        }
                    }
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showingKeyboardShortcutPicker) {
            KeyboardShortcutPicker(selectedShortcut: $appSettings.keyboardShortcut)
        }
    }
    
    // MARK: - Dynamic API Key Section
    
    @ViewBuilder
    private var apiKeySection: some View {
        let currentProvider = appSettings.selectedProvider
        let isValidated = appSettings.isCurrentAPIKeyValid
        let isSet = appSettings.isCurrentAPIKeySet
        let isValidating = appSettings.isValidatingAPIKey
        
        if isValidated {
            SettingsCard(
                title: "\(currentProvider.displayName) API Key",
                description: "",
                icon: "checkmark.circle.fill"
            ) {
                HStack {
                    Text("API key configured and validated")
                        .foregroundColor(.green)
                    Spacer()
                    Button("Delete") {
                        appSettings.clearCurrentAPIKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        } else {
            SettingsCard(
                title: "\(currentProvider.displayName) API Key",
                description: "",
                icon: "key.fill"
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    SecureField("Enter your \(currentProvider.displayName) API key", text: currentAPIKeyBinding)
                        .textFieldStyle(CustomTextFieldStyle())
                    
                    // API Key Status
                    if isSet {
                        if isValidating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("Validating API key...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else if !isValidated {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Invalid API key")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("API key validated")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Dynamic API Key Binding
    
    private var currentAPIKeyBinding: Binding<String> {
        switch appSettings.selectedProvider {
        case .openai:
            return $appSettings.openAIKey
        case .groq:
            return $appSettings.groqKey
        }
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let description: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
    }
}

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}