import Foundation

struct UsageStats {
    private static let defaults = UserDefaults(suiteName: "\(App.bundleIdentifier).usage")!
    private static let maxAge: TimeInterval = 365 * 24 * 3600
    private static let queue = DispatchQueue(label: "com.lwouis.alt-tab-macos.usage-stats", qos: .utility)
    private static let allKeys = ["triggers", "searches", "triggersAppIcons", "triggersTitles", "triggersAutoSize", "triggersExtraShortcuts"]
    private(set) static var searchRecordedThisSession = false

    static func recordTrigger(_ shortcutIndex: Int) {
        record("triggers")
        if shortcutIndex > 0 && shortcutIndex < Preferences.maxShortcutCount { record("triggersExtraShortcuts") }
        if Preferences.appearanceStyle == .appIcons { record("triggersAppIcons") }
        if Preferences.appearanceStyle == .titles { record("triggersTitles") }
        if Preferences.appearanceSize == .auto { record("triggersAutoSize") }
    }

    static func recordSearchIfFirst() {
        guard !searchRecordedThisSession else { return }
        searchRecordedThisSession = true
        record("searches")
    }

    static func resetSession() {
        searchRecordedThisSession = false
    }

    static func count(_ key: String, since date: Date) -> Int {
        let threshold = Int(date.timeIntervalSince1970)
        return queue.sync { getTimestamps(key).count { $0 >= threshold } }
    }

    static func prune() {
        let cutoff = Int(Date().timeIntervalSince1970 - maxAge)
        queue.async {
            for key in allKeys {
                let timestamps = getTimestamps(key)
                guard !timestamps.isEmpty else { continue }
                defaults.set(timestamps.filter { $0 >= cutoff }, forKey: key)
            }
        }
    }

    static func flush() {
        queue.sync {}
    }

    private static func record(_ key: String) {
        let timestamp = Int(Date().timeIntervalSince1970)
        queue.async {
            var timestamps = getTimestamps(key)
            timestamps.append(timestamp)
            defaults.set(timestamps, forKey: key)
        }
    }

    private static func getTimestamps(_ key: String) -> [Int] {
        defaults.array(forKey: key) as? [Int] ?? []
    }
}
