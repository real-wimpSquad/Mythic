//
//  SteamAuthView.swift
//  Mythic
//
//  Created by Jon Sherlin on 7/15/25.
//

import SwiftUI

struct SteamAuthView: View {
    @Binding var isPresented: Bool
    @Binding var isLoginSuccessful: Bool

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Steam Login")
                .font(.title2).bold()

            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let status = statusMessage {
             Text(status)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }

            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                } else {
                    Button("Log In") {
                        Task { await attemptSteamLogin() }
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 300)
    }

    private func attemptSteamLogin() async {
        isLoading = true
        errorMessage = nil
        statusMessage = "Checking SteamCMD installation..."

        do {
            if !Steam.isInstalled {
                statusMessage = "Installing SteamCMD..."
                try await Steam.install()
            }
            
            statusMessage = "Logging into Steam..."
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["steamcmd", "+login", username, password, "+quit"]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: data, as: UTF8.self)

            if output.contains("Waiting for user info...OK") || output.contains("Steam>") {
                isLoginSuccessful = true
                isPresented = false
            } else {
                errorMessage = "Login failed. Check your username, password, or Steam Guard."
            }
        } catch {
            errorMessage = "Failed to launch steamcmd."
        }

        statusMessage = nil
        isLoading = false
    }
}
