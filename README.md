CareKit Framework
===========

CareKit™ is an open source software framework for creating apps that help people 
better understand and manage their health.

* [Getting Started](#gettingstarted)
* Documentation:
    * [Programming Guide](http://carekit.org/docs/docs/Overview/Overview.html)
    *  [Framework Reference](http://carekit.org/docs/index.html)
* [Best Practices](../../wiki/best-practices)
* [Contributing to CareKit](CONTRIBUTING.md)
* [Website](http://carekit.org) and [Blog](http://carekit.org/blog.html)
* [CareKit BSD License](#license)

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
<img src="../../wiki/AddedBinaries.png" width="100%" alt="Adding the ResearchKit framework to
Embedded Binaries" align="middle"/>
<figcaption><center>Adding the CareKit framework to Embedded Binaries</center></figcaption>
</figure>
</center>

Discovering How CareKit Works
------------------------------

One of the best ways to see how CareKit works is to look at the [OCKSample](../../tree/master/Sample/OCKSample) app. 
You can find it in the CareKit sample directory. You will need to add the CareKit framework to the 
sample, as described in the previous section.

Build and run OCKSample. Then take a look at the code and experiment by making a few changes. 

License<a name="license"></a>
=======

The source in the CareKit repository is made available under the
following license unless another license is explicitly identified:

```
Copyright (c) 2016, Apple Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of the copyright holder(s) nor the names of any contributors
may be used to endorse or promote products derived from this software without
specific prior written permission. No license is granted to the trademarks of
the copyright holders even if such marks are included in this software.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
