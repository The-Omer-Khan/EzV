//
//  ConversionEngine.swift
//  EzV
//
//  Created by Omer Khan on 23/08/2026.
//  reach out to me at hello@kanasoftware.com

import Foundation
import SwiftUI
import Combine

@MainActor
final class ConversionEngine: ObservableObject {
    @Published var jobs: [ConversionJob] = []
    @Published var settings = EncodeSettings()
    @Published var isRunning = false
    @Published var logs: [LogEntry] = []
    @Published var outputDirectory: URL?   // if nil, write next to source

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp = Date()
        let message: String
        let level: Level
        enum Level { case info, success, warning, error }
    }

    private var currentRunner: FFmpegRunner?
    private var cancelRequested = false

    // MARK: - Queue management

    func addFiles(_ urls: [URL]) {
        let movs = urls.flatMap(expandMovs)
        for url in movs where !jobs.contains(where: { $0.sourceURL == url }) {
            jobs.append(ConversionJob(sourceURL: url))
        }
    }

    func clearCompleted() {
        jobs.removeAll {
            if case .completed = $0.status { return true }
            if case .skipped   = $0.status { return true }
            return false
        }
    }

    private func expandMovs(_ url: URL) -> [URL] {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return [] }
        if isDir.boolValue {
            let contents = (try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            )) ?? []
            return contents.filter { $0.pathExtension.lowercased() == "mov" }
        } else {
            return url.pathExtension.lowercased() == "mov" ? [url] : []
        }
    }

    // MARK: - Running

    func start() {
        guard !isRunning else { return }
        let pending = jobs.filter { if case .pending = $0.status { true } else { false } }
        guard !pending.isEmpty else { return }
        isRunning = true
        cancelRequested = false
        log("Starting \(pending.count) file(s) • CRF \(settings.crf) • \(settings.maxHeight.rawValue) • \(settings.preset.rawValue)", .info)

        Task { await runQueue(pending) }
    }

    func cancel() {
        cancelRequested = true
        currentRunner?.cancel()
    }

    private func runQueue(_ queue: [ConversionJob]) async {
        for job in queue {
            if cancelRequested {
                job.status = .cancelled
                continue
            }
            await run(job)
        }
        isRunning = false
        currentRunner = nil
        log("Done.", cancelRequested ? .warning : .success)
    }

    private func run(_ job: ConversionJob) async {
        let src = job.sourceURL

        // Security scope for sandboxed access
        let didStart = src.startAccessingSecurityScopedResource()
        defer { if didStart { src.stopAccessingSecurityScopedResource() } }

        // Determine destination
        let destDir = outputDirectory ?? src.deletingLastPathComponent()
        let destURL = destDir
            .appendingPathComponent(src.deletingPathExtension().lastPathComponent)
            .appendingPathExtension("mp4")

        let destScope = outputDirectory?.startAccessingSecurityScopedResource() ?? false
        defer { if destScope { outputDirectory?.stopAccessingSecurityScopedResource() } }

        if FileManager.default.fileExists(atPath: destURL.path) {
            job.status = .skipped("Output already exists")
            log("Skipping \(src.lastPathComponent) — \(destURL.lastPathComponent) exists", .warning)
            return
        }

        job.status = .running(progress: 0)
        log("Converting \(src.lastPathComponent) → \(destURL.lastPathComponent)", .info)

        let duration = await FFmpegRunner.probeDuration(of: src)
        let runner = FFmpegRunner()
        currentRunner = runner

        let ok = await runner.run(
            source: src,
            destination: destURL,
            settings: settings,
            duration: duration,
            onProgress: { [weak job] frac in
                Task { @MainActor in job?.status = .running(progress: frac) }
            },
            onLog: { [weak self] msg in
                Task { @MainActor in self?.log(msg, .error) }
            }
        )

        if ok {
            let outBytes = (try? destURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let outMB = Double(outBytes) / (1024 * 1024)
            let saved = job.sourceSizeMB > 0 ? (1 - outMB / job.sourceSizeMB) * 100 : 0
            job.status = .completed(outputSizeMB: outMB, savedPct: saved)
            log(String(format: "  ✓ %.1f MB (%+.0f%% vs source)", outMB, -saved), .success)

            if settings.deleteSourceOnSuccess {
                try? FileManager.default.trashItem(at: src, resultingItemURL: nil)
            }
        } else {
            try? FileManager.default.removeItem(at: destURL)
            if cancelRequested {
                job.status = .cancelled
            } else {
                job.status = .failed("Conversion failed")
                log("  ✗ Failed", .error)
            }
        }
    }

    private func log(_ msg: String, _ level: LogEntry.Level) {
        logs.append(LogEntry(message: msg, level: level))
        if logs.count > 500 { logs.removeFirst(logs.count - 500) }
    }
}
