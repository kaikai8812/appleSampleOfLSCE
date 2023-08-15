/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration representing the different types of activities people can enjoy doing on a trail.
*/

import AppIntents
import Foundation
import HealthKit

enum ActivityStyle: String, Codable, Sendable {
    case biking
    case equestrian
    case hiking
    case jogging
    case crossCountrySkiing
    case snowshoeing
    
    /// The string name for an SF Symbol representing the value.
    var symbol: String {
        switch self {
        case .biking:
            return "figure.outdoor.cycle"
        case .equestrian:
            return "figure.equestrian.sports"
        case .hiking:
            return "figure.hiking"
        case .jogging:
            return "figure.run"
        case .crossCountrySkiing:
            return "figure.skiing.crosscountry"
        case .snowshoeing:
            return "snowflake"
        }
    }

    /// The HealthKit workout type that corresponds to the activity type.
    var workoutStyle: HKWorkoutActivityType {
        switch self {
        case .biking:
            return .cycling
        case .equestrian:
            return .equestrianSports
        case .hiking:
            return .hiking
        case .jogging:
            return .running
        case .crossCountrySkiing:
            return .crossCountrySkiing
        case .snowshoeing:
            return .snowSports
        }
    }
}

/// Conforming `ActivityStyle` to `AppEnum` makes it available for use as a parameter in an `AppIntent`.
extension ActivityStyle: AppEnum {
    
    /**
     A localized name representing this entity as a concept people are familiar with in the app, including
     localized variations based on the plural rules the app defines in `AppIntents.stringsdict`, referenced here
     through the `table` parameter. The system may show this value to people when they configure an intent.
     */
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Activity", table: "AppIntents"),
            numericFormat: LocalizedStringResource("\(placeholder: .int) activities", table: "AppIntents")
        )
    }
    
    /// Localized names for each case that the enum defines. The system shows these values to people when they configure or use an intent.
    static var caseDisplayRepresentations: [ActivityStyle: DisplayRepresentation] = [
        .biking: DisplayRepresentation(title: "Biking",
                                       subtitle: "Mountain bike ride",
                                       image: imageRepresentation[.biking]),
        
        .equestrian: DisplayRepresentation(title: "Equestrian",
                                           subtitle: "Equestrian sports",
                                           image: imageRepresentation[.equestrian]),
        
        .hiking: DisplayRepresentation(title: "Hiking",
                                       subtitle: "A lengthy outdoor walk",
                                       image: imageRepresentation[.hiking]),
        
        .jogging: DisplayRepresentation(title: "Jogging",
                                        subtitle: "A gentle run",
                                        image: imageRepresentation[.jogging]),
        
        .crossCountrySkiing: DisplayRepresentation(title: "Skiing",
                                                   subtitle: "Cross-country skiing",
                                                   image: imageRepresentation[.crossCountrySkiing]),
        
        .snowshoeing: DisplayRepresentation(title: "Snowshoeing",
                                            subtitle: "Walking in the snow",
                                            image: imageRepresentation[.snowshoeing])
    ]
    
    /// An image for the activity that appears in Spotlight and when the system asks people to provide a parameter value in an intent.
    private static var imageRepresentation: [ActivityStyle: DisplayRepresentation.Image] = [
        .biking: DisplayRepresentation.Image(systemName: ActivityStyle.biking.symbol),
        .equestrian: DisplayRepresentation.Image(systemName: ActivityStyle.equestrian.symbol),
        .hiking: DisplayRepresentation.Image(systemName: ActivityStyle.hiking.symbol),
        .jogging: DisplayRepresentation.Image(systemName: ActivityStyle.jogging.symbol),
        .crossCountrySkiing: DisplayRepresentation.Image(systemName: ActivityStyle.crossCountrySkiing.symbol),
        .snowshoeing: DisplayRepresentation.Image(systemName: ActivityStyle.snowshoeing.symbol)
    ]
}

extension Array where Element == ActivityStyle {
    /// Flattens an array of activities to a formatted string.
    var formattedDisplayValue: String {
        let activities: [String] = compactMap { activity in
            guard let activityName = ActivityStyle.caseDisplayRepresentations[activity] else {
                return nil
            }
            return String(localized: activityName.title)
        }
        return activities.joined(separator: ", ")
    }
}
