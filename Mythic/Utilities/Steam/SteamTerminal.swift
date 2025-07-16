//
//  SteamTerminal.swift
//  Mythic
//
//  Created by Jon Sherlin on 7/15/25.
//

import Foundation

final class SteamTerminal {
    private var process: Process?
    private var inputPipe = Pipe()
    private var outputPipe = Pipe()

    var onOutput: ((String) -> Void)?

    func launch(with arguments: [String] = []) {
        let steamcmdURL = Bundle.appHome!.appendingPathComponent("Steam/steamcmd")
        let steamcmdPath = steamcmdURL.path
        
        if !FileManager.default.fileExists(atPath: steamcmdPath) {
            onOutput?("SteamCMD not found. Installing...\n")
            Task {
                do {
                    try await Steam.install()
                    onOutput?("SteamCMD installed.\n")
                    launch(with: arguments)
                } catch {
                    onOutput?("[Error] Failed to install SteamCMD: \(error)\n")
                }
            }
            return
        }
        
        let process = Process()
        process.executableURL = steamcmdURL
        process.arguments = arguments
        
        let steamHome = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("/Library/Application Support/Mythic/Steam")
        
        try? FileManager.default.createDirectory(at: steamHome, withIntermediateDirectories: true, attributes: nil)
        
        process.currentDirectoryURL = steamHome

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let line = String(data: data, encoding: .utf8) {
                self.onOutput?(line)
            }
        }

        do {
            try process.run()
            self.process = process
        } catch {
            onOutput?("[Error] Failed to start steamcmd: \(error)\n")
        }
    }

    func send(_ command: String) {
        guard let data = command.data(using: .utf8) else { return }
        inputPipe.fileHandleForWriting.write(data)
    }

    func terminate() {
        process?.terminate()
    }
}
