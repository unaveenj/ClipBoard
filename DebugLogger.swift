import Foundation

// MARK: - DebugLogger
// Wraps print() so logs are emitted in Debug builds only.
// Replace all print() calls with dlog() for zero-overhead Release builds.

func dlog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}
