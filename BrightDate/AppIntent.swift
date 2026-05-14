//
//  AppIntent.swift
//  BrightDate
//
//  Created by Jessica Mulein on 5/13/26.
//

import WidgetKit
import AppIntents

/// Predefined update intervals for the widget timeline.
enum UpdateIntervalOption: String, AppEnum {
    case tenth  = "0.1"
    case half   = "0.5"
    case one    = "1"
    case two    = "2"
    case five   = "5"
    case ten    = "10"
    case thirty = "30"
    case sixty  = "60"

    var seconds: Double {
        switch self {
        case .tenth:  return 0.1
        case .half:   return 0.5
        case .one:    return 1.0
        case .two:    return 2.0
        case .five:   return 5.0
        case .ten:    return 10.0
        case .thirty: return 30.0
        case .sixty:  return 60.0
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Update Interval"
    static var caseDisplayRepresentations: [UpdateIntervalOption: DisplayRepresentation] = [
        .tenth:  "0.1 seconds",
        .half:   "0.5 seconds",
        .one:    "1 second",
        .two:    "2 seconds",
        .five:   "5 seconds",
        .ten:    "10 seconds",
        .thirty: "30 seconds",
        .sixty:  "60 seconds",
    ]
}

/// Number of decimal places to show in the BrightDate value (3–9).
enum DecimalPlacesOption: Int, AppEnum {
    case three = 3, four = 4, five = 5, six = 6, seven = 7, eight = 8, nine = 9

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Decimal Places"
    static var caseDisplayRepresentations: [DecimalPlacesOption: DisplayRepresentation] = [
        .three: "3", .four: "4", .five: "5", .six: "6",
        .seven: "7", .eight: "8", .nine: "9",
    ]
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "BrightDate Configuration" }
    static var description: IntentDescription { "Configure the BrightDate display." }

    /// Decimal places shown after the point (3–9).
    @Parameter(title: "Decimal Places", default: .five)
    var decimalPlaces: DecimalPlacesOption

    /// How often the widget timeline advances.
    @Parameter(title: "Update Interval", default: .one)
    var updateInterval: UpdateIntervalOption
}
