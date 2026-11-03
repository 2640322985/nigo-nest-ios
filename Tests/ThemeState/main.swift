import Foundation

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}

let args = CommandLine.arguments
require(args.count == 3, "Expected isolated suite and test phase")
let defaults = UserDefaults(suiteName: args[1])!
switch args[2] {
case "seed":
    require(ThemePreference.load(from: defaults) == .monochrome, "First launch must use monochrome")
    ThemePreference.save(.journal, to: defaults)
    require(ThemePreference.load(from: defaults) == .journal, "Journal selection must apply")
    defaults.synchronize()
case "reload":
    require(ThemePreference.load(from: defaults) == .journal, "Journal must survive a new process")
    ThemePreference.save(.monochrome, to: defaults)
    defaults.synchronize()
case "fallback":
    require(ThemePreference.load(from: defaults) == .monochrome, "Switching back must persist")
    defaults.set("unknown-future-theme", forKey: ThemePreference.key)
    require(ThemePreference.load(from: defaults) == .monochrome, "Unknown values must recover safely")
    defaults.removeObject(forKey: ThemePreference.key)
    require(ThemePreference.load(from: defaults) == .monochrome, "Cleared preference must restore default")
    require(AppTheme.allCases.count == 2, "Expected both available themes")
    defaults.synchronize()
default: fatalError("Unknown test phase")
}
print("Theme preference check passed: \(args[2])")
