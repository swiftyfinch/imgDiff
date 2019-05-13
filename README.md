# imgDiff

[![Fastlane](https://img.shields.io/badge/🚀_fastlane-blue.svg?style=flat)](https://github.com/fastlane/fastlane)
[![Swift Version](https://img.shields.io/badge/Swift-4.0-orange.svg)](https://developer.apple.com/swift)
[![Platform](https://img.shields.io/cocoapods/p/Frog.svg?style=flat)](https://cocoapods.org/pods/Frog)
[![Twitter](https://img.shields.io/badge/twitter-@artFintch-blue.svg?style=flat)](https://twitter.com/artFintch)

When you use [`iOSSnapshotTestCase (previously named FBSnapshotTestCase)`](https://github.com/uber/ios-snapshot-test-case) it can be difficult to understand which `perPixelTolerance` you should define. This tiny util can help you to compare two images in the same manner as `iOSSnapshitTestCase` does that. And then you can tune the `perPixelTolerance` in your tests for sure.

###### Install:
Firstly, you should install `Fastlane`. And then go on to `Usage` topic.<br>
You can find information about `Fastlane` [here](https://docs.fastlane.tools/#getting-started).

###### Usage:
```sh
$ bundle exec fastlane imgDiff one:your_img_path1 two:your_img_path2
// 🚦 Max pixel difference: 0.2705
```

## Author

Vyacheslav Khorkov, artfintch@ya.ru
