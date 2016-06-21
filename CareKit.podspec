
 # Copyright (c) 2016, Apple Inc. All rights reserved.

 # Redistribution and use in source and binary forms, with or without modification,
 # are permitted provided that the following conditions are met:

 # 1.  Redistributions of source code must retain the above copyright notice, this
 # list of conditions and the following disclaimer.

 # 2.  Redistributions in binary form must reproduce the above copyright notice,
 # this list of conditions and the following disclaimer in the documentation and/or
 # other materials provided with the distribution.

 # 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 # may be used to endorse or promote products derived from this software without
 # specific prior written permission. No license is granted to the trademarks of
 # the copyright holders even if such marks are included in this software.

 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 # AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 # IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 # ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 # FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 # DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 # SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 # CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 # OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 # OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#
# Podspec for CareKit.  For details see https://guides.cocoapods.org/syntax/podspec.html#specification#
#

Pod::Spec.new do |s|
  s.name                  = 'CareKit'
  s.version               = '1.0.2'
  s.summary               = 'CareKit is an open source software framework for creating apps that help people better understand and manage their health.'
  s.homepage              = 'https://github.com/carekit-apple/CareKit/'
  s.documentation_url     = 'http://carekit.org/docs/'
  s.screenshots           = [ 'http://carekit.org/docs/docs/Overview/OverviewImages/CareCard.png',
                              'http://carekit.org/docs/docs/Overview/OverviewImages/Evaluations.png',
                              'http://carekit.org/docs/docs/Overview/OverviewImages/Dashboard.png' ]
  s.license               = { :type => 'BSD', :file => 'LICENSE' }
  s.author                = { 'carekit.org' => 'http://carekit.org' }
  s.platform              = :ios, '9.0'
  s.ios.deployment_target = '9.0'
  s.source                = { :git => 'https://github.com/carekit-apple/carekit.git', :tag => s.version.to_s }
  s.source_files          = 'CareKit/**/*.{h,m}'
  s.private_header_files  = `./scripts/find_headers.rb --private CareKit CareKit.xcodeproj`.split("\n")
  s.resources             = [ 'CareKit/Assets.xcassets', 
                              'CareKit/Localization/*.lproj', 
                              'CareKit/CarePlan/OCKCarePlanStore.xcdatamodeld' ]
  s.public_header_files   = `./scripts/find_headers.rb --public CareKit CareKit.xcodeproj`.split("\n")
                              
  s.exclude_files         = [ 'docs', 'Sample', 'testing', 'DerivedData' ]
  s.module_map            = 'CareKit/CareKit.modulemap'
  s.requires_arc          = true
  s.ios.framework         = [ 'HealthKit', 'CoreData' ]

end
