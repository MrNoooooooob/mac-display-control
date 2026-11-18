// Copyright © 2026 MrNoooooooob
import Foundation
@main struct DisplayProfileTests {
    static func main() {
        assert(DisplayProfileKind.offered(from: [120, 240]) == [.stability120, .gaming240])
        assert(DisplayProfileKind.offered(from: [60]).isEmpty)
        assert(DisplayProfileKind.balanced144.hertz == 144)
        let suite = "MDC-ProfileTests-2026"
        guard let defaults = UserDefaults(suiteName: suite) else { fatalError("UserDefaults unavailable") }
        defaults.removePersistentDomain(forName: suite)
        assert(DisplayProfileStore.selected(for: "LG-UUID", defaults: defaults) == nil)
        DisplayProfileStore.save(.stability120, for: "LG-UUID", defaults: defaults)
        DisplayProfileStore.save(.gaming240, for: "SECOND-UUID", defaults: defaults)
        assert(DisplayProfileStore.selected(for: "LG-UUID", defaults: defaults) == .stability120)
        assert(DisplayProfileStore.selected(for: "SECOND-UUID", defaults: defaults) == .gaming240)
        defaults.removePersistentDomain(forName: suite)
        print("PASS: profile choices, persisted per display, no unsupported rate")
    }
}
