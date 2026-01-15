import SwiftUI

struct TestConnectionView: View {
    let host: Host
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = true
    @State private var success = false
    @State private var latency: TimeInterval = 0
    @State private var errorMessage: String?
    @State private var healthInfo: HealthResponse?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Test Connection")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Content
            VStack(spacing: 20) {
                // Host info
                VStack(spacing: 6) {
                    Text(host.name)
                        .font(.system(.headline, design: .rounded))
                    
                    if let baseURL = host.baseURL {
                        Text(baseURL)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Status display
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(.circular)
                        
                        Text("Testing connection...")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                } else if success {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("Connected Successfully")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 8) {
                            if let health = healthInfo {
                                HStack {
                                    Text("Agent Version:")
                                        .foregroundColor(.secondary)
                                    Text(health.agentVersion ?? "Unknown")
                                }
                                .font(.system(.caption, design: .rounded))
                                
                                if let hostname = health.hostname {
                                    HStack {
                                        Text("Hostname:")
                                            .foregroundColor(.secondary)
                                        Text(hostname)
                                    }
                                    .font(.system(.caption, design: .rounded))
                                }
                            }
                            
                            HStack {
                                Text("Latency:")
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.0f ms", latency * 1000))
                            }
                            .font(.system(.caption, design: .rounded))
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        
                        Text("Connection Failed")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.red)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: 350)
        .task {
            await testConnection()
        }
    }
    
    private func testConnection() async {
        guard host.type == .remote else {
            // Local host is always online
            success = true
            isLoading = false
            latency = 0
            return
        }
        
        let startTime = Date()
        
        do {
            if host.connectionMode == .truenasAPI {
                // Test TrueNAS API connection
                let client = TrueNASAPIClient(baseURL: host.baseURL ?? "", apiKey: host.token)
                let systemInfo = try await client.testConnection()
                latency = Date().timeIntervalSince(startTime)
                healthInfo = HealthResponse(
                    ok: true,
                    schema: "v1",
                    agentVersion: "TrueNAS-\(systemInfo.version)",
                    hostname: systemInfo.hostname
                )
                success = true
            } else {
                // Test Go agent connection
                let client = RemoteStatsClient()
                let result = try await client.testConnection(baseURL: host.baseURL ?? "", token: host.token)
                latency = result.latency
                healthInfo = result.health
                success = true
            }
        } catch let error as RemoteStatsError {
            errorMessage = error.errorDescription
            success = false
        } catch let error as TrueNASAPIClient.TrueNASError {
            switch error {
            case .invalidURL:
                errorMessage = "Invalid URL format"
            case .networkError(let networkError):
                errorMessage = "Network error: \(networkError.localizedDescription)"
            case .authenticationFailed:
                errorMessage = "Authentication failed. Check your API key."
            case .invalidResponse:
                errorMessage = "Invalid response from TrueNAS"
            case .decodingError(let decodingError):
                errorMessage = "Failed to parse response: \(decodingError.localizedDescription)"
            case .unsupportedVersion:
                errorMessage = "Unsupported TrueNAS version"
            }
            success = false
        } catch {
            errorMessage = error.localizedDescription
            success = false
        }
        
        isLoading = false
    }
}
