import SwiftUI

struct HostManagementView: View {
    @EnvironmentObject var hostManager: HostManager
    @State private var showingAddHost = false
    @State private var hostToEdit: Host?
    @State private var hostToTest: Host?
    @State private var showingDeleteAlert = false
    @State private var hostToDelete: Host?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Add button
            HStack {
                Text("Hosts")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    showingAddHost = true
                }) {
                    Label("Add Host", systemImage: "plus.circle.fill")
                        .font(.system(.body, design: .rounded))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Host list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(hostManager.hosts) { host in
                        HostRowView(
                            host: host,
                            onEdit: {
                                if host.type != .local {
                                    hostToEdit = host
                                }
                            },
                            onDelete: {
                                if host.type != .local {
                                    hostToDelete = host
                                    showingDeleteAlert = true
                                }
                            },
                            onTest: {
                                hostToTest = host
                            }
                        )
                    }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showingAddHost) {
            HostEditView(mode: .add, hostManager: hostManager)
        }
        .sheet(item: $hostToEdit) { host in
            HostEditView(mode: .edit(host), hostManager: hostManager)
        }
        .sheet(item: $hostToTest) { host in
            TestConnectionView(host: host)
        }
        .alert("Delete Host", isPresented: $showingDeleteAlert, presenting: hostToDelete) { host in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                hostManager.deleteHost(host.id)
            }
        } message: { host in
            Text("Are you sure you want to delete '\(host.name)'? This action cannot be undone.")
        }
    }
}

struct HostRowView: View {
    let host: Host
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTest: () -> Void
    
    var body: some View {
        GlassRow {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                
                // Host info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(host.name)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        
                        if host.type == .local {
                            Text("LOCAL")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(4)
                        } else if !host.enabled {
                            Text("DISABLED")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                    
                    if let baseURL = host.baseURL {
                        Text(baseURL)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let lastSeen = host.lastSeen {
                        Text("Last seen: \(formatRelativeTime(lastSeen))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    } else if host.type == .remote {
                        Text("Never connected")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    if let error = host.lastError {
                        Text("⚠️ \(error)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.orange)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    Button(action: onTest) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Test Connection")
                    
                    if host.type != .local {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("Edit Host")
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Delete Host")
                    }
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch host.status {
        case .online:
            return .green
        case .offline:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
