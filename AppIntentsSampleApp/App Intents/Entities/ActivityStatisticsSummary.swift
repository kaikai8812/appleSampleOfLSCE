/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A summary of activity statistics, including distance traveled and calories burned.
*/

import AppIntents
import CoreLocation
import Foundation

/**
 A `TransientAppEntity` represents data that an `EntityQuery` cannot query because the data continually changes, such as a summary
 of workout statistics. This type of app entity is helpful for returning data from an intent so that other intents can use its properties as inputs
 to other intents, enabling powerful workflows in the Shortcuts app.
 */
struct ActivityStatisticsSummary: TransientAppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Workout Summary")
    
    @Property(title: "Summary Start Date")
    var summaryStartDate: Date
    
    @Property(title: "Workouts Completed")
    var totalWorkoutsCompleted: Int
    
    @Property(title: "Calories Burned")
    var totalCaloriesBurned: Int
    
    @Property(title: "Distance Traveled")
    var distanceTraveled: Measurement<UnitLength>
    
    init() {
        summaryStartDate = Date()
        totalWorkoutsCompleted = 0
        totalCaloriesBurned = 0
        distanceTraveled = Measurement(value: 0, unit: .meters)
    }
    
    var displayRepresentation: DisplayRepresentation {
        var image = "party.popper"
        var subtitle = LocalizedStringResource("You burned \(totalCaloriesBurned) calories.")
        
        if totalWorkoutsCompleted == 0 {
            image = "figure.hiking"
            subtitle = LocalizedStringResource("You haven't logged a workout yet.")
        }
        
        return DisplayRepresentation(title: "Workout Summary",
                                     subtitle: subtitle,
                                     image: DisplayRepresentation.Image(systemName: image),
                                     synonyms: ["Activity Summary"])
    }
}
