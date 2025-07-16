//
//  SteamTerminalView.swift
//  Mythic
//
//  Created by Jon Sherlin on 7/15/25.
//

import SwiftUI

struct SteamTerminalView: View {
    @Binding var isPresented: Bool

    @State private var output: String = ""
    @State private var inputLine: String = ""
    @State private var isRunning: Bool = false
    @State private var steamUsername: String = ""
    @State private var steamPassword: String = ""
    @State private var isAwaitingSteamGuard: Bool = false
    @State private var needsSteamGuardCode: Bool = false
    
    @FocusState private var focusedField: Field?
    enum Field {
        case username, password
    }

    private let terminal = SteamTerminal()

    var onLoginSuccess: (() -> Void)?
    
    var body: some View {
        VStack {
            if !isRunning {
                Form{
                    Text("Log in to Steam")
                        .font(.title2).bold()
                    VStack {
                        TextField("Username", text: $steamUsername)
                            .focused($focusedField, equals: .username)
                            .textContentType(.username)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .password
                            }
                        
                        SecureField("Password", text: $steamPassword)
                            .focused($focusedField, equals: .password)
                            .textContentType(.password)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled(true)
                            .onSubmit {
                                runLoginCommand()
                            }
                        if isAwaitingSteamGuard {
                            if needsSteamGuardCode {
                                TextField("Steam Guard Code", text: $inputLine, onCommit: sendInput)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                            } else {
                                HStack {
                                    ProgressView()
                                    Text("Waiting for Steam Guard approval in the Steam Mobile app...")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Button("Login to Steam") {
                            runLoginCommand()
                        }
                        .onAppear {
                            focusedField = .username
                        }
                        .keyboardShortcut(.defaultAction)
                        .padding()
                        
                        Button("Close") {
                            isPresented = false
                        }
                        .padding(.bottom)
                    }
                    .padding()
                }
                .frame(maxWidth: 400)
            } else {
                ProgressView("Logging in...")
                    .padding()
                
                Text("First time installation and updates may take a few minutes.")
                    .padding()
            }
        }
        .onDisappear {
            terminal.terminate()
        }
        .frame(minWidth: 500, minHeight: 300)
        
        GroupBox(label: Text("Steamcmd")) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading) {
                        Text(output)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Color.clear
                            .frame(height: 1)
                            .id("BOTTOM")
                    }
                    .padding()
                }
                .onChange(of: output) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        scrollProxy.scrollTo("BOTTOM", anchor: .bottom)
                    }
                }
            }
        }
        .padding([.horizontal, .bottom])
        .frame(height: 140)
    }
    
    private func sendInput() {
        terminal.send(inputLine + "\n")
        inputLine = ""
        
        if isAwaitingSteamGuard {
            isAwaitingSteamGuard = false
        }
    }
    
    private func runLoginCommand() {
        isRunning = true
        output = ""

        terminal
            .onOutput = { line in
            DispatchQueue.main.async {
                output += line
                if line.contains("Steam>") || line.contains("Success!") {
                    onLoginSuccess?()
                    isPresented = false
                    isAwaitingSteamGuard = false
                    needsSteamGuardCode = false
                    isRunning = false
                    terminal.send("force_install_dir ./castle_crashers +app_update 2086680 validate +quit")
                    SteamSession.shared.refresh()
                }
                
                if line.contains("Steam Guard") && !isAwaitingSteamGuard {
                    isAwaitingSteamGuard = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if isRunning {
                            needsSteamGuardCode = true
                        }
                    }
                }
            }
        }

        terminal.launch()
        terminal.send("login \(steamUsername) \(steamPassword)\n")
    }
}
