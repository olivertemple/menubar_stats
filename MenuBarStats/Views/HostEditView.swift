import SwiftUI

struct HostEditView: View {
    enum Mode {
        case add
        case edit(Host)
        
        var title: String {
            switch self {
            case .add:
                return "Add Remote Host"
            case .edit:
                return "Edit Host"
            }
        }
    }
    
    let mode: Mode
    @ObservedObject var hostManager: HostManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var baseURL: String = ""
    @State private var token: String = ""
    @State private var enabled: Bool = true
    @State private var connectionMode: Host.ConnectionMode = .agent
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(mode: Mode, hostManager: HostManager) {
        self.mode = mode
        self.hostManager = hostManager
        
        if case .edit(let host) = mode {
            _name = State(initialValue: host.name)
            _baseURL = State(initialValue: host.baseURL ?? "")
            _token = State(initialValue: host.token ?? "")
            _enabled = State(initialValue: host.enabled)
            _connectionMode = State(initialValue: host.connectionMode)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(mode.title)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Form
            Form {
                Section {
                    TextField("Host Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Base URL", text: $baseURL)
                        .textFieldStyle(.roundedBorder)
                        .help(connectionMode == .agent ? 
                              "Example: http://100.x.y.z:9955 or https://stats.domain.tld" :
                              "Example: http://truenas.local or https://truenas.domain.tld")
                    
                    Text(connectionMode == .agent ?
                         "Example: http://100.x.y.z:9955 (Go agent endpoint)" :
                         "Example: http://truenas.local (TrueNAS web interface)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Picker("Connection Type", selection: $connectionMode) {
                        Text("Go Agent").tag(Host.ConnectionMode.agent)
                        Text("TrueNAS API").tag(Host.ConnectionMode.truenasAPI)
                    }
                    .pickerStyle(.segmented)
                    
                    Text(connectionMode == .agent ?
                         "Connect to the lightweight Go agent running on the host" :
                         "Connect directly to TrueNAS API (for VMs without host access)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                } header: {
                    Text("Host Information")
                        .font(.headline)
                }
                .padding(.bottom, 12)
                
                Section {
                    SecureField(connectionMode == .agent ? "Token (optional)" : "API Key (optional)", text: $token)
                        .textFieldStyle(.roundedBorder)
                    
                    Text(connectionMode == .agent ?
                         "Enter ****** token if required by the Go agent" :
                         "Enter TrueNAS API key from Settings > API Keys")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                } header: {
                    Text("Authentication")
                        .font(.headline)
                }
                .padding(.bottom, 12)
                
                Section {
                    Toggle("Enabled", isOn: $enabled)
                        .toggleStyle(.switch)
                    
                    Text("Disabled hosts will not be polled for stats")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                } header: {
                    Text("Settings")
                        .font(.headline)
                }
            }
            .formStyle(.grouped)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
            
            // Footer with Save button
            HStack {
                Spacer()
                
                Button("Save") {
                    saveHost()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: 500, height: 450)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !baseURL.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveHost() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedURL = baseURL.trimmingCharacters(in: .whitespaces)
        let trimmedToken = token.trimmingCharacters(in: .whitespaces)
        
        // Basic URL validation
        guard let _ = URL(string: trimmedURL) else {
            errorMessage = "Invalid URL format"
            showingError = true
            return
        }
        
        switch mode {
        case .add:
            let newHost = Host.createRemote(
                name: trimmedName,
                baseURL: trimmedURL,
                token: trimmedToken.isEmpty ? nil : trimmedToken,
                connectionMode: connectionMode
            )
            var mutableHost = newHost
            mutableHost.enabled = enabled
            hostManager.addHost(mutableHost)
            
        case .edit(let existingHost):
            var updatedHost = existingHost
            updatedHost.name = trimmedName
            updatedHost.baseURL = trimmedURL
            updatedHost.token = trimmedToken.isEmpty ? nil : trimmedToken
            updatedHost.enabled = enabled
            updatedHost.connectionMode = connectionMode
            hostManager.updateHost(updatedHost)
        }
        
        dismiss()
    }
}
