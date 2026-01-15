import SwiftUI

struct HostSelectorView: View {
    @EnvironmentObject var hostManager: HostManager
    
    var enabledHosts: [Host] {
        hostManager.hosts.filter { $0.enabled }
    }
    
    var body: some View {
        if enabledHosts.count > 1 {
            Picker("Host", selection: $hostManager.selectedHostId) {
                ForEach(enabledHosts) { host in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor(for: host))
                            .frame(width: 6, height: 6)
                        
                        Text(host.name)
                            .font(.system(.body, design: .rounded))
                    }
                    .tag(host.id)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .padding(.horizontal, 12)
        }
    }
    
    private func statusColor(for host: Host) -> Color {
        switch host.status {
        case .online:
            return .green
        case .offline:
            return .red
        case .unknown:
            return .gray
        }
    }
}
