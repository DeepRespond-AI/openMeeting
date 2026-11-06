// summary/text_utils.rs
//
// Pure text helpers kept client-side after summary generation moved to the
// server: reasoning-marker cleanup (used to validate manual summary edits) and
// language code → name mapping (used by local summary-language detection).

use once_cell::sync::Lazy;
use regex::Regex;
use tracing::warn;

static THINK_ENVELOPE_REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"(?is)<think(?:ing)?(?:\s+[^>]*)?>.*?</think(?:ing)?\s*>").unwrap()
});
static THINK_MARKER_REGEX: Lazy<Regex> =
    Lazy::new(|| Regex::new(r"(?is)</?think(?:ing)?(?:\s+[^>]*)?>").unwrap());

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CleanedLlmMarkdown {
    pub markdown: String,
    pub reasoning_stripped: bool,
}

pub fn clean_llm_markdown_detailed(raw: &str) -> CleanedLlmMarkdown {
    let visible = THINK_ENVELOPE_REGEX.replace_all(raw, "");
    let reasoning_stripped = visible.as_ref() != raw;
    let trimmed = visible.trim();
    const PREFIXES: &[&str] = &["```markdown\n", "```\n", "```markdown\r\n", "```\r\n"];
    const SUFFIX: &str = "```";
    let markdown = PREFIXES
        .iter()
        .find_map(|prefix| {
            (trimmed.starts_with(prefix) && trimmed.ends_with(SUFFIX))
                .then(|| trimmed[prefix.len()..trimmed.len() - SUFFIX.len()].trim())
        })
        .unwrap_or(trimmed)
        .to_string();

    if THINK_MARKER_REGEX.is_match(&markdown) {
        warn!(
            raw_len = raw.len(),
            sanitized_len = markdown.len(),
            "LLM output contains an unterminated reasoning marker"
        );
    }

    CleanedLlmMarkdown {
        markdown,
        reasoning_stripped,
    }
}

pub(crate) fn contains_reasoning_marker(markdown: &str) -> bool {
    THINK_MARKER_REGEX.is_match(markdown)
}

/// Maps a BCP-47 tag to the English language name used inside LLM prompts.
///
/// LLMs respond far more reliably to "in Spanish" than to "in es". Regional
/// tags (`pt-BR`, `en_GB`) are normalised to their base language; Chinese
/// variants are disambiguated. Unknown codes return None so the caller falls
/// back to English rather than injecting a literal ISO code into the prompt.
pub(crate) fn language_name_from_code(code: &str) -> Option<&'static str> {
    let normalised = code.to_ascii_lowercase().replace('_', "-");
    let lookup: &str = match normalised.as_str() {
        "zh-cn" => "zh",
        "zh-tw" => return Some("Traditional Chinese"),
        other => other.split('-').next().unwrap_or(other),
    };
    match lookup {
        "en" => Some("English"),
        "zh" => Some("Chinese"),
        "de" => Some("German"),
        "es" => Some("Spanish"),
        "ru" => Some("Russian"),
        "ko" => Some("Korean"),
        "fr" => Some("French"),
        "ja" => Some("Japanese"),
        "pt" => Some("Portuguese"),
        "it" => Some("Italian"),
        "nl" => Some("Dutch"),
        "pl" => Some("Polish"),
        "ar" => Some("Arabic"),
        "hi" => Some("Hindi"),
        "ta" => Some("Tamil"),
        "tr" => Some("Turkish"),
        "vi" => Some("Vietnamese"),
        "th" => Some("Thai"),
        "id" => Some("Indonesian"),
        "sv" => Some("Swedish"),
        "cs" => Some("Czech"),
        "da" => Some("Danish"),
        "fi" => Some("Finnish"),
        "el" => Some("Greek"),
        "he" => Some("Hebrew"),
        "hu" => Some("Hungarian"),
        "no" => Some("Norwegian"),
        "ro" => Some("Romanian"),
        "uk" => Some("Ukrainian"),
        _ => None,
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cleaner_strips_reasoning_and_fences() {
        let cleaned = clean_llm_markdown_detailed("<think>x</think>\n```markdown\n# Hi\n```");
        assert_eq!(cleaned.markdown, "# Hi");
        assert!(cleaned.reasoning_stripped);
        assert!(contains_reasoning_marker("<think>open"));
    }

    #[test]
    fn language_names() {
        assert_eq!(language_name_from_code("zh-CN"), Some("Chinese"));
        assert_eq!(language_name_from_code("pt_BR"), Some("Portuguese"));
        assert_eq!(language_name_from_code("xx"), None);
    }
}
