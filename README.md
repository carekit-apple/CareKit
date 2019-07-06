![CareKit](https://user-images.githubusercontent.com/29666989/60061659-cf6acb00-96aa-11e9-90a0-459b08fc020d.png)

CareKit Framework
===========

[![License](https://img.shields.io/badge/license-BSD-green.svg?style=flat)](https://github.com/carekit-apple/CareKit#license) ![Swift](https://img.shields.io/badge/swift-5.0-brightgreen.svg) ![Xcode 11.0+](https://img.shields.io/badge/Xcode-11.0%2B-blue.svg) ![iOS 13.0+](https://img.shields.io/badge/iOS-13.0%2B-blue.svg) [![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

CareKit™ is an open source software framework for creating apps that help people better understand and manage their health.

* [Getting Started](#gettingstarted)
* Documentation:
    * [Programming Guide](http://carekit.org/docs/docs/Overview/Overview.html)
    * [Framework Reference](http://carekit.org/docs/index.html)
* [Best Practices](../../wiki/best-practices)
* [Website](http://carekit.org) and [Blog](http://carekit.org/blog.html)
* [Contributing to CareKit](CONTRIBUTING.md)
* [License](#license)

Getting Started <a name="gettingstarted"></a>
===============

Requirements
------------

The primary CareKit framework codebase supports iOS and requires Xcode 11.0
or newer.
The CareKit framework has a Base SDK version of 13.0, meaning that apps
using the CareKit framework can run on devices with iOS 13.0 or newer.


Installation
------------

The latest stable version of the CareKit™ framework is version 1.2 and can be cloned with:

```
git clone -b stable --recurse-submodules https://github.com/carekit-apple/carekit.git
```

Or, for the latest changes including early access to CareKit 2.0, use the `master` branch:

```
git clone https://github.com/carekit-apple/carekit.git
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

One of the best ways to see how CareKit works is to look at the [OCKSample](../../tree/master/OCKSample/OCKSample) app. 
The simplest way to do this is to open `CKWorkspace.xcworkspace`, choose the `OCKSample` scheme, build and run the app. After that take a look at the app's code and experiment by making a few changes.

License <a name="license"></a>
=======

This project is made available under the terms of a BSD license. See the [LICENSE](LICENSE) file.
