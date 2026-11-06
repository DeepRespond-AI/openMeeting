import AVFoundation
import Flutter
import UIKit

/// PCM16 → AAC-LC (.m4a) streaming encoder backed by `AVAudioFile`.
///
/// Every session owns a serial dispatch queue; calls are processed in order and answered on
/// the main thread once done, which gives the Dart side natural backpressure.
public class AacWriterPlugin: NSObject, FlutterPlugin {
  private static let channelName = "cn.deeprespond.aac_writer"
  private static let bytesPerSample = 2

  private var sessions: [Int: Session] = [:]
  private var nextHandle = 1
  private let lock = NSLock()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(AacWriterPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "open":
      guard let path = args["path"] as? String,
        let sampleRate = args["sampleRate"] as? Int,
        let channels = args["channels"] as? Int,
        let bitrate = args["bitrate"] as? Int
      else {
        result(FlutterError(code: "bad_args", message: "path, sampleRate, channels and bitrate are required", details: nil))
        return
      }
      let session = Session(path: path, sampleRate: sampleRate, channels: channels, bitrate: bitrate)
      session.queue.async {
        do {
          try session.open()
          let handle = self.store(session)
          DispatchQueue.main.async { result(handle) }
        } catch {
          Self.fail(result, "open_failed", error)
        }
      }
    case "write":
      guard let session = self.session(args["handle"]) else {
        result(FlutterError(code: "not_open", message: "No open AAC writer", details: nil))
        return
      }
      let data = (args["data"] as? FlutterStandardTypedData)?.data ?? Data()
      session.queue.async {
        do {
          try session.write(data)
          DispatchQueue.main.async { result(nil) }
        } catch {
          Self.fail(result, "write_failed", error)
        }
      }
    case "close":
      guard let session = self.remove(args["handle"]) else {
        result(nil)
        return
      }
      session.queue.async {
        session.close()
        DispatchQueue.main.async { result(nil) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func store(_ session: Session) -> Int {
    lock.lock()
    defer { lock.unlock() }
    let handle = nextHandle
    nextHandle += 1
    sessions[handle] = session
    return handle
  }

  private func session(_ handle: Any?) -> Session? {
    guard let h = handle as? Int else { return nil }
    lock.lock()
    defer { lock.unlock() }
    return sessions[h]
  }

  private func remove(_ handle: Any?) -> Session? {
    guard let h = handle as? Int else { return nil }
    lock.lock()
    defer { lock.unlock() }
    return sessions.removeValue(forKey: h)
  }

  private static func fail(_ result: @escaping FlutterResult, _ code: String, _ error: Error) {
    DispatchQueue.main.async {
      result(FlutterError(code: code, message: error.localizedDescription, details: nil))
    }
  }

  private final class Session {
    let queue = DispatchQueue(label: "cn.deeprespond.aac_writer.session")
    private let url: URL
    private let sampleRate: Int
    private let channels: Int
    private let bitrate: Int
    private var file: AVAudioFile?
    private var format: AVAudioFormat?
    private var framesWritten: AVAudioFramePosition = 0

    init(path: String, sampleRate: Int, channels: Int, bitrate: Int) {
      self.url = URL(fileURLWithPath: path)
      self.sampleRate = sampleRate
      self.channels = channels
      self.bitrate = bitrate
    }

    func open() throws {
      try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
      }
      let settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVSampleRateKey: Double(sampleRate),
        AVNumberOfChannelsKey: channels,
        AVEncoderBitRateKey: bitrate,
      ]
      let file = try AVAudioFile(
        forWriting: url, settings: settings, commonFormat: .pcmFormatInt16, interleaved: true)
      self.file = file
      self.format = file.processingFormat
    }

    func write(_ data: Data) throws {
      guard let file = file, let format = format else { return }
      let frameBytes = AacWriterPlugin.bytesPerSample * channels
      let frameCount = data.count / frameBytes
      if frameCount == 0 { return }
      guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)),
        let target = buffer.int16ChannelData
      else { return }
      buffer.frameLength = AVAudioFrameCount(frameCount)
      data.withUnsafeBytes { raw in
        if let base = raw.baseAddress {
          memcpy(target[0], base, frameCount * frameBytes)
        }
      }
      try file.write(from: buffer)
      framesWritten += AVAudioFramePosition(frameCount)
    }

    func close() {
      // Releasing the AVAudioFile flushes the encoder and finalizes the MP4 container.
      file = nil
      format = nil
      if framesWritten == 0 {
        try? FileManager.default.removeItem(at: url)
      }
    }
  }
}
