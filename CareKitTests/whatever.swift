//
//  whatever.swift
//  CareKit
//
//  Created by Yuan Zhu on 1/28/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

import Foundation

/*
There is a bug in XCode require a swift file which import ResearchKit.
Othereise xcode complains about:

dyld: Library not loaded: @rpath/libswiftCoreAudio.dylib
Referenced from: /Users/yuanzhu/Library/Developer/Xcode/DerivedData/CKWorkspace-ezhpuntuaxosnccibyhfzfakpckh/Build/Products/Debug-iphonesimulator/ResearchKit.framework/ResearchKit
Reason: image not found

*/
import ResearchKit