Pod::Spec.new do |s|
  s.name                  = 'OTFCareKit'
  s.version               = '1.0'
  s.summary               = 'CareKit is an open source software framework for creating apps that help people better understand and manage their health.'
  s.homepage              = 'https://github.com/carekit-apple/CareKit/'
  s.documentation_url     = 'https://developer.apple.com/documentation/carekit'
  s.screenshots           = [ 'https://user-images.githubusercontent.com/51756298/69096972-66de0b00-0a0a-11ea-96f0-4605d04ab396.gif',
                              'https://user-images.githubusercontent.com/51756298/69107801-7586eb00-0a27-11ea-8aa2-eca687602c76.gif']
  s.license               = { :type => 'BSD', :file => 'LICENSE' }
  s.author                = { 'researchandcare.org' => 'https://www.researchandcare.org' }
  s.platform              = :ios
  s.ios.deployment_target = '13.0'
  s.watchos.deployment_target = '6.0'
  s.swift_versions = '5.0'
  s.source                = { :git => 'https://github.com/HippocratesTech/otfcarekit.git', :branch => 'main' }

  s.source_files          = 'CareKit/CareKit/**/*'
  s.exclude_files         = [ 'CareKit/CareKit/**/*.plist', 'OCKCatalog', 'OCKSample', 'DerivedData' ]
  s.xcconfig              = { 'LIBRARY_SEARCH_PATHS' => "$(SRCROOT)/Pods/**" }
  #sp.module_map            = 'CareKit/CareKit.modulemap'
  s.requires_arc          = true
  s.frameworks            = 'CareKitUI', 'CareKitStore'
  s.dependency 'CareKitStore', '1.0'
  s.dependency 'CareKitUI', '1.0'

#  s.subspec 'CareKitUI' do |cku|
#    		cku.source_files 		= 'CareKitUI/CareKitUI/**/*.swift'
#		cku.exclude_files		= 'CareKitUI/CareKitUI/**/*.plist', 'CareKitUI/CareKitUITests'

#  end


#  s.subspec 'CareKitStore' do |cks| 
#	cks.source_files 	= 'CareKitStore/CareKitStore/**/*.swift'
#	cks.exclude_files	= 'CareKitStore/CareKitStore/**/*.plist'
#  end

end
