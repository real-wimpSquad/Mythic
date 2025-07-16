//
//  SteamInterface.swift
//  Mythic
//
//  Created by Esiayo Alegbe on 27/7/2024.
//

// Reference: https://developer.valvesoftware.com/wiki/SteamCMD

// TODO: steamcmd autoupdater parser
// TODO: use licenses_print to get all available games' IDs -- see steam-cli GH src for more ino
// TODO: onetap steam gui installer -- for DRM
// TODO: user-interactive shell?
// TODO: use find <command> to search for other commands -- steamcmd docs are literally nonexistent

import Foundation
import OSLog

final class Steam {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Mythic", category: "steam")

    private static let fileManager = FileManager.default

    private static let directory: URL = {
        guard let appHome = Bundle.appHome else {
            fatalError("Missing app home directory")
        }
        return appHome.appendingPathComponent("Steam", isDirectory: true)
    }()

    private static let steamcmdURL = directory.appendingPathComponent("steamcmd")

    /// Returns true if the SteamCMD binary is installed.
    static var isInstalled: Bool {
        fileManager.fileExists(atPath: steamcmdURL.path)
    }

    /// Installs SteamCMD by downloading and extracting it into the local Steam directory.
    static func install() async throws {
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            logger.info("Created Steam directory at \(directory.path, privacy: .public)")
        }

        let command = """
        curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf - -C "\(directory.path)"
        """

        logger.info("Starting SteamCMD install process")
        try Process.execute(
            executableURL: URL(fileURLWithPath: "/bin/bash"),
            arguments: ["-c", command]
        )

        if isInstalled {
            logger.info("SteamCMD installed successfully")
        } else {
            logger.error("SteamCMD installation failed")
        }
    }

    /// Removes the SteamCMD installation by deleting the Steam directory.
    static func uninstall() throws {
        guard fileManager.fileExists(atPath: directory.path) else {
            logger.warning("Steam directory does not exist, skipping uninstall")
            return
        }

        try fileManager.removeItem(at: directory)
        logger.info("Removed Steam directory at \(directory.path, privacy: .public)")
    }
}
