import Foundation

/// Thin Swift wrapper around `FSEventStream` for watching a single file.
///
/// We watch the file's **parent directory** rather than the file directly,
/// because atomic writes (`Data.write(to:options:.atomic)`) replace the
/// file via rename — which would invalidate any direct watch but is just
/// a directory event when watching the parent.
///
/// Coalescing: `FSEventStreamCreate`'s latency parameter (0.5s here)
/// batches rapid-fire events into a single callback. That's already
/// sufficient debouncing for the rules.json edit pattern.
final class FileWatcher {

    private var stream: FSEventStreamRef?
    private let queue = DispatchQueue(label: "com.pkajaba.junction.filewatcher")
    private let onChange: () -> Void
    private let watchedURL: URL

    init(url: URL, onChange: @escaping () -> Void) {
        self.watchedURL = url
        self.onChange = onChange
    }

    func start() {
        guard stream == nil else { return }

        let parentPath = watchedURL.deletingLastPathComponent().path
        let paths: CFArray = [parentPath] as CFArray

        // `passUnretained`, deliberately: the stream is owned by *this*
        // object, so retaining self in the stream's context (passRetained)
        // would form a cycle — the stream would keep the watcher alive,
        // `deinit` would never fire, and `stop()` would never run. Instead
        // the owner keeps us alive and `stop()` drains in-flight callbacks
        // on teardown (see below), which closes the use-after-free window
        // without the cycle.
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags = UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)

        let created = FSEventStreamCreate(
            kCFAllocatorDefault,
            { _, info, _, _, _, _ in
                guard let info = info else { return }
                let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
                watcher.dispatchChange()
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,            // latency in seconds — coalesces bursts
            flags
        )

        guard let stream = created else { return }
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
        self.stream = stream
    }

    func stop() {
        guard let stream = stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)   // unschedules from `queue`: no new callbacks
        FSEventStreamRelease(stream)
        self.stream = nil
        // Drain the serial callback queue so any callback already in flight
        // finishes touching `self` before stop() returns. Combined with the
        // unscheduling above, this guarantees no callback runs after the
        // watcher is gone — the use-after-free window the audit flagged,
        // which matters if this watcher is ever owned by a short-lived
        // object rather than the app-lifetime RuleStore singleton.
        //
        // Safe from deadlock: the callback only hops to the main queue and
        // never calls back into stop(), and stop() is never invoked from
        // `queue` itself.
        queue.sync { }
    }

    private func dispatchChange() {
        // Hop to the main queue so callers can touch @MainActor state safely.
        DispatchQueue.main.async { [weak self] in
            self?.onChange()
        }
    }

    deinit { stop() }
}
