CareKit Framework
===========

![VCS](https://img.shields.io/badge/dvcs-Git%20%2B%20Submodules-tomato.svg) ![Platform](https://img.shields.io/cocoapods/p/CareKit.svg) ![CocoaPods](https://img.shields.io/cocoapods/v/CareKit.svg) ![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-yellow.svg?style=flat) [![License](https://img.shields.io/badge/license-BSD-green.svg?style=flat)](#license)

The *CareKit™ framework* is an open source software framework for creating apps that help people 
better understand and manage their health.

* [Getting Started](#gettingstarted)
* Documentation:
    * [Programming Guide](http://carekit.org/docs/docs/Overview/Overview.html)
    * [Framework Reference](http://carekit.org/docs/index.html)
* [Best Practices](../../wiki/best-practices)
* [Website](http://carekit.org) and [Blog](http://carekit.org/blog.html)
* [Developer Forum](https://forums.developer.apple.com/community/researchkit)
* [Contributing to CareKit](CONTRIBUTING.md)
* [License](#license)

Getting Started <a name="gettingstarted"></a>
===============

Requirements
------------

The primary CareKit framework codebase supports iOS and requires Xcode 7.0
or newer.
The CareKit framework has a Base SDK version of 9.0, meaning that apps
using the CareKit framework can run on devices with iOS 9.0 or newer.


Installation
------------

The latest stable version of CareKit framework can be cloned with:

```
git clone -b stable --recurse-submodules https://github.com/carekit-apple/carekit.git
```

Or, for the latest changes, use the `master` branch:

```
git clone --recurse-submodules https://github.com/carekit-apple/carekit.git
```

Building
--------

Build the CareKit framework by opening `CareKit.xcodeproj` and running the
`CareKit` framework target. Optionally, run the unit tests too.


Adding the CareKit framework to your App
------------------------------

To get started, drag `CareKit.xcodeproj` from your checkout into
your iOS app project in Xcode.

<center>
<figure>
<img src="../../wiki/AddingCareKitXcode.png" alt="Adding the CareKit framework to your
project" align="middle"/>
</figure>
</center>

Then, embed the CareKit framework as a dynamic framework in your app, by adding
it to the Embedded Binaries section of the General pane for your
target as shown in the figure below.

<center>
<figure>
<img src="../../wiki/AddedBinaries.png" width="100%" alt="Adding the CareKit framework to
Embedded Binaries" align="middle"/>
<figcaption><center>Adding the CareKit framework to Embedded Binaries</center></figcaption>
</figure>
</center>

Discovering How CareKit Works
------------------------------

One of the best ways to see how CareKit works is to look at the [OCKSample](../../tree/master/Sample/OCKSample) app. 
The simplest way to do this is to open `CKWorkspace.xcworkspace`, choose the `OCKSample` scheme, build and run the app. After that take a look at the app's code and experiment by making a few changes.

License <a name="license"></a>
=======

This project is made available under the terms of a BSD license. See the [LICENSE](LICENSE) file.