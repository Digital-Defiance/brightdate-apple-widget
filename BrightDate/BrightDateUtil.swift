// BrightDateUtil.swift
// Utility for computing the current BrightDate value (decimal days since J2000.0)

import Foundation

struct BrightDateUtil {
    /// TAI – UTC offset as of 2017-01-01 (37 s). Update when IERS adds a new leap second.
    static let currentTAIUTCOffset: TimeInterval = 37.0
    /// TAI Unix seconds at J2000.0 = 2000-01-01T11:59:27.816 TAI
    /// (UTC label: 2000-01-01T11:58:55.816Z  = Unix ms 946_727_935_816)
    static let j2000TAIUnixSeconds: TimeInterval = 946_727_967.816
    /// SI seconds per day
    static let secondsPerDay: TimeInterval = 86_400.0

    /// BrightDate for an arbitrary Date.
    ///
    /// Formula (from the README):
    ///   bd = (taiUnixSeconds − J2000_TAI_UNIX_S) / 86400
    /// where taiUnixSeconds = utcUnixSeconds + currentTAIUTCOffset.
    static func brightDate(for date: Date) -> Double {
        let taiSeconds = date.timeIntervalSince1970 + currentTAIUTCOffset
        return (taiSeconds - j2000TAIUnixSeconds) / secondsPerDay
    }

    /// BrightDate for right now.
    static func currentBrightDate() -> Double {
        brightDate(for: Date())
    }

    /// Formatted BrightDate for right now (5 decimal places).
    static func formattedBrightDate(decimalPlaces: Int = 5) -> String {
        String(format: "%0.\(decimalPlaces)f", currentBrightDate())
    }
}
