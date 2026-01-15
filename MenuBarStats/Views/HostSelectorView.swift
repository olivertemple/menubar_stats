import SwiftUI

struct HostSelectorView: View {
    @EnvironmentObject var hostManager: HostManager
    
    var enabledHosts: [Host] {
        hostManager.hosts.filter { $0.enabled }
    }
    
    var body: some View {
        if enabledHosts.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(enabledHosts) { host in
                        HostButton(
                            host: host,
                            isSelected: host.id == hostManager.selectedHostId,
                            action: {
                                hostManager.selectedHostId = host.id
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }
}

struct HostButton: View {
    let host: Host
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor(for: host.status))
                    .frame(width: 6, height: 6)
                
                Text(host.name)
                    .font(.system(.footnote, design: .rounded))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : (isHovered ? Color.gray.opacity(0.1) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func statusColor(for status: Host.HostStatus) -> Color {
        switch status {
        case .online:
            return .green
        case .offline:
            return .red
        case .unknown:
            return .gray
        }
    }
}
