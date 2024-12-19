# SPMTest
Swift Package Manager Test Library.

## Environments
MacOS 15.2
Xcode 16.2

## Practice
Use Xcode to open `Package.swift`.

## Tips
### [Linking the package only in debug builds](https://augmentedcode.io/2022/05/02/linking-a-swift-package-only-in-debug-builds/)
App target’s libraries.Then we’ll open build settings and look for “Excluded Source File Names” and configure release builds to ignore “[LookinServer*](https://github.com/QMUI/LookinServer)”.

Build settings configured to ignore the package in release builds.To verify this change, we can make a release build with shift+command+i (Product -> Build For -> Profiling which builds release configuration). If we check the latest build log with command+9 and clicking on the top most build item, scrolling to app target’s linker step, we can see that Xcode did not link “LookinServer”. Exactly what we wanted to achieve.

`"EXCLUDED_SOURCE_FILE_NAMES[arch=*]" = "LookinServer*";`

`pod 'LookinServer',    '1.2.6',    :configurations => ['Debug']`
