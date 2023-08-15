/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent that suggests trails based on criteria that people provide.
*/

import AppIntents
import CoreLocation
import Foundation
import OSLog

struct SuggestTrails: ForegroundContinuableIntent {

    static var title: LocalizedStringResource = "Suggest Trails"
    
    /// The `resultValueName` parameter names the output of the intent to control how the system displays it when other actions use it in a shortcut.
    static var description = IntentDescription("Plan your next trip to the great outdoors with some suggestions on what you'll enjoy doing.",
                                               categoryName: "Discover",
                                               resultValueName: "Suggested Trails")
    
    /// When this intent runs, the system launches the app in the background without creating any UI scenes.
    static var openAppWhenRun: Bool = false
    
    /**
     Parameter summaries are customizable based on the current parameter values. For example, if someone is
     searching for trails from a collection, the app doesn't need to get a location or search radius. If someone specifies
     neither a location or a collection, the app presents them with a starting point to choose from. This example combines multiple conditions with
     a `ParameterSummarySwitchCondition` over `AppEnum` values, with a `ParameterSummaryWhenCondition`.
     */
    static var parameterSummary: some ParameterSummary {
        Switch(\.$activity) {
            Case(.biking) {
                When(\.$location, .hasAnyValue) {
                    Summary("Ride a bike within \(\.$searchRadius) of \(\.$location)")
                } otherwise: {
                    When(\.$trailCollection, .hasAnyValue) {
                        Summary("Pick a bike ride from \(\.$trailCollection)")
                    } otherwise: {
                        Summary("Suggest bike rides from \(\.$trailCollection) or near \(\.$location)")
                    }
                }
            }
            DefaultCase() {
                When(\.$location, .hasAnyValue) {
                    Summary("Suggest \(\.$activity) trails within \(\.$searchRadius) of \(\.$location)")
                } otherwise: {
                    When(\.$trailCollection, .hasAnyValue) {
                        Summary("Suggest \(\.$activity) trails from \(\.$trailCollection)")
                    } otherwise: {
                        Summary("Suggest \(\.$activity) trails from \(\.$trailCollection) or near \(\.$location)")
                    }
                }
            }
        }
    }

    @Parameter(title: "Activity", requestValueDialog: "What activity would you like to do?")
    var activity: ActivityStyle
    
    /**
     Measurement parameters can provide their preferred unit with the `defaultUnit` parameter, and also specify whether the unit can have a
     negative value. The default unit selected here is visible when configuring the intent in Shortcuts.
     */
    @Parameter(title: "Search Radius", defaultUnit: .kilometers, supportsNegativeNumbers: false)
    var searchRadius: Measurement<UnitLength>?

    @Parameter(title: "Location", requestValueDialog: "Where would you like to go?", optionsProvider: LocationOptionsProvider())
    var location: String?
    
    @Parameter(title: "Featured Collection")
    var trailCollection: TrailCollection?
    
    @Dependency
    private var trailManager: TrailDataManager
    
    @Dependency
    private var accountManager: AccountManager

    /**
     Conform results to `ReturnsValue` to allow people to compose their own shortcuts, using intents and their outputs as the building blocks.
     For example, this intent returns `[TrailEntity]`. An individual could write a shortcut to pick the first trail from the result array of this
     intent, then pass that selected trail to `GetTrailInfo`.
     */
    func perform() async throws -> some IntentResult & ReturnsValue<[TrailEntity]> {
        /**
         Verify that an individual has an account to search for trails. If not, request that they log in using the app, and continue the app in the
         foreground. Bring the app to the foreground by conforming to `ForegroundContinuableIntent`.
         */
        Logger.intentLogging.debug("[SuggestTrails] Checking if the user is logged in")
        if !accountManager.loggedIn {
            Logger.intentLogging.debug("[SuggestTrails] User is not logged in")
            let dialog = IntentDialog("You are not logged in. Press the Continue button to open the app and log in.")
            throw needsToContinueInForegroundError(dialog) {
                /**
                 Use this closure, if needed, to update app state after transitioning the app to the foreground, such as to update UI to show
                 information on resolving the error.
                 */
            }
        }
        
        /// Verify that the intent's parameters have usable values before proceeding.
        try await validateParameters()
        
        /// Pick trails out of a collection, either the one that the individual has provided or the entire set of trails.
        let resolvedTrailCollection = trailCollection ?? trailManager.completeTrailCollection
        
        /// The starting list of trails to then apply further filters on.
        var trailsMatchingConditions = trailManager.trails(with: resolvedTrailCollection.members)
        Logger.intentLogging.debug("[SuggestTrails] Initial result count is \(trailsMatchingConditions.count)")
        trailsMatchingConditions = trailsMatchingConditions.filter { $0.activities.contains(activity) }
        Logger.intentLogging.debug("[SuggestTrails] Applied activity filter, result count is \(trailsMatchingConditions.count)")
        
        if var searchRadius {
            
            /// People can input data in a different unit of measurement than the unit the app stores data in. This app stores its data in meters.
            searchRadius.convert(to: .meters)
            trailsMatchingConditions = trailsMatchingConditions.filter { $0.distanceToTrail.value <= searchRadius.value }
            Logger.intentLogging.debug("[SuggestTrails] Applied searchRadius filter, result count is \(trailsMatchingConditions.count)")
        }
        
        if let location {
            trailsMatchingConditions = trailsMatchingConditions.filter { $0.regionDescription == location }
            Logger.intentLogging.debug("[SuggestTrails] Applied location filter, result count is \(trailsMatchingConditions.count)")
        }
        
        Logger.intentLogging.debug("[SuggestTrails] Returning suggestions, final count is \(trailsMatchingConditions.count)")
        let result = trailsMatchingConditions.map { TrailEntity(trail: $0) }
        return .result(value: result)
    }
    
    /// - Tag: disambiguation_dialog
    private func validateParameters() async throws {
        Logger.intentLogging.debug("[SuggestTrails] Validating parameters")
        
        /// This intent requires a value for one of the parameters. If people provide neither, request that they provide a value for `location`.
        if location == nil && searchRadius == nil && trailCollection == nil {
            Logger.intentLogging.debug("[SuggestTrails] No parameter values provided, need more information to proceed.")
            throw $location.needsValueError(IntentDialog("Please provide a location."))
        }
        
        /**
         `location` is a String parameter. Even though the associated `DynamicOptionsProvider` helps people select a valid value, they can
         provide any string for the parameter, such as by referencing a Text variable in the Shortcuts app. The intent needs to validate that the
         parameter value is usable.
         */
        if let location {
            let uniqueLocations = trailManager.uniqueLocations
            
            /// There was not an exact match for `location`. Request that the individual refine the value.
            if !uniqueLocations.contains(location) {
                /**
                 Include `IntentDialog` throughout your app intent's flow, so that people who run your intent through Siri have a great voice-only
                 experience. Below are several examples of validating input and when to use different types of responses, such as
                 `requestConfirmation` and `needsDisambiguationError`, with custom dialog to ask people to clarify what they mean.
                 */
                
                Logger.intentLogging.debug("[SuggestTrails] Did not find exact match for \(location)")
                
                let suggestedMatches = uniqueLocations.filter { $0.contains(location) }
                if suggestedMatches.count == 1 {
                    /**
                     There appears to be a close match to the value the individual provided. Ask them to confirm that the app identified the correct
                     location. Example: Confirm "Yosemite" means "Yosemite National Park."
                     */
                    Logger.intentLogging.debug("[SuggestTrails] There is one location containing '\(location)', confirm this is correct")
                    
                    let suggestion = suggestedMatches.first!
                    let dialog = IntentDialog("Did you mean \(suggestion)?")
                    let confirmed = try await $location.requestConfirmation(for: suggestion, dialog: dialog)
                    if confirmed {
                        self.location = suggestion
                    } else {
                        /**
                         Because the individual indicated the suggestion for location was incorrect, throw `needsValueError` to have them provide
                         different input.
                         */
                        throw $location.needsValueError()
                    }
                } else if !suggestedMatches.isEmpty && suggestedMatches.count < 5 {
                    /**
                     The app can't identify which location the individual might have intended, but there are a few close matches, so prompt
                     them to select one of the matches. Example: Choose between several location types with the input "National Forest".
                     
                     Provide fewer than five options for disambiguation. When an intent is running as a voice-only experience, such as through
                     HomePod, the system reads each item of the disambiguation. Since there were too many items to disambiguate, request
                     that the individual provide a different term.
                     */
                    Logger.intentLogging.debug(
                        "[SuggestTrails] There are \(suggestedMatches.count) locations that might match, asking the user to choose"
                    )
                    
                    let dialog = IntentDialog("Multiple locations match \(location). Did you mean one of these locations?")
                    let disambiguationList = suggestedMatches.sorted(using: KeyPathComparator(\.self, comparator: .localizedStandard))
                    throw $location.needsDisambiguationError(among: disambiguationList, dialog: dialog)
                } else {
                    /// The app can't identify which location the individual intended, and there are either no matches or too many matches to suggest.
                    Logger.intentLogging.debug("[SuggestTrails] There are no locations that match, start over")
                    throw $location.needsValueError(IntentDialog("Did not recognize \(location) as a location."))
                }
            } else {
                Logger.intentLogging.debug("[SuggestTrails] Exact match found for \(location)")
            }
        }
    }
}
