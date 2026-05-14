//
//  BrightDate.swift
//  BrightDate
//
//  Created by Jessica Mulein on 5/13/26.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let interval = configuration.updateInterval.seconds
        let now = Date()
        // Pre-compute up to 1 hour of entries, capped at 720 to stay memory-light.
        // WidgetKit may rate-limit rendering at sub-second intervals, but dense
        // pre-computation keeps the displayed value as fresh as the system allows.
        let count = min(720, max(1, Int(3600.0 / interval)))
        let entries = (0..<count).map { i in
            SimpleEntry(
                date: now.addingTimeInterval(Double(i) * interval),
                configuration: configuration
            )
        }
        let refreshAfter = now.addingTimeInterval(Double(count) * interval)
        return Timeline(entries: entries, policy: .after(refreshAfter))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct BrightDateEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        let value     = BrightDateUtil.brightDate(for: entry.date)
        let places    = entry.configuration.decimalPlaces.rawValue
        let formatted = String(format: "%0.\(places)f", value)

        VStack(spacing: 6) {
            Text("BRIGHTDATE")
                .font(.custom("RobotoMono-Light", size: 11))
                .foregroundColor(Color(white: 0.55))
                .tracking(4)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(formatted)
                .font(.custom("RobotoMono-Regular", size: 34))
                .foregroundColor(Color(red: 1.0, green: 0.82, blue: 0.0))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .contentTransition(.identity)
        }
        .padding(.horizontal, 12)
    }
}

struct BrightDate: Widget {
    let kind: String = "BrightDate"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            BrightDateEntryView(entry: entry)
                .containerBackground(Color.black, for: .widget)
        }
        .configurationDisplayName("BrightDate")
        .description("Decimal days since J2000.0 (TAI-based).")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
