//
//  FFmpegRunner.swift
//  EzV
//
//  Created by Omer Khan on 23/08/2026.
//

import Foundation

final class FFmpegRunner {
    private var process: Process?

    static var ffmpegURL: URL? {
        Bundle.main.url(forResource: "ffmpeg", withExtension: nil)
    }
    static var ffprobeURL: URL? {
        Bundle.main.url(forResource: "ffprobe", withExtension: nil)
    }

    /// Probe duration in seconds via ffprobe.
    static func probeDuration(of url: URL) async -> Double? {
        guard let ffprobe = ffprobeURL else { return nil }
        let p = Process()
        p.executableURL = ffprobe
        p.arguments = [
            "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            url.path
        ]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = Pipe()
        do {
            try p.run()
            p.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let str = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return Double(str)
        } catch {
            return nil
        }
    }

    /// Runs ffmpeg. Progress callback fires with 0.0 - 1.0 (fraction of this file).
    /// Returns true on success.
    func run(
        source: URL,
        destination: URL,
        settings: EncodeSettings,
        duration: Double?,
        onProgress: @escaping (Double) -> Void,
        onLog: @escaping (String) -> Void
    ) async -> Bool {
        guard let ffmpeg = Self.ffmpegURL else {
            onLog("ffmpeg binary not found in app bundle.")
            return false
        }

        var args: [String] = [
            "-nostdin", "-hide_banner", "-loglevel", "error",
            "-progress", "pipe:1", "-y",
            "-i", source.path
        ]
        if settings.maxHeight != .keep {
            args += ["-vf", "scale=-2:'min(\(settings.maxHeight.rawValue),ih)'"]
        }
        args += [
            "-c:v", "libx264",
            "-preset", settings.preset.rawValue,
            "-crf", String(settings.crf),
            "-c:a", "aac",
            "-b:a", "192k",
            destination.path
        ]

        let p = Process()
        p.executableURL = ffmpeg
        p.arguments = args

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        p.standardOutput = stdoutPipe
        p.standardError  = stderrPipe
        self.process = p

        var stderrBuffer = ""
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let s = String(data: data, encoding: .utf8), !s.isEmpty {
                stderrBuffer += s
            }
        }

        // Parse -progress key=value stream from stdout.
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard let s = String(data: data, encoding: .utf8), !s.isEmpty else { return }
            for line in s.split(separator: "\n") {
                if line.hasPrefix("out_time_us="), let d = duration, d > 0 {
                    let value = line.dropFirst("out_time_us=".count)
                    if let us = Int64(value.trimmingCharacters(in: .whitespaces)) {
                        let frac = min(1.0, (Double(us) / 1_000_000.0) / d)
                        onProgress(frac)
                    }
                }
            }
        }

        do {
            try p.run()
        } catch {
            onLog("Failed to launch ffmpeg: \(error.localizedDescription)")
            return false
        }

        // Wait off the main thread.
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            p.terminationHandler = { _ in cont.resume() }
        }

        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil
        self.process = nil

        if p.terminationStatus != 0 {
            let lastLine = stderrBuffer
                .split(separator: "\n")
                .last
                .map(String.init) ?? "unknown error"
            onLog("ffmpeg: \(lastLine)")
            return false
        }
        return true
    }

    func cancel() {
        process?.terminate()
    }
}
