//
//  SteamSession.swift
//  Mythic
//
//  Created by Jon Sherlin on 7/15/25.
//

import Foundation
import OSLog

final class SteamSession: ObservableObject {
    static let shared = SteamSession()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Mythic", category: "steam-session")

    @Published var isSignedIn: Bool = false
    @Published var username: String? = nil

    private let steamDir: URL = {
        guard let home = Bundle.appHome else {
            fatalError("Missing app home directory")
        }
        return home.appendingPathComponent("Steam")
    }()
    
    private var configDir: URL {
        steamDir.appendingPathComponent("config")
    }

    private var configVDF: URL {
        configDir.appendingPathComponent("config.vdf")
    }

    func refresh() {
        if !files.fileExists(atPath: configDir.path) {
            do {
                try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logger.error("Failed to create config directory: \(error)")
                return
            }
        }
        let configPath = configVDF.path
        isSignedIn = FileManager.default.fileExists(atPath: configPath)

        if let contents = try? String(contentsOf: configVDF) {
            let lines = contents.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("\"AutoLoginUser\"") {
                    username = extractVDFValue(from: line)
                    return
                }
            }
        }

        username = nil
    }

    func forget() {
        do {
            if FileManager.default.fileExists(atPath: steamDir.path) {
                try FileManager.default.removeItem(at: steamDir)
                logger.info("Removed Steam credential directory")
            }
        } catch {
            logger.error("Failed to remove Steam directory: \(error.localizedDescription)")
        }

        isSignedIn = false
        username = nil
    }

    private func extractVDFValue(from line: String) -> String? {
        guard let start = line.range(of: "\"", options: .backwards)?.upperBound,
              let end = line.range(of: "\"", range: start..<line.endIndex)?.lowerBound else {
            return nil
        }
        return String(line[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
