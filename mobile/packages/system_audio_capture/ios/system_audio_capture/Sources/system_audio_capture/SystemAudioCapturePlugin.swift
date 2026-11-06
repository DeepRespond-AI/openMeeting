import AVFoundation
import Flutter
import ReplayKit
import UIKit

/// iOS side of `system_audio_capture` (main app).
///
/// iOS can only capture other apps' audio through a ReplayKit Broadcast Upload Extension that
/// the user starts from the system broadcast picker. This class arms a session in the App Group
/// (config in shared UserDefaults), presents the picker, waits for the extension's `started`
/// Darwin notification and then returns the chunk directory; the Dart side reads the chunks.
/// Stop: the app sets `stopRequested` and posts `requestStop` — the extension then finishes the
/// broadcast itself (iOS offers no API to stop someone else's broadcast).
///
/// State machine: idle → starting → capturing → stopping → idle.
public class SystemAudioCapturePlugin: NSObject, FlutterPlugin {
  private enum State { case idle, starting, capturing, stopping }

  private struct ExtensionInfo {
    let bundleId: String
    let appGroup: String
  }

  private static let channelPrefix = "cn.deeprespond.system_audio_capture"

  private var state = State.idle
  private let eventStream = EventStreamHandler()
  private var pendingStart: FlutterResult?
  private var pendingStop: [FlutterResult] = []
  private var startTimer: Timer?
  private var stopTimer: Timer?
  private var picker: UIView?
  private var session: (info: ExtensionInfo, config: BroadcastConfig, sessionDir: URL, rootDir: URL)?
  private var observing = false
  private var keepAlive: AVAudioEngine?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SystemAudioCapturePlugin()
    let method = FlutterMethodChannel(
      name: "\(channelPrefix)/method", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: method)
    // PCM and level are produced by the Dart chunk reader on iOS; the channels exist so that
    // listening to them is a no-op rather than a MissingPluginException.
    FlutterEventChannel(name: "\(channelPrefix)/pcm", binaryMessenger: registrar.messenger())
      .setStreamHandler(EventStreamHandler())
    FlutterEventChannel(name: "\(channelPrefix)/level", binaryMessenger: registrar.messenger())
      .setStreamHandler(EventStreamHandler())
    FlutterEventChannel(name: "\(channelPrefix)/events", binaryMessenger: registrar.messenger())
      .setStreamHandler(instance.eventStream)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "availability":
      result(availability())
    case "start":
      start(args: call.arguments as? [String: Any] ?? [:], result: result)
    case "pause", "resume":
      result(nil)  // Chunks keep flowing; the Dart side drops them while paused.
    case "stop":
      stop(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    if state == .capturing || state == .starting { requestExtensionStop() }
    teardown()
  }

  // MARK: - Availability

  private func availability() -> String {
    #if targetEnvironment(simulator)
      return "unsupported"
    #else
      guard let info = Self.findExtension(),
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: info.appGroup)
          != nil
      else { return "unsupported" }
      return "available"
    #endif
  }

  /// The embedded broadcast upload extension and its App Group (from its Info.plist).
  private static func findExtension() -> ExtensionInfo? {
    guard let plugins = Bundle.main.builtInPlugInsURL,
      let urls = try? FileManager.default.contentsOfDirectory(
        at: plugins, includingPropertiesForKeys: nil)
    else { return nil }
    for url in urls where url.pathExtension == "appex" {
      guard let bundle = Bundle(url: url), let id = bundle.bundleIdentifier,
        let ext = bundle.infoDictionary?["NSExtension"] as? [String: Any],
        ext["NSExtensionPointIdentifier"] as? String == BroadcastProtocol.extensionPointIdentifier,
        let group = bundle.infoDictionary?[BroadcastProtocol.appGroupInfoKey] as? String,
        !group.isEmpty
      else { continue }
      return ExtensionInfo(bundleId: id, appGroup: group)
    }
    return nil
  }

  // MARK: - Start

  private func start(args: [String: Any], result: @escaping FlutterResult) {
    #if targetEnvironment(simulator)
      result(FlutterError(code: "unsupported", message: "simulator", details: nil))
      return
    #else
      guard state == .idle else {
        result(FlutterError(code: "busy", message: "capture in progress", details: nil))
        return
      }
      guard let info = Self.findExtension(),
        let container = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: info.appGroup),
        let defaults = UserDefaults(suiteName: info.appGroup)
      else {
        result(FlutterError(code: "unsupported", message: "broadcast extension or App Group missing", details: nil))
        return
      }
      guard let config = Self.makeConfig(args: args) else {
        result(FlutterError(code: "platform", message: "invalid arguments", details: nil))
        return
      }
      let root = container.appendingPathComponent(BroadcastProtocol.rootDirectoryName, isDirectory: true)
      let sessionDir = root.appendingPathComponent(config.sessionId, isDirectory: true)
      do {
        try? FileManager.default.removeItem(at: root)  // previous sessions' leftovers
        try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)
        defaults.set(try JSONEncoder().encode(config), forKey: BroadcastProtocol.configKey)
        defaults.set(false, forKey: BroadcastProtocol.stopRequestedKey)
      } catch {
        result(FlutterError(code: "platform", message: error.localizedDescription, details: nil))
        return
      }
      session = (info, config, sessionDir, root)
      state = .starting
      pendingStart = result
      keepAliveEnabled = (args["iosKeepAliveInBackground"] as? Bool) ?? false
      observeDarwin(prefix: config.notificationPrefix)
      let timeout = Double((args["iosStartTimeoutMs"] as? NSNumber)?.intValue ?? 0) / 1000
      let stopTimeout = Double((args["iosStopTimeoutMs"] as? NSNumber)?.intValue ?? 0) / 1000
      self.stopTimeout = stopTimeout
      startTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
        self?.failStart(code: "userCancelled", message: "broadcast not started")
      }
      presentPicker(extensionId: info.bundleId, showsMicrophone: config.includeMicrophone)
    #endif
  }

  private var keepAliveEnabled = false
  private var stopTimeout: TimeInterval = 0

  private static func makeConfig(args: [String: Any]) -> BroadcastConfig? {
    func int(_ k: String) -> Int? { (args[k] as? NSNumber)?.intValue }
    func dbl(_ k: String) -> Double? { (args[k] as? NSNumber)?.doubleValue }
    let texts = args["texts"] as? [String: Any]
    guard let prefix = Bundle.main.bundleIdentifier,
      let sampleRate = int("sampleRate"), let micGain = dbl("micGain"),
      let ducking = dbl("duckingRatio"), let frameMs = int("frameMs"),
      let jitter = int("jitterBufferMs"), let maxBuffer = int("maxBufferMs"),
      let micThreshold = dbl("micActiveRmsThreshold"), let attack = int("duckingAttackMs"),
      let release = int("duckingReleaseMs"), let knee = dbl("softClipKnee"),
      let chunkMs = int("iosChunkMs"), let maxPending = int("iosMaxPendingChunks"),
      let stopMessage = texts?["broadcastStoppedByApp"] as? String,
      let notArmed = texts?["broadcastNotStartedFromApp"] as? String
    else { return nil }
    return BroadcastConfig(
      sessionId: UUID().uuidString, armed: true, notificationPrefix: prefix,
      sampleRate: sampleRate, includeMicrophone: args["includeMicrophone"] as? Bool ?? false,
      micGain: micGain, duckingRatio: ducking, frameMs: frameMs, jitterBufferMs: jitter,
      maxBufferMs: maxBuffer, micActiveRmsThreshold: micThreshold, duckingAttackMs: attack,
      duckingReleaseMs: release, softClipKnee: knee, chunkMs: chunkMs,
      maxPendingChunks: maxPending, stopMessage: stopMessage, notArmedMessage: notArmed)
  }

  /// Shows the system broadcast picker by tapping RPSystemBroadcastPickerView's button.
  private func presentPicker(extensionId: String, showsMicrophone: Bool) {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    guard let window else {
      failStart(code: "platform", message: "no key window")
      return
    }
    let pickerView = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    pickerView.preferredExtension = extensionId
    pickerView.showsMicrophoneButton = showsMicrophone
    pickerView.alpha = 0.01
    window.addSubview(pickerView)
    picker = pickerView
    guard let button = pickerView.subviews.compactMap({ $0 as? UIButton }).first else {
      failStart(code: "unsupported", message: "broadcast picker unavailable")
      return
    }
    button.sendActions(for: .allTouchEvents)
  }

  private func failStart(code: String, message: String) {
    guard state == .starting else { return }
    let result = pendingStart
    pendingStart = nil
    disarm()
    teardown()
    result?(FlutterError(code: code, message: message, details: nil))
  }

  // MARK: - Stop

  private func stop(result: @escaping FlutterResult) {
    switch state {
    case .idle:
      result(nil)
    case .starting:
      failStart(code: "userCancelled", message: "stopped before start")
      result(nil)
    case .stopping:
      pendingStop.append(result)
    case .capturing:
      state = .stopping
      pendingStop.append(result)
      requestExtensionStop()
      stopTimer = Timer.scheduledTimer(withTimeInterval: stopTimeout, repeats: false) {
        [weak self] _ in self?.finishStop()
      }
    }
  }

  private func requestExtensionStop() {
    guard let session, let defaults = UserDefaults(suiteName: session.info.appGroup) else { return }
    defaults.set(true, forKey: BroadcastProtocol.stopRequestedKey)
    post(BroadcastProtocol.notificationName(prefix: session.config.notificationPrefix, .requestStop))
  }

  private func finishStop() {
    disarm()
    teardown()
    let results = pendingStop
    pendingStop = []
    results.forEach { $0(nil) }
  }

  /// Marks the stored config as not armed so a later broadcast started from Control Center
  /// is refused by the extension.
  private func disarm() {
    guard let session, let defaults = UserDefaults(suiteName: session.info.appGroup) else { return }
    var config = session.config
    config.armed = false
    if let data = try? JSONEncoder().encode(config) {
      defaults.set(data, forKey: BroadcastProtocol.configKey)
    }
  }

  /// Releases observers, timers, picker and keep-alive. The session directory is left for
  /// the Dart reader, which drains and clears it.
  private func teardown() {
    startTimer?.invalidate()
    startTimer = nil
    stopTimer?.invalidate()
    stopTimer = nil
    picker?.removeFromSuperview()
    picker = nil
    stopObservingDarwin()
    stopKeepAlive()
    session = nil
    state = .idle
  }

  // MARK: - Darwin notifications

  private func observeDarwin(prefix: String) {
    guard !observing else { return }
    observing = true
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    let observer = Unmanaged.passUnretained(self).toOpaque()
    for n in [BroadcastProtocol.Notification.started, .chunk, .stopped, .paused, .resumed] {
      CFNotificationCenterAddObserver(
        center, observer,
        { _, observer, name, _, _ in
          guard let observer, let name else { return }
          let plugin = Unmanaged<SystemAudioCapturePlugin>.fromOpaque(observer)
            .takeUnretainedValue()
          let raw = name.rawValue as String
          DispatchQueue.main.async { plugin.handleDarwin(raw) }
        },
        BroadcastProtocol.notificationName(prefix: prefix, n) as CFString, nil,
        .deliverImmediately)
    }
  }

  private func stopObservingDarwin() {
    guard observing else { return }
    observing = false
    CFNotificationCenterRemoveEveryObserver(
      CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passUnretained(self).toOpaque())
  }

  private func post(_ name: String) {
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(), CFNotificationName(name as CFString), nil, nil,
      true)
  }

  private func handleDarwin(_ name: String) {
    guard let session else { return }
    let prefix = session.config.notificationPrefix
    func matches(_ n: BroadcastProtocol.Notification) -> Bool {
      name == BroadcastProtocol.notificationName(prefix: prefix, n)
    }
    let current = readState(root: session.rootDir)
    let isOurs = current?.sessionId == session.config.sessionId
    if matches(.started) {
      guard state == .starting, isOurs else { return }
      startTimer?.invalidate()
      startTimer = nil
      picker?.removeFromSuperview()
      picker = nil
      state = .capturing
      if keepAliveEnabled { startKeepAlive() }
      let result = pendingStart
      pendingStart = nil
      result?(["mode": "chunks", "directory": session.sessionDir.path])
    } else if matches(.chunk) {
      if state == .capturing || state == .stopping {
        eventStream.send(["type": "chunksAvailable"])
      }
    } else if matches(.paused) {
      if state == .capturing { eventStream.send(["type": "interrupted"]) }
    } else if matches(.resumed) {
      if state == .capturing { eventStream.send(["type": "interruptionEnded"]) }
    } else if matches(.stopped) {
      guard isOurs else { return }
      switch state {
      case .stopping:
        finishStop()
      case .capturing:
        let reason = current?.reason?.rawValue ?? BroadcastProtocol.StopReason.user.rawValue
        disarm()
        teardown()
        eventStream.send(["type": "stoppedExternally", "reason": reason])
      case .starting:
        failStart(code: "userCancelled", message: "broadcast stopped")
      case .idle:
        break
      }
    }
  }

  private func readState(root: URL) -> BroadcastState? {
    guard
      let data = try? Data(
        contentsOf: root.appendingPathComponent(BroadcastProtocol.stateFileName))
    else { return nil }
    return try? JSONDecoder().decode(BroadcastState.self, from: data)
  }

  // MARK: - Background keep-alive

  /// Plays silence so the app (background mode `audio`) keeps running and reading chunks
  /// while the user is in another app.
  private func startKeepAlive() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      if audioSession.category != .playAndRecord && audioSession.category != .playback {
        try audioSession.setCategory(.playback, options: [.mixWithOthers])
      }
      try audioSession.setActive(true)
      let engine = AVAudioEngine()
      let format = engine.outputNode.inputFormat(forBus: 0)
      let source = AVAudioSourceNode(format: format) { _, _, _, buffers in
        for buffer in UnsafeMutableAudioBufferListPointer(buffers) {
          if let data = buffer.mData { memset(data, 0, Int(buffer.mDataByteSize)) }
        }
        return noErr
      }
      engine.attach(source)
      engine.connect(source, to: engine.mainMixerNode, format: format)
      try engine.start()
      keepAlive = engine
    } catch {
      eventStream.send([
        "type": "failed", "code": "platform", "message": "keep-alive: \(error.localizedDescription)",
      ])
    }
  }

  private func stopKeepAlive() {
    keepAlive?.stop()
    keepAlive = nil
  }
}

/// Holds the event sink of one EventChannel.
private final class EventStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func send(_ event: Any) {
    sink?(event)
  }
}
