//
//  ConversionJob.swift
//  EzV
//
//  Created by Omer Khan on 23/08/2026.
//  reach out to me at hello@kanasoftware.com

import Foundation
import Combine

enum JobStatus: Equatable {
    case pending
    case running(progress: Double)   // 0.0 ... 1.0
    case completed(outputSizeMB: Double, savedPct: Double)
    case failed(String)
    case skipped(String)
    case cancelled
}

final class ConversionJob: Identifiable, ObservableObject {
    let id = UUID()
    let sourceURL: URL
    let sourceSizeMB: Double
    @Published var status: JobStatus = .pending

    init(sourceURL: URL) {
        self.sourceURL = sourceURL
        let bytes = (try? sourceURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        self.sourceSizeMB = Double(bytes) / (1024 * 1024)
    }

    var fileName: String { sourceURL.lastPathComponent }
}
