import AppIntents
import LockedCameraCapture

struct LockedCaptureIntent: CameraCaptureIntent {
    /// Every intent needs to include metadata, such as a localized title. The title of the intent is displayed throughout the system.
    static var title: LocalizedStringResource = "カメラ"
    /// An intent can optionally provide a localized description that the Shortcuts app displays.
    
    
    /**
     When the system runs the intent, it calls `perform()`.
     
     Intents run on an arbitrary queue. Intents that manipulate UI need to annotate `perform()` with `@MainActor`
     so that the UI operations run on the main actor.
     */
    @MainActor
    func perform() async throws -> some IntentResult {
        
        do {
            if let sample = try await LockedCaptureIntent.appContext { //TODO: ここのAppContextに、どうしたら値を持っていけるか？
                print("🌝：\(sample)")
                return .result()
            }
        } catch {
            print("🌝：\(error)")
        }
        
        /// Return an empty result, indicating that the intent is complete.
        return .result()
    }
}

