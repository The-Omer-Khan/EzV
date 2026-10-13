//
//  ContentView.swift
//  EzV
//
//  Created by Omer Khan on 23/08/2026.
//  reach out to me at hello@kanasoftware.com

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var engine: ConversionEngine
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            HSplitView {
                VStack(spacing: 12) {
                    dropZone
                    fileList
                }
                .padding(12)
                .frame(minWidth: 380)

                VStack(spacing: 12) {
                    settingsPanel
                    logPanel
                }
                .padding(12)
                .frame(minWidth: 300)
            }

            Divider()
            bottomBar
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MOV Compressor")
                    .font(.title2).bold()
                Text("Batch compress screen recordings with ffmpeg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }

    // MARK: - Drop zone

    private var dropZone: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(
                isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .frame(height: 90)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Drop .mov files or a folder here")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Browse…") { browse() }
                        .buttonStyle(.link)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers)
            }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url { urls.append(url) }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            engine.addFiles(urls)
        }
        return true
    }

    private func browse() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [UTType.movie, UTType.folder]
        if panel.runModal() == .OK {
            engine.addFiles(panel.urls)
        }
    }

    // MARK: - File list

    private var fileList: some View {
        Group {
            if engine.jobs.isEmpty {
                VStack {
                    Spacer()
                    Text("No files queued")
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(engine.jobs) { job in
                    JobRow(job: job)
                }
                .listStyle(.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Settings

    private var settingsPanel: some View {
        GroupBox("Encoding") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Quality (CRF)")
                        Spacer()
                        Text("\(engine.settings.crf)")
                            .monospacedDigit()
                            .foregroundStyle(.tint)
                            .bold()
                    }
                    Slider(
                        value: Binding(
                            get: { Double(engine.settings.crf) },
                            set: { engine.settings.crf = Int($0) }
                        ),
                        in: 18...32, step: 1
                    )
                    Text("Lower = better quality  •  23 is default  •  28+ noticeable loss")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Picker("Max height", selection: $engine.settings.maxHeight) {
                        ForEach(EncodeSettings.MaxHeight.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Preset", selection: $engine.settings.preset) {
                        ForEach(EncodeSettings.Preset.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Toggle("Move source to Trash on success", isOn: $engine.settings.deleteSourceOnSuccess)

                HStack {
                    Button(engine.outputDirectory == nil ? "Set output folder…" : "Change output folder…") {
                        pickOutputFolder()
                    }
                    if engine.outputDirectory != nil {
                        Button("Reset") { engine.outputDirectory = nil }
                    }
                }
                if let out = engine.outputDirectory {
                    Text(out.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Output next to source files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(6)
        }
    }

    private func pickOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            engine.outputDirectory = panel.url
        }
    }

    // MARK: - Log

    private var logPanel: some View {
        GroupBox("Log") {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        ForEach(engine.logs) { entry in
                            Text(entry.message)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(color(for: entry.level))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(entry.id)
                        }
                    }
                    .padding(6)
                }
                .onChange(of: engine.logs.count) { _, _ in
                    if let last = engine.logs.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .frame(minHeight: 160)
        }
    }

    private func color(for level: ConversionEngine.LogEntry.Level) -> Color {
        switch level {
        case .info:    .primary
        case .success: .green
        case .warning: .orange
        case .error:   .red
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack {
            let done = engine.jobs.filter { if case .completed = $0.status { true } else { false } }.count
            let total = engine.jobs.count
            Text(total == 0 ? "No files" : "\(done) of \(total) complete")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Clear finished") { engine.clearCompleted() }
                .disabled(engine.isRunning)

            if engine.isRunning {
                Button("Cancel", role: .destructive) { engine.cancel() }
            } else {
                Button("Start conversion") { engine.start() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(engine.jobs.isEmpty)
            }
        }
        .padding(12)
    }
}

// MARK: - Job row

struct JobRow: View {
    @ObservedObject var job: ConversionJob

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(job.fileName)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text(String(format: "%.1f MB", job.sourceSizeMB))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            statusView
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusView: some View {
        switch job.status {
        case .pending:
            Text("Pending")
                .font(.caption).foregroundStyle(.secondary)
        case .running(let p):
            ProgressView(value: p)
                .progressViewStyle(.linear)
        case .completed(let mb, let saved):
            Text(String(format: "✓ %.1f MB  (%+.0f%%)", mb, -saved))
                .font(.caption).foregroundStyle(.green)
        case .failed(let msg):
            Text("✗ \(msg)").font(.caption).foregroundStyle(.red)
        case .skipped(let msg):
            Text("↷ \(msg)").font(.caption).foregroundStyle(.orange)
        case .cancelled:
            Text("Cancelled").font(.caption).foregroundStyle(.secondary)
        }
    }
}


// What are you looking for :P
