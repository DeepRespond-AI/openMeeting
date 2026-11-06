import CoreMedia
import Foundation
import ReplayKit

/// Broadcast Upload Extension for system-audio capture ("内录").
///
/// Receives `.audioApp` (+ optional `.audioMic`) sample buffers, converts both to mono Float32
/// at the configured rate, mixes them on a wall-clock-paced timer (zero-padding an input with
/// no data, e.g. app audio while nothing plays, so output duration equals real time) and writes
/// one PCM16 chunk file per tick into the App Group container. The app is told about new chunks
/// with Darwin notifications. See BroadcastProtocol.swift for the shared protocol.
///
/// Memory: two small ring buffers (`maxBufferMs` each) and one chunk at a time — far below the
/// ~50 MB extension limit. Video sample buffers are ignored.
final class SampleHandler: RPBroadcastSampleHandler {
  private var config: BroadcastConfig?
  private var appGroup: String?
  private var rootDir: URL?
  private var sessionDir: URL?

  private var appRing: FloatRing?
  private var micRing: FloatRing?
  private var appConverter: MonoConverter?
  private var micConverter: MonoConverter?
  private var mixer: DuckingMixer?

  private let queue = DispatchQueue(label: "SystemAudioBroadcast.mixer", qos: .userInitiated)
  private var timer: DispatchSourceTimer?
  private var startUptime: TimeInterval = 0
  private var emittedSamples = 0
  private var nextIndex = 0
  private var finished = false
  private var observingStop = false

  // MARK: - Broadcast lifecycle

  override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
    guard let group = Bundle.main.object(forInfoDictionaryKey: BroadcastProtocol.appGroupInfoKey) as? String,
      let defaults = UserDefaults(suiteName: group),
      let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
    else {
      finishBroadcastWithError(Self.error(message: nil))
      return
    }
    appGroup = group
    rootDir = container.appendingPathComponent(BroadcastProtocol.rootDirectoryName, isDirectory: true)
    guard let data = defaults.data(forKey: BroadcastProtocol.configKey),
      let cfg = try? JSONDecoder().decode(BroadcastConfig.self, from: data)
    else {
      finishBroadcastWithError(Self.error(message: nil))
      return
    }
    config = cfg
    guard cfg.armed else {
      // Started from Control Center (or the app already gave up waiting).
      writeState(.stopped, reason: .notArmed)
      finishBroadcastWithError(Self.error(message: cfg.notArmedMessage))
      return
    }
    let dir = rootDir!.appendingPathComponent(cfg.sessionId, isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    sessionDir = dir

    let capacity = cfg.sampleRate * cfg.maxBufferMs / 1000
    appRing = FloatRing(capacity: capacity)
    appConverter = MonoConverter(sampleRate: cfg.sampleRate)
    if cfg.includeMicrophone {
      micRing = FloatRing(capacity: capacity)
      micConverter = MonoConverter(sampleRate: cfg.sampleRate)
    }
    mixer = DuckingMixer(config: cfg)

    observeStopRequest(prefix: cfg.notificationPrefix)
    writeState(.running, reason: nil)
    post(.started)
    startTimer(cfg)
  }

  override func broadcastPaused() {
    writeState(.paused, reason: nil)
    post(.paused)
  }

  override func broadcastResumed() {
    writeState(.running, reason: nil)
    post(.resumed)
  }

  override func broadcastFinished() {
    // Stopped by the user from the status bar / Control Center, or by the system.
    finish(reason: .user)
  }

  override func processSampleBuffer(
    _ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType
  ) {
    switch sampleBufferType {
    case .audioApp:
      if let samples = appConverter?.convert(sampleBuffer) { appRing?.write(samples) }
    case .audioMic:
      if let samples = micConverter?.convert(sampleBuffer) { micRing?.write(samples) }
    case .video:
      break
    @unknown default:
      break
    }
  }

  // MARK: - Mixing and chunk files

  private func startTimer(_ cfg: BroadcastConfig) {
    startUptime = ProcessInfo.processInfo.systemUptime + Double(cfg.jitterBufferMs) / 1000
    let t = DispatchSource.makeTimerSource(queue: queue)
    let interval = DispatchTimeInterval.milliseconds(cfg.chunkMs)
    t.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(cfg.frameMs))
    t.setEventHandler { [weak self] in self?.tick() }
    timer = t
    t.resume()
  }

  /// Mixes everything due up to now (minus the jitter buffer) into one chunk file.
  private func tick() {
    guard let cfg = config, var mixer, let appRing, let dir = sessionDir, !finished else { return }
    let elapsed = ProcessInfo.processInfo.systemUptime - startUptime
    guard elapsed > 0 else { return }
    let due = Int(elapsed * Double(cfg.sampleRate)) - emittedSamples
    guard due > 0 else { return }

    let frame = max(1, cfg.sampleRate * cfg.frameMs / 1000)
    var sys = [Float](repeating: 0, count: frame)
    var mic: [Float]? = micRing == nil ? nil : [Float](repeating: 0, count: frame)
    var out = [Float](repeating: 0, count: frame)
    var chunk = Data(capacity: due * 2)
    var remaining = due
    while remaining > 0 {
      let n = min(frame, remaining)
      appRing.readPadded(into: &sys, count: n)
      if mic != nil { micRing?.readPadded(into: &mic!, count: n) }
      mixer.mix(mic: mic, sys: sys, out: &out, count: n)
      chunk.append(pcm16LittleEndian(out, count: n))
      remaining -= n
    }
    self.mixer = mixer
    emittedSamples += due
    writeChunk(chunk, dir: dir, maxPending: cfg.maxPendingChunks)
  }

  private func writeChunk(_ data: Data, dir: URL, maxPending: Int) {
    let index = nextIndex
    let name = BroadcastProtocol.chunkFileName(index)
    let tmp = dir.appendingPathComponent(name + BroadcastProtocol.tmpSuffix)
    do {
      try data.write(to: tmp)
      try FileManager.default.moveItem(at: tmp, to: dir.appendingPathComponent(name))
    } catch {
      try? FileManager.default.removeItem(at: tmp)
      return
    }
    nextIndex += 1
    trimBacklog(dir: dir, maxPending: maxPending)
    post(.chunk)
  }

  /// Drops the oldest unread chunks when the app is not consuming (e.g. it was suspended).
  private func trimBacklog(dir: URL, maxPending: Int) {
    guard maxPending > 0,
      let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path)
    else { return }
    let indices = names.compactMap(BroadcastProtocol.chunkIndex(fileName:)).sorted()
    guard indices.count > maxPending else { return }
    for index in indices.prefix(indices.count - maxPending) {
      try? FileManager.default.removeItem(
        at: dir.appendingPathComponent(BroadcastProtocol.chunkFileName(index)))
    }
  }

  // MARK: - Stop

  private func finish(reason: BroadcastProtocol.StopReason) {
    queue.sync {
      guard !finished else { return }
      tick()  // flush what is due
      finished = true
      timer?.cancel()
      timer = nil
    }
    stopObservingStopRequest()
    writeState(.stopped, reason: reason)
    post(.stopped)
  }

  private func observeStopRequest(prefix: String) {
    observingStop = true
    CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque(),
      { _, observer, _, _, _ in
        guard let observer else { return }
        Unmanaged<SampleHandler>.fromOpaque(observer).takeUnretainedValue().handleStopRequest()
      },
      BroadcastProtocol.notificationName(prefix: prefix, .requestStop) as CFString, nil,
      .deliverImmediately)
  }

  private func stopObservingStopRequest() {
    guard observingStop else { return }
    observingStop = false
    CFNotificationCenterRemoveEveryObserver(
      CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque())
  }

  private func handleStopRequest() {
    guard let group = appGroup, let defaults = UserDefaults(suiteName: group),
      defaults.bool(forKey: BroadcastProtocol.stopRequestedKey)
    else { return }
    defaults.set(false, forKey: BroadcastProtocol.stopRequestedKey)
    finish(reason: .requested)
    // iOS has no API to end a broadcast silently; the message is shown in a system alert.
    finishBroadcastWithError(Self.error(message: config?.stopMessage))
  }

  // MARK: - Helpers

  private func writeState(_ status: BroadcastProtocol.Status, reason: BroadcastProtocol.StopReason?) {
    guard let root = rootDir, let cfg = config else { return }
    let state = BroadcastState(
      sessionId: cfg.sessionId, status: status, reason: reason, lastIndex: nextIndex - 1,
      updatedAt: Date().timeIntervalSince1970)
    try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    if let data = try? JSONEncoder().encode(state) {
      try? data.write(to: root.appendingPathComponent(BroadcastProtocol.stateFileName), options: .atomic)
    }
  }

  private func post(_ n: BroadcastProtocol.Notification) {
    guard let prefix = config?.notificationPrefix else { return }
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(BroadcastProtocol.notificationName(prefix: prefix, n) as CFString), nil,
      nil, true)
  }

  private static func error(message: String?) -> NSError {
    var info: [String: Any] = [:]
    if let message, !message.isEmpty { info[NSLocalizedDescriptionKey] = message }
    return NSError(domain: Bundle.main.bundleIdentifier ?? "BroadcastExtension", code: 0, userInfo: info)
  }
}
