/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent for people to gather statistics about the activities they've tracked, and use that information with
 other apps in a shortcut.
*/

import AppIntents
import Foundation

struct SummarizeActivities: AppIntent {
    static var title: LocalizedStringResource = "Summarize Activities"
    static var description = IntentDescription("Summarizes activities tracked by the app to monitor progress towards a goal.",
                                               categoryName: "Activity Tracking",
                                               searchKeywords: ["workout"],
                                               resultValueName: "Activity Statistics")
    
    @Dependency
    private var activityTracker: ActivityTracker
    
    @Dependency
    private var trailManager: TrailDataManager
    
    /**
     An intent that completes an action or provides a summary to people can return an app entity with additional details.
     By returning the app entity, people can take the data from the properties of this intent and
     use it with other apps, enabling them to build their own powerful features that meet their specific needs.
     */
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<ActivityStatisticsSummary> {
        /**
         Summarize all activities, such as for a "Year To Date" summary. The data in the`ActivityStatisticsSummary` structure returned from
         `activityTracker` is not stored by the app, as the data continually changes baed on how people use the app. Since this data is continually
         changing, the app  conforms `ActivityStatisticsSummary` to `TransientAppEntity` instead of `AppEntity`.
         */
        let stats = activityTracker.activityStatistics
        if activityTracker.activityHistory.isEmpty {
            return .result(value: stats, dialog: IntentDialog("You haven't logged a workout yet. Let's get started!"))
        } else {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .full
            formatter.allowedUnits = [.month, .year]
            let summaryString = formatter.string(from: stats.summaryStartDate, to: Date())!
            
            let dialog = IntentDialog("You completed \(stats.totalWorkoutsCompleted) workouts in \(summaryString). Incredible!")
            return .result(value: stats, dialog: dialog)
        }
    }
}
