# OTFCareKit

The TheraForge OTFCareKit is a framework for creating digital health applications that help people to better understand and manage their health. The framework provides modules that can be used out of the box, or extended and customized for more targeted use cases.
Basically OTFCareKit is the fork of Apple CareKit with extra addon features such as Build Targets. 

You can read here more details about [Apple CareKit](../README.md). 

# Table of Contents
* [Installation](#installation)
* [Build Targets](#build-targets)
* [Unit Tests](#unit-tests)
* [License](#license)

# Installation <a name="installation"></a>

* [Prerequisites](#prerequisites)
* [Project Setup](#project-setup)
* [OTFCareKit in Cocoapod](#OTFCareKit-in-cocoapod)

## Prerequisites <a name="prerequisites"></a>

An Intel-based Mac running [macOS Catalina 10.15.4 or later](https://developer.apple.com/documentation/xcode-release-notes/xcode-12-release-notes).

Install the following components:

* Xcode 12 or later (SDK 14)

* CocoaPods 1.10.0 or later

For your projects make sure to target iOS 13 or later

## Project Setup <a name="project-setup"></a>

If you don't have Xcode, then follow this [Xcode article](https://medium.nextlevelswift.com/install-and-configure-xcode-7ed0c5592219) to install and configure Xcode.

After successfully installing Xcode and creating a new project, you can build your first digital health application.

The next step is to integrate OTFCareKit with your application. OTFCareKit can be installed via CocoaPods.

If you are new to CocoaPods you can refer to the [CocoaPods Guides](https://guides.cocoapods.org/using/using-cocoapods.html) to learn more about it.

CocoaPods is built with the Ruby language and can be installed with the default version of Ruby available with macOS.

Open the Terminal application (you can search for “Terminal” in Spotlight and press Return). 

Then type the following command in Terminal:

```
sudo gem install cocoapods

```

Then you  need to create a project directory in your user directory.

For example, in Terminal go to your personal directory by typing this command:





```
cd ~

```

Then create a Development directory (if you haven’t done it already) to create a project directory in it:


```
mkdir Development

```

For example, you may want to call your project *MyDigitalHealthApp* and so you would typically also create a directory with the same name in your Development directory:


```
cd Development
mkdir MyDigitalHealthApp
cd MyDigitalHealthApp

```

In your project directory, if you don’t already have a pod file (which is required by CocoaPods to install frameworks), create one with the command:

```
pod init

```

This will add a default pod file in your project directory. Once your project podfile is ready, you can start adding required podspecs under target in this file.
 

Next step is to integrate OTFCareKit with your application. OTFCareKit can be installed via Cocoapods.





## OTFCareKit in Cocoapod <a name="OTFCareKit-in-cocoapod"></a>


Integrating OTFCareKit with an existing workspace requires the below extra line in your Podfile.

Add pod 'OTFCareKit' under target in Podfile.

``` 
$ pod 'OTFCareKit'

```

Run pod install from the terminal root of your project directory, which will fetch all the external dependencies mentioned by you, and associate it with a .xcworkspace file of your project. This .xcworkspace file will be generated for you if you already do not have one.

``` 
$ pod install

```

Once you successfully install podspec, you can start importing OTFCareKit, OTFCareKitUI and OTFCareKitStore.

# Build Targets <a name="build-targets"></a>

 Theraforge OTFCareKit has included the following build targets to benefit compile time: 

   * CARE : OTFCareKit code module will be compiled. 
 
   * HEALTH : HealthKit code module will be compiled. 

# Unit Tests <a name="unit-tests"></a>

Todo: Add Video link here.

# Licence <a name="license"></a>

Todo: Add Licence here.

