Pod::Spec.new do |s|

  s.name         = "Kml.swift"
  s.version      = "0.4.0"
  s.summary      = "Simple KML parser for Swift."

  s.homepage     = "https://github.com/asus4/Kml.swift"
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = { "asus4" => "koki.ibukuro@gmail.com" }
  s.social_media_url   = "https://twitter.com/asus4"
  s.ios.deployment_target = '8.0'

  s.source = { :git => 'https://github.com/asus4/Kml.swift.git', :tag => s.version }
  s.default_subspec = "Core"

  s.subspec "Core" do |ss|
    ss.source_files  = "Source/*.swift"
    ss.dependency 'AEXML'
    ss.frameworks  = "Foundation"
  end

  s.subspec "MapKit" do |ss|
    ss.source_files  = "Source/MapKit/*.swift"
    ss.dependency "Kml.swift/Core"
    ss.frameworks  = "Foundation", "MapKit"
  end

  s.subspec "Mapbox" do |ss|
    ss.source_files  = "Source/Mapbox/*.swift"
    ss.dependency "Kml.swift/Core"
    ss.dependency "Mapbox-iOS-SDK", "~> 3.3"
    ss.frameworks  = "Foundation"
  end
end
