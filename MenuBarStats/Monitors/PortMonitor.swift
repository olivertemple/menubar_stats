import Foundation

struct PortInfo: Identifiable, Hashable {
    let id = UUID()
    let port: Int
    let processName: String
    let pid: Int32
    let protocol: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PortInfo, rhs: PortInfo) -> Bool {
        lhs.id == rhs.id
    }
}

class PortMonitor {
    func getOpenPorts() -> [PortInfo] {
        var ports: [PortInfo] = []
        
        // Use lsof to get open ports
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                
                for line in lines.dropFirst() { // Skip header
                    let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    
                    if components.count >= 9 {
                        let processName = components[0]
                        if let pid = Int32(components[1]) {
                            let nameComponent = components[8]
                            
                            // Extract port from format like "*:8080"
                            if let portString = nameComponent.components(separatedBy: ":").last,
                               let port = Int(portString) {
                                let portInfo = PortInfo(
                                    port: port,
                                    processName: processName,
                                    pid: pid,
                                    protocol: "TCP"
                                )
                                ports.append(portInfo)
                            }
                        }
                    }
                }
            }
        } catch {
            // If lsof fails, return empty array
        }
        
        return ports
    }
    
    func killProcess(pid: Int32) -> Bool {
        let result = kill(pid, SIGTERM)
        return result == 0
    }
}
