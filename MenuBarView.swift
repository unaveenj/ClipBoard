import SwiftUI
import AppKit

// MARK: - MenuBarView

struct MenuBarView: View {
    @ObservedObject var historyManager: HistoryManager
    @ObservedObject var settings: SettingsManager
    let onCopy: (ClipboardItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            contentList
            Divider()
            settingsFooter
        }
        .frame(width: 320)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("ClipBoard")
                .font(.headline)
            Spacer()
            Button("Clear All") {
                historyManager.clear()
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: Content

    @ViewBuilder
    private var contentList: some View {
        if historyManager.items.isEmpty {
            Text("No clipboard items yet.\nCopy something to get started.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .font(.subheadline)
                .padding(24)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(historyManager.items.reversed()) { item in
                        ItemRowView(item: item, onCopy: onCopy) {
                            historyManager.removeItem(item)
                        }
                        Divider()
                            .padding(.leading, 12)
                    }
                }
            }
            .frame(maxHeight: 380)
        }
    }

    // MARK: Settings Footer

    private var settingsFooter: some View {
        VStack(spacing: 0) {
            HStack {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                Spacer()
                HStack(spacing: 4) {
                    Text("Limit:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Stepper(
                        "\(settings.maxHistoryItems)",
                        value: $settings.maxHistoryItems,
                        in: 5...100,
                        step: 5
                    )
                    .font(.caption)
                }
            }
            Divider()
            HStack {
                QuitButton()
                Spacer()
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - QuitButton

private struct QuitButton: View {
    var body: some View {
        Button(action: { NSApp.terminate(nil) }) {
            Label("Quit ClipBoard", systemImage: "power")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ItemRowView

private struct ItemRowView: View {
    let item: ClipboardItem
    let onCopy: (ClipboardItem) -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var copied    = false   // drives the feedback animation

    var body: some View {
        HStack(spacing: 10) {
            thumbnail
            details
            Spacer()
            trailingAction
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.06) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { handleCopy() }
    }

    // MARK: Thumbnail

    @ViewBuilder
    private var thumbnail: some View {
        if item.type == "image" {
            if let nsImage = NSImage(contentsOfFile: item.content) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "photo")
                    .frame(width: 40, height: 40)
                    .foregroundColor(.secondary)
            }
        } else {
            Image(systemName: "doc.on.clipboard")
                .frame(width: 24, height: 24)
                .foregroundColor(.accentColor)
                .padding(.horizontal, 8)
        }
    }

    // MARK: Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            if item.type == "image" {
                Text(URL(fileURLWithPath: item.content).lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)
                Text("Screenshot")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text(item.content)
                    .font(.subheadline)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
        }
    }

    // MARK: Trailing action (delete / copied feedback)

    @ViewBuilder
    private var trailingAction: some View {
        if copied {
            // Green checkmark — fades in, stays briefly, then disappears
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .transition(.scale.combined(with: .opacity))
        } else if isHovered {
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Copy

    private func handleCopy() {
        onCopy(item)
        withAnimation(.easeOut(duration: 0.15)) { copied = true }
        // Reset after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.2)) { copied = false }
        }
    }
}
