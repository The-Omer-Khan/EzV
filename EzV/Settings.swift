//
//  Settings.swift
//  EzV
//
//  Created by Omer Khan on 23/08/2026.
//

import Foundation

struct EncodeSettings {
    var crf: Int = 23
    var maxHeight: MaxHeight = .p1080
    var preset: Preset = .slow
    var deleteSourceOnSuccess: Bool = false

    enum MaxHeight: String, CaseIterable, Identifiable {
        case keep = "Keep original"
        case p2160 = "2160"
        case p1440 = "1440"
        case p1080 = "1080"
        case p720  = "720"
        case p480  = "480"
        var id: String { rawValue }
    }

    enum Preset: String, CaseIterable, Identifiable {
        case ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
        var id: String { rawValue }
    }
}
