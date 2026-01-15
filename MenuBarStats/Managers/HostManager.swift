import Foundation
import Combine

class HostManager: ObservableObject {
    @Published var hosts: [Host] = []
    @Published var selectedHostId: UUID
    
    private let hostsKey = "hosts"
    private let selectedHostIdKey = "selectedHostId"
    
    init() {
        self.selectedHostId = Host.localHost.id
        loadHosts()
    }
    
    func addHost(_ host: Host) {
        hosts.append(host)
        saveHosts()
    }
    
    func updateHost(_ host: Host) {
        if let index = hosts.firstIndex(where: { $0.id == host.id }) {
            hosts[index] = host
            saveHosts()
        }
    }
    
    func deleteHost(_ id: UUID) {
        // Prevent deleting the local host
        guard id != Host.localHost.id else { return }
        
        hosts.removeAll { $0.id == id }
        
        // If we deleted the selected host, switch to local
        if selectedHostId == id {
            selectedHostId = Host.localHost.id
        }
        
        saveHosts()
    }
    
    func saveHosts() {
        // Filter out local host before saving (it's always re-added on load)
        let hostsToSave = hosts.filter { $0.id != Host.localHost.id }
        
        if let encoded = try? JSONEncoder().encode(hostsToSave) {
            UserDefaults.standard.set(encoded, forKey: hostsKey)
        }
        
        UserDefaults.standard.set(selectedHostId.uuidString, forKey: selectedHostIdKey)
    }
    
    func loadHosts() {
        var loadedHosts: [Host] = []
        
        // Load saved hosts
        if let data = UserDefaults.standard.data(forKey: hostsKey),
           let decoded = try? JSONDecoder().decode([Host].self, from: data) {
            loadedHosts = decoded
        }
        
        // Always ensure local host is first
        hosts = [Host.localHost] + loadedHosts
        
        // Restore selected host ID
        if let savedIdString = UserDefaults.standard.string(forKey: selectedHostIdKey),
           let savedId = UUID(uuidString: savedIdString),
           hosts.contains(where: { $0.id == savedId }) {
            selectedHostId = savedId
        } else {
            selectedHostId = Host.localHost.id
        }
    }
}
