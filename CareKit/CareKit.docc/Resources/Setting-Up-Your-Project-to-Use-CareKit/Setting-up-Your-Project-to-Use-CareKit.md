# Setting up your project to use CareKit

Add and update CareKit in your project using Swift Package Manger.

## Overview

CareKit is an open-source framework and is not part of Xcode. To use it, you need to add it to your project as a dependency using the Swift Package Manager in Xcode. This allows you to easily keep it up to date.

You can find CareKit as a repository on GitHub: [CareKit on GitHub](https://github.com/carekit-apple/CareKit).

### Add CareKit as a package dependency

Add a package dependency to your Xcode project by selecting File > Swift Packages > Add Package Dependency. Next, provide the URL of the repository: https://github.com/carekit-apple/CareKit

### Choose package options

With the package repository specified, choose which version, branch, or commit to pull from. Unless there’s a specific commit you want to pull from, choose the stable branch. For more information on specifying versions, branches, and commits, see [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app/).

### Select parts of CareKit you want to use

CareKit is built to be modular, and this includes being able to use only the parts relevant to your needs. The framework includes a complete set of libraries, pre-built view controllers, the data store, and the component views. It also synchronizes data between the UI and data layers.

CareKit includes CareKitUI and CareKitStore. If you only want to use the customizable views, choose CareKitUI. If you only need access to the data-persistence library, choose CareKitStore.

In the ‘Choose package products and targets’ dialogue, select which part or parts you want, and the targets they should be added to:

![Choose the package products](setting-up-your-project-to-use-carekit-1)

### Verify the dependency

To check whether the dependency was successfully included in your project, select your project in the Navigator, select the target, and under General scroll down to Frameworks, Libraries, and Embedded Content. You should see CareKit listed there:

![CareKit package embedded in app](setting-up-your-project-to-use-carekit-2)

If you’d like to remove CareKit from your target, select it in the list, then press the removal (-) button.

Once you’ve added CareKit to your target, use it in any of your classes by importing it:

```swift
import CareKit
```

### Update CareKit

Swift Package Manager makes it easy to keep your dependencies up to date. Every time you open a Xcode project that has CareKit included as a dependency, and you have an active internet connection, the Swift Package Manager checks for updates that match your specified rules for version, branch, or commit.

You can also manually check for an update in Xcode by selecting File > Swift Packages > Update to Latest Package Versions:

![Update Swift packages](setting-up-your-project-to-use-carekit-3)
