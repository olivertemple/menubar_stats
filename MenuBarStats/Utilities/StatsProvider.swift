import Foundation

/// Protocol for all stats providers to conform to
protocol StatsProvider {
    associatedtype StatsType
    
    /// Get the current stats
    func getStats() -> StatsType
    
    /// Optional: Reset/initialize the provider
    func reset()
}

extension StatsProvider {
    func reset() {
        // Default implementation - do nothing
    }
}
