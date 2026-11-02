import Foundation

/// Where the app finds the backend. Defaults to the live server. To point a debug
/// run at a backend on your Mac, enable `PLONG_API_BASE_URL` / `PLONG_HLS_URL` in
/// Product > Scheme > Edit Scheme > Run > Arguments (see README).
enum AppConfig {
    static let apiBaseURL = value(for: "PLONG_API_BASE_URL", default: "https://api.plong.my.id")
    static let hlsURL = URL(string: value(for: "PLONG_HLS_URL", default: "https://cctv.plong.my.id/cam1/index.m3u8"))!

    /// Environment variables only exist when Xcode launches the app, so TestFlight and
    /// archive builds always get the default.
    private static func value(for key: String, default fallback: String) -> String {
        let raw = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !raw.isEmpty else { return fallback }
        // APIClient appends paths that start with "/", so a trailing slash would double it.
        return raw.hasSuffix("/") ? String(raw.dropLast()) : raw
    }
}
