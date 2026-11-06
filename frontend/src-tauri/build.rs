#[path = "build/ffmpeg.rs"]
mod ffmpeg;

fn main() {
    // The built-in server URL (server/config.rs) can be overridden at compile time.
    println!("cargo:rerun-if-env-changed=OPENMEETING_SERVER_URL");
    println!("cargo:rerun-if-env-changed=OPENMEETING_ANALYTICS_KEY");
    println!("cargo:rerun-if-env-changed=OPENMEETING_ANALYTICS_HOST");

    #[cfg(target_os = "macos")]
    {
        println!("cargo:rustc-link-lib=framework=AVFoundation");
        println!("cargo:rustc-link-lib=framework=Cocoa");
        println!("cargo:rustc-link-lib=framework=Foundation");
    }

    // Download and bundle FFmpeg binary at build-time to eliminate runtime download delays.
    // (Speech recognition and summarization run on the remote OpenMeeting server, so no
    // GPU detection or ONNX Runtime bundling is needed anymore.)
    ffmpeg::ensure_ffmpeg_binary();

    tauri_build::build()
}
