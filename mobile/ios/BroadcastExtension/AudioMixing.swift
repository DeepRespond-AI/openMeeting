import AVFoundation
import CoreMedia
import Foundation

// DSP for the broadcast extension. Same rules as the Android implementation
// (packages/system_audio_capture/android/.../AudioDsp.kt) and the desktop mixer
// (frontend/src-tauri/src/audio/pipeline.rs): system audio is ducked while the mic carries
// speech, and the sum is soft-clipped instead of hard-clipped.

/// Fixed-capacity float FIFO; writing past capacity drops the oldest samples. Thread-safe.
final class FloatRing {
  private var buf: [Float]
  private var head = 0
  private var size = 0
  private var lock = os_unfair_lock()

  init(capacity: Int) {
    buf = [Float](repeating: 0, count: max(1, capacity))
  }

  func write(_ src: [Float]) {
    os_unfair_lock_lock(&lock)
    defer { os_unfair_lock_unlock(&lock) }
    let cap = buf.count
    var from = 0
    var n = src.count
    if n > cap {
      from = n - cap
      n = cap
    }
    let overflow = size + n - cap
    if overflow > 0 {
      head = (head + overflow) % cap
      size -= overflow
    }
    var tail = (head + size) % cap
    for i in 0..<n {
      buf[tail] = src[from + i]
      tail += 1
      if tail == cap { tail = 0 }
    }
    size += n
  }

  /// Fills `dst[0..<count]`, zero-padding when fewer samples are available.
  func readPadded(into dst: inout [Float], count: Int) {
    os_unfair_lock_lock(&lock)
    defer { os_unfair_lock_unlock(&lock) }
    let n = min(count, size)
    let cap = buf.count
    for i in 0..<n {
      dst[i] = buf[head]
      head += 1
      if head == cap { head = 0 }
    }
    size -= n
    for i in n..<count { dst[i] = 0 }
  }
}

struct DuckingMixer {
  let micGain: Float
  let duckingRatio: Float
  let micActiveRms: Float
  let attackCoef: Float
  let releaseCoef: Float
  let softClipKnee: Float
  private(set) var systemGain: Float = 1

  init(config: BroadcastConfig) {
    micGain = Float(config.micGain)
    duckingRatio = Float(config.duckingRatio)
    micActiveRms = Float(config.micActiveRmsThreshold)
    attackCoef = Self.coef(rate: config.sampleRate, ms: config.duckingAttackMs)
    releaseCoef = Self.coef(rate: config.sampleRate, ms: config.duckingReleaseMs)
    softClipKnee = Float(config.softClipKnee)
  }

  private static func coef(rate: Int, ms: Int) -> Float {
    ms <= 0 ? 1 : Float(1 - exp(-1000.0 / (Double(ms) * Double(rate))))
  }

  /// Mixes `count` samples; `mic` is nil when the microphone is not mixed in.
  mutating func mix(mic: [Float]?, sys: [Float], out: inout [Float], count: Int) {
    let target: Float = (mic.map { Self.rms($0, count) >= micActiveRms } ?? false) ? duckingRatio : 1
    let c = target < systemGain ? attackCoef : releaseCoef
    for i in 0..<count {
      systemGain += (target - systemGain) * c
      let m = mic.map { $0[i] * micGain } ?? 0
      out[i] = Self.softClip(m + sys[i] * systemGain, knee: softClipKnee)
    }
  }

  static func softClip(_ x: Float, knee: Float) -> Float {
    let a = abs(x)
    if a <= knee || knee >= 1 { return min(1, max(-1, x)) }
    let range = 1 - knee
    let y = knee + range * tanh((a - knee) / range)
    return x < 0 ? -y : y
  }

  static func rms(_ x: [Float], _ count: Int) -> Float {
    guard count > 0 else { return 0 }
    var sum: Float = 0
    for i in 0..<count { sum += x[i] * x[i] }
    return sqrt(sum / Float(count))
  }
}

/// Converts ReplayKit audio sample buffers (any linear-PCM layout: Int16/Int32/Float32,
/// big/little endian, interleaved or not, any channel count and rate) to mono Float32 at the
/// target rate. Keeps one AVAudioConverter per input so resampling is seamless across buffers.
final class MonoConverter {
  private let outFormat: AVAudioFormat
  private var converter: AVAudioConverter?
  private var inFormat: AVAudioFormat?

  init?(sampleRate: Int) {
    guard
      let f = AVAudioFormat(
        commonFormat: .pcmFormatFloat32, sampleRate: Double(sampleRate), channels: 1,
        interleaved: false)
    else { return nil }
    outFormat = f
  }

  func convert(_ sampleBuffer: CMSampleBuffer) -> [Float]? {
    guard let (mono, rate) = Self.monoFloats(sampleBuffer), !mono.isEmpty else { return nil }
    if rate == outFormat.sampleRate { return mono }
    if inFormat?.sampleRate != rate {
      inFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32, sampleRate: rate, channels: 1, interleaved: false)
      converter = inFormat.flatMap { AVAudioConverter(from: $0, to: outFormat) }
    }
    guard let converter, let inFormat,
      let input = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: AVAudioFrameCount(mono.count))
    else { return nil }
    input.frameLength = AVAudioFrameCount(mono.count)
    mono.withUnsafeBufferPointer { src in
      input.floatChannelData![0].update(from: src.baseAddress!, count: mono.count)
    }
    let capacity = AVAudioFrameCount(Double(mono.count) * outFormat.sampleRate / rate) + 64
    guard let output = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: capacity) else {
      return nil
    }
    var consumed = false
    var error: NSError?
    let status = converter.convert(to: output, error: &error) { _, inputStatus in
      if consumed {
        inputStatus.pointee = .noDataNow
        return nil
      }
      consumed = true
      inputStatus.pointee = .haveData
      return input
    }
    guard status != .error, let data = output.floatChannelData else { return nil }
    return Array(UnsafeBufferPointer(start: data[0], count: Int(output.frameLength)))
  }

  private static func monoFloats(_ sb: CMSampleBuffer) -> ([Float], Double)? {
    guard let fd = CMSampleBufferGetFormatDescription(sb),
      let asbdPtr = CMAudioFormatDescriptionGetStreamBasicDescription(fd)
    else { return nil }
    let asbd = asbdPtr.pointee
    guard asbd.mFormatID == kAudioFormatLinearPCM, asbd.mChannelsPerFrame > 0 else { return nil }
    let frames = CMSampleBufferGetNumSamples(sb)
    guard frames > 0 else { return nil }

    var listSize = 0
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
      sb, bufferListSizeNeededOut: &listSize, bufferListOut: nil, bufferListSize: 0,
      blockBufferAllocator: nil, blockBufferMemoryAllocator: nil, flags: 0, blockBufferOut: nil)
    guard listSize > 0 else { return nil }
    let raw = UnsafeMutableRawPointer.allocate(
      byteCount: listSize, alignment: MemoryLayout<AudioBufferList>.alignment)
    defer { raw.deallocate() }
    let list = raw.bindMemory(to: AudioBufferList.self, capacity: 1)
    var block: CMBlockBuffer?
    let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
      sb, bufferListSizeNeededOut: nil, bufferListOut: list, bufferListSize: listSize,
      blockBufferAllocator: nil, blockBufferMemoryAllocator: nil,
      flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, blockBufferOut: &block)
    guard status == noErr else { return nil }

    let flags = asbd.mFormatFlags
    let isFloat = flags & kAudioFormatFlagIsFloat != 0
    let bigEndian = flags & kAudioFormatFlagIsBigEndian != 0
    let nonInterleaved = flags & kAudioFormatFlagIsNonInterleaved != 0
    let bytes = Int(asbd.mBitsPerChannel) / 8
    guard bytes == 2 || bytes == 4 else { return nil }
    let channels = Int(asbd.mChannelsPerFrame)

    var out = [Float](repeating: 0, count: frames)
    for buffer in UnsafeMutableAudioBufferListPointer(list) {
      guard let data = buffer.mData else { continue }
      let ch = nonInterleaved ? 1 : max(1, Int(buffer.mNumberChannels))
      let n = min(frames, Int(buffer.mDataByteSize) / (bytes * ch))
      for f in 0..<n {
        for c in 0..<ch {
          let offset = (f * ch + c) * bytes
          out[f] += sample(data, offset, bytes: bytes, isFloat: isFloat, bigEndian: bigEndian)
        }
      }
    }
    if channels > 1 {
      let scale = 1 / Float(channels)
      for i in 0..<frames { out[i] *= scale }
    }
    return (out, asbd.mSampleRate)
  }

  private static func sample(
    _ p: UnsafeMutableRawPointer, _ offset: Int, bytes: Int, isFloat: Bool, bigEndian: Bool
  ) -> Float {
    if bytes == 2 {
      let v = p.loadUnaligned(fromByteOffset: offset, as: Int16.self)
      return Float(bigEndian ? Int16(bigEndian: v) : Int16(littleEndian: v)) / 32768
    }
    let bits = p.loadUnaligned(fromByteOffset: offset, as: UInt32.self)
    let v = bigEndian ? UInt32(bigEndian: bits) : UInt32(littleEndian: bits)
    return isFloat ? Float(bitPattern: v) : Float(Int32(bitPattern: v)) / 2_147_483_648
  }
}

/// Float [-1, 1] → PCM16 little-endian.
func pcm16LittleEndian(_ samples: [Float], count: Int) -> Data {
  var data = Data(count: count * 2)
  data.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
    for i in 0..<count {
      let v = Int16(max(-1, min(1, samples[i])) * Float(Int16.max))
      ptr.storeBytes(of: v.littleEndian, toByteOffset: i * 2, as: Int16.self)
    }
  }
  return data
}
