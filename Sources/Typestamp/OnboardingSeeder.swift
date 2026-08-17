import AppKit
import Foundation
import TypestampKit

/// Seeds a fresh install's empty log with a few entries that double as a
/// tour: a welcome line, an open todo, a bookmark, and a pasted image.
@MainActor
enum OnboardingSeeder {
    private static let seededKey = "didSeedOnboarding"

    static func seedIfNeeded(model: AppModel = .shared) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey) else { return }
        defaults.set(true, forKey: seededKey)
        // Never seed a log that already has captures (an upgrade from a
        // build that predates the flag).
        guard (try? model.store.count()) == 0 else { return }

        var logoPath: String?
        if let url = Bundle.main.url(forResource: "onboarding-logo", withExtension: "png"),
            let data = try? Data(contentsOf: url)
        {
            logoPath = try? model.images.savePNG(data)
        }

        // The log reads newest first, so the last seed here lands on top:
        // the welcome line leads and the image closes the tour.
        let seeds: [(text: String?, imagePath: String?, isTodo: Bool)] = [
            (
                text: "paste an image or screenshot straight into the bar — like our logo here",
                imagePath: logoPath, isTodo: false
            ),
            (text: "https://github.com/suraj-xd/typestamp", imagePath: nil, isTodo: false),
            (
                text: "press ⇧↩ instead to log a todo — click the box when it's done",
                imagePath: nil, isTodo: true
            ),
            (
                text:
                    "welcome to Typestamp — press ⇧⌘' anywhere, type or paste, hit ↩, and it lands here with a timestamp",
                imagePath: nil, isTodo: false
            ),
        ]
        let now = Date()
        for (offset, seed) in seeds.enumerated() {
            try? model.store.save(
                text: seed.text, imagePath: seed.imagePath, isTodo: seed.isTodo,
                at: now.addingTimeInterval(TimeInterval(offset - seeds.count) * 60))
        }
    }
}
