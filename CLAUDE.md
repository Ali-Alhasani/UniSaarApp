# UniSaarApp iOS Upgrade Guidelines

## Project Boundaries
- ONLY modify files inside the `iOSApp/` directory.
- DO NOT touch, modify, or delete anything in `server/` or `docs/`.

## Upgrade Requirements
1. **Target Environment**: Modernize the project deployment target to the latest stable iOS SDK.
2. **Language Syntax**: Refactor old Swift patterns. Comply with modern Swift Concurrency (`async/await`, `Task`, `Actors`), replacing legacy completion closures.
3. **API Modernization**: Replace deprecated UIKit or SwiftUI APIs with modern equivalents.
4. **Dependencies**: Check for legacy CocoaPods or SPM configurations. Update them to fetch modern, compatible versions.
5. **Incremental Execution**: Modify files incrementally. Ensure core offline functionality remains intact.

## Build and Test Commands
- Check compilation errors using: `xcodebuild -project "iOSApp/Uni Saar.xcodeproj" -scheme "Uni Saar" -destination "generic/platform=iOS" CODE_SIGNING_ALLOWED=NO build`
