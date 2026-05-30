import Foundation

/// Hardened, cached wrapper around `NSRegularExpression` for
/// **user-authored** patterns — rule `hostRegex` matchers and tracking-
/// param globs. Those patterns compile and run on the main-actor routing
/// path against a URL host any website can craft, so in principle a
/// pathological pattern could trigger catastrophic backtracking (ReDoS)
/// and stall routing. It's self-inflicted (the user wrote the pattern) and
/// the input is small, so the real-world risk is low — but three cheap
/// bounds make a hang impossible:
///
/// 1. **Pattern-length cap** (`maxPatternLength`) — longer patterns are
///    refused at compile time (→ `nil`, treated as "no match").
/// 2. **Input-length cap** (`maxInputLength`) — matching is skipped for
///    longer inputs. URL hosts are ≤253 chars; this is belt-and-braces.
/// 3. **Match budget** (`matchBudget`, 25 ms) — each match runs on a
///    worker thread with a wall-clock deadline. A normal host regex
///    resolves in microseconds, so the budget is invisible; only a
///    catastrophic pattern reaches it, and on overrun we return `false`
///    so the link still routes promptly. `NSRegularExpression` can't be
///    cancelled mid-match, so a timed-out worker runs to completion in the
///    background — bounded by the input-length cap, and it never blocks
///    the click beyond the budget.
/// 4. **Slow-pattern cache** — a pattern that blows the budget once is
///    remembered and short-circuited to "no match" on every later call,
///    so a catastrophic rule costs at most *one* ~25 ms stall per process
///    (not one per link click). Editing the rule changes the pattern
///    string, which clears it from the set naturally.
///
/// Compiled patterns are also cached (lock-guarded) so repeated routing
/// doesn't recompile the same regex.
enum SafeRegex {

    static let maxPatternLength = 1_000
    static let maxInputLength = 4_096
    static let matchBudget: TimeInterval = 0.025   // 25 ms

    // Lock-guarded shared state. `nonisolated(unsafe)` because access is
    // serialized through `cacheLock` — the compiler can't see that.
    private static let cacheLock = NSLock()
    nonisolated(unsafe) private static var cache: [String: NSRegularExpression] = [:]
    // Patterns that exceeded `matchBudget` at least once. Treated as
    // "no match" without re-running, so a catastrophic rule stalls at most
    // once per process. Bounded in practice by the number of distinct
    // user-authored regex patterns.
    nonisolated(unsafe) private static var slowPatterns: Set<String> = []

    /// Compile (and cache) a case-insensitive regex. Returns `nil` if the
    /// pattern is over the length cap or fails to compile.
    static func compile(_ pattern: String) -> NSRegularExpression? {
        guard pattern.count <= maxPatternLength else { return nil }
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cached = cache[pattern] { return cached }
        guard let regex = try? NSRegularExpression(
            pattern: pattern, options: [.caseInsensitive]
        ) else { return nil }
        cache[pattern] = regex
        return regex
    }

    /// Compile + match `pattern` against `input`. `false` for an empty
    /// input, an over-long/invalid pattern, a budget overrun, or a pattern
    /// already known to overrun.
    static func matches(pattern: String, input: String) -> Bool {
        guard let regex = compile(pattern) else { return false }
        if isKnownSlow(pattern) { return false }
        let result = evaluate(regex, in: input)
        if result.timedOut { markSlow(pattern) }
        return result.hit
    }

    /// Run the match on a worker thread with the wall-clock budget.
    /// Returns whether it matched and whether it overran. On overrun we
    /// don't read `carrier.hit` (the worker may still be writing it) — we
    /// bail with "no match" and report the timeout so the caller can cache
    /// the offending pattern.
    private static func evaluate(
        _ regex: NSRegularExpression, in input: String
    ) -> (hit: Bool, timedOut: Bool) {
        guard !input.isEmpty, input.count <= maxInputLength else { return (false, false) }
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        let carrier = MatchCarrier(regex: regex, input: input, range: range)
        let done = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            carrier.hit = carrier.regex.firstMatch(
                in: carrier.input, options: [], range: carrier.range
            ) != nil
            done.signal()
        }
        if done.wait(timeout: .now() + matchBudget) == .timedOut { return (false, true) }
        return (carrier.hit, false)
    }

    private static func isKnownSlow(_ pattern: String) -> Bool {
        cacheLock.lock(); defer { cacheLock.unlock() }
        return slowPatterns.contains(pattern)
    }

    private static func markSlow(_ pattern: String) {
        cacheLock.lock(); defer { cacheLock.unlock() }
        slowPatterns.insert(pattern)
    }
}

/// Carries the immutable match inputs (plus the one-shot result) across the
/// worker-thread boundary. `@unchecked Sendable`: the regex/input/range are
/// effectively immutable, and `hit` is only read by the caller *after* the
/// worker signals the semaphore (a happens-before edge) on the non-timeout
/// path.
private final class MatchCarrier: @unchecked Sendable {
    let regex: NSRegularExpression
    let input: String
    let range: NSRange
    var hit = false

    init(regex: NSRegularExpression, input: String, range: NSRange) {
        self.regex = regex
        self.input = input
        self.range = range
    }
}
