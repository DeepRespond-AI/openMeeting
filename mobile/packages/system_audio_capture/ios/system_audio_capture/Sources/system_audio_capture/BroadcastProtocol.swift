import Foundation

// Wire protocol between the app (this plugin) and the ReplayKit Broadcast Upload Extension
// (mobile/ios/BroadcastExtension). This file is compiled into BOTH targets: the extension's
// Xcode target references it directly, so the two sides can never drift apart.
//
// Layout inside the App Group container:
//   <root>/state.json                    BroadcastState, written by the extension
//   <root>/<sessionId>/chunk_<index>.pcm  mono PCM16 LE chunks, written tmp → atomic rename
// UserDefaults(suiteName: appGroup):
//   configKey        BroadcastConfig (JSON), written by the app before presenting the picker
//   stopRequestedKey Bool, set by the app before posting `requestStop`
// Darwin notifications: "<notificationPrefix>.broadcast.<name>".

enum BroadcastProtocol {
  /// Info.plist key of the extension holding the App Group identifier (set from the
  /// `DR_APP_GROUP_IDENTIFIER` build setting).
  static let appGroupInfoKey = "DRAppGroupIdentifier"
  static let extensionPointIdentifier = "com.apple.broadcast-services-upload"
  static let rootDirectoryName = "SystemAudioBroadcast"
  static let stateFileName = "state.json"
  static let configKey = "systemAudio.broadcastConfig"
  static let stopRequestedKey = "systemAudio.stopRequested"
  static let chunkPrefix = "chunk_"
  static let chunkSuffix = ".pcm"
  static let tmpSuffix = ".tmp"
  static let chunkIndexDigits = 12

  static func chunkFileName(_ index: Int) -> String {
    let digits = String(index)
    let pad = String(repeating: "0", count: max(0, chunkIndexDigits - digits.count))
    return chunkPrefix + pad + digits + chunkSuffix
  }

  static func chunkIndex(fileName: String) -> Int? {
    guard fileName.hasPrefix(chunkPrefix), fileName.hasSuffix(chunkSuffix) else { return nil }
    return Int(fileName.dropFirst(chunkPrefix.count).dropLast(chunkSuffix.count))
  }

  enum Notification: String, CaseIterable {
    case started, chunk, stopped, paused, resumed, requestStop
  }

  static func notificationName(prefix: String, _ n: Notification) -> String {
    "\(prefix).broadcast.\(n.rawValue)"
  }

  enum Status: String, Codable {
    case running, paused, stopped
  }

  enum StopReason: String, Codable {
    /// The app asked the extension to finish.
    case requested
    /// Stopped by the user from the status bar / Control Center, or by the system.
    case user
    /// Started without the app arming a session (e.g. from Control Center).
    case notArmed
  }
}

/// Session parameters written by the app; all values originate from the app's AppConfig.
struct BroadcastConfig: Codable {
  var sessionId: String
  var armed: Bool
  var notificationPrefix: String
  var sampleRate: Int
  var includeMicrophone: Bool
  var micGain: Double
  var duckingRatio: Double
  var frameMs: Int
  var jitterBufferMs: Int
  var maxBufferMs: Int
  var micActiveRmsThreshold: Double
  var duckingAttackMs: Int
  var duckingReleaseMs: Int
  var softClipKnee: Double
  var chunkMs: Int
  var maxPendingChunks: Int
  var stopMessage: String
  var notArmedMessage: String
}

struct BroadcastState: Codable {
  var sessionId: String
  var status: BroadcastProtocol.Status
  var reason: BroadcastProtocol.StopReason?
  var lastIndex: Int
  var updatedAt: Double
}
