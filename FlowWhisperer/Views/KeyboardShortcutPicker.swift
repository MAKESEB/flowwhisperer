import SwiftUI

struct KeyboardShortcutPicker: View {
    @Binding var selectedShortcut: KeyCombination
    @Environment(\.dismiss) private var dismiss
    @State private var tempShortcut: KeyCombination
    
    init(selectedShortcut: Binding<KeyCombination>) {
        self._selectedShortcut = selectedShortcut
        self._tempShortcut = State(initialValue: selectedShortcut.wrappedValue)
    }
    
    private let modifierOptions = [
        ("cmd", "⌘ Command"),
        ("option", "⌥ Option"),
        ("ctrl", "⌃ Control"),
        ("shift", "⇧ Shift"),
        ("fn", "fn Function")
    ]
    
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Recording Shortcut")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose a keyboard combination to trigger recording")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            // Preset options
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Shortcuts")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    ForEach(KeyCombination.presetShortcuts, id: \.displayString) { preset in
                        HStack {
                            Button(action: {
                                tempShortcut = preset
                            }) {
                                HStack {
                                    // Radio button indicator
                                    Image(systemName: tempShortcut == preset ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(tempShortcut == preset ? .accentColor : .secondary)
                                        .font(.title3)
                                    
                                    // Shortcut display
                                    Text(preset.displayString)
                                        .font(.system(.title3, design: .monospaced))
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    // Description
                                    Text(getShortcutDescription(preset))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(tempShortcut == preset ? Color.accentColor.opacity(0.1) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(tempShortcut == preset ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    selectedShortcut = tempShortcut
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 500, maxHeight: 400)
    }
    
    private func getShortcutDescription(_ shortcut: KeyCombination) -> String {
        if shortcut.modifiers.contains("shift") && shortcut.modifiers.contains("cmd") {
            return "Recommended - Easy to press"
        } else if shortcut.modifiers.contains("option") && shortcut.modifiers.contains("cmd") {
            return "Alternative option"
        } else if shortcut.modifiers.contains("ctrl") && shortcut.modifiers.contains("cmd") {
            return "Less common combination"
        }
        return "Custom combination"
    }
}

struct ModifierToggle: View {
    let modifier: String
    let displayName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(displayName)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}