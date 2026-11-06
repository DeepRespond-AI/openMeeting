// server/jobs.rs
//
// Polling helper for server background jobs (import / retranscribe).

use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;

use super::client::ServerClient;
use super::types::Job;

const POLL_INTERVAL: Duration = Duration::from_secs(1);
/// Give up after this many consecutive polling failures (~1 minute offline).
const MAX_CONSECUTIVE_ERRORS: u32 = 60;

pub enum JobOutcome {
    Finished(Box<Job>),
    Cancelled,
}

/// Poll `GET /jobs/{id}` every second until the job is terminal. `on_update`
/// is called for every poll result. If `cancel` becomes true the job is
/// cancelled server-side (`DELETE /jobs/{id}`) and `Cancelled` is returned.
pub async fn poll_job<F>(
    client: &ServerClient,
    job_id: &str,
    cancel: &AtomicBool,
    mut on_update: F,
) -> Result<JobOutcome, String>
where
    F: FnMut(&Job),
{
    let mut consecutive_errors = 0u32;
    loop {
        if cancel.load(Ordering::SeqCst) {
            if let Err(e) = client.delete_json::<Job>(&format!("/jobs/{}", job_id)).await {
                log::warn!("Failed to cancel job {}: {}", job_id, e);
            }
            return Ok(JobOutcome::Cancelled);
        }

        match client.get::<Job>(&format!("/jobs/{}", job_id)).await {
            Ok(job) => {
                consecutive_errors = 0;
                on_update(&job);
                if job.is_terminal() {
                    if job.status == "cancelled" {
                        return Ok(JobOutcome::Cancelled);
                    }
                    return Ok(JobOutcome::Finished(Box::new(job)));
                }
            }
            Err(e) if e.is_retryable() && consecutive_errors < MAX_CONSECUTIVE_ERRORS => {
                consecutive_errors += 1;
                log::warn!("Polling job {} failed ({}), retrying", job_id, e);
            }
            Err(e) => return Err(e.to_string()),
        }

        tokio::time::sleep(POLL_INTERVAL).await;
    }
}
