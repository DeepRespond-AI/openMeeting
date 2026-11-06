// server/mod.rs
//
// Remote OpenMeeting server integration: connection config, HTTP client,
// heartbeat/status tracking and the related Tauri commands.

pub mod client;
mod direct_upload;
pub mod auth;
pub mod commands;
pub mod config;
pub mod heartbeat;
pub mod jobs;
pub mod local_index;
pub mod live;
pub mod types;

pub use client::{ServerClient, ServerError};
