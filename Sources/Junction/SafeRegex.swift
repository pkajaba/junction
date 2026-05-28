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
/// 3. **Match budget** (`matchBudget`) — each match runs on a worker
///    thread with a wall-clock deadline. If it overruns we return `false`
///    so the user's link still routes promptly. `NSRegularExpression`
///    can't be cancelled mid-match, so a timed-out worker runs to
///    completion in the background — but that's bounded (the input is
///    capped) and never blocks the click.
///
/// Compiled patterns are cached (lock-guarded) so repeated routing doesn't
/// recompile the same regex.
enum SafeRegex {

    static let maxPatternLength = 1_000
    static let maxInputLength = 4_096
    static let matchBudget: TimeInterval = 0.1   // 100 ms

    // Lock-guarded compile cache. `nonisolated(unsafe)` because access is
    // serialized through `cacheLock` — the compiler can't see that.
    private static let cacheLock = NSLock()
    nonisolated(unsafe) private static var cache: [String: NSRegularExpression] = [:]

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

    /// True if `regex` matches anywhere in `input`, subject to the input
    /// cap and the match budget. Catastrophic patterns return `false` at
    /// the deadline rather than hanging.
    static func matchesWithinBudget(_ regex: NSRegularExpression, in input: String) -> Bool {
        guard !input.isEmpty, input.count <= maxInputLength else { return false }
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        let carrier = MatchCarrier(regex: regex, input: input, range: range)
        let done = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            carrier.hit = carrier.regex.firstMatch(
                in: carrier.input, options: [], range: carrier.range
            ) != nil
            done.signal()
        }
        // On a timeout we deliberately don't read `carrier.hit` (the worker
        // may still be writing it) — we just bail with "no match".
        if done.wait(timeout: .now() + matchBudget) == .timedOut { return false }
        return carrier.hit
    }

    /// Convenience: compile + match in one call. `false` for an empty
    /// input, an over-long/invalid pattern, or a budget overrun.
    static func matches(pattern: String, input: String) -> Bool {
        guard let regex = compile(pattern) else { return false }
        return matchesWithinBudget(regex, in: input)
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
