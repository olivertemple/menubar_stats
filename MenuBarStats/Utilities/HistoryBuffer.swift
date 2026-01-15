import Foundation

/// A circular buffer for storing historical data points for sparklines
class HistoryBuffer<T> {
    private var buffer: [T]
    private var currentIndex: Int = 0
    private var isFull: Bool = false
    let capacity: Int
    
    init(capacity: Int) {
        self.capacity = max(capacity, 1)
        self.buffer = []
        self.buffer.reserveCapacity(self.capacity)
    }
    
    /// Add a new data point to the buffer
    func add(_ value: T) {
        if buffer.count < capacity {
            buffer.append(value)
        } else {
            buffer[currentIndex] = value
            isFull = true
        }
        
        currentIndex = (currentIndex + 1) % capacity
    }
    
    /// Get all values in chronological order
    func getValues() -> [T] {
        guard !buffer.isEmpty else { return [] }
        
        if !isFull {
            return buffer
        }
        
        // Return values in chronological order (oldest to newest)
        let firstPart = Array(buffer[currentIndex..<capacity])
        let secondPart = Array(buffer[0..<currentIndex])
        return firstPart + secondPart
    }
    
    /// Get the most recent value
    func latest() -> T? {
        guard !buffer.isEmpty else { return nil }
        let latestIndex = currentIndex == 0 ? buffer.count - 1 : currentIndex - 1
        return buffer[latestIndex]
    }
    
    /// Clear all data
    func clear() {
        buffer.removeAll(keepingCapacity: true)
        currentIndex = 0
        isFull = false
    }
    
    /// Number of values currently stored
    var count: Int {
        return buffer.count
    }
}
