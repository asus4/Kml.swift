Pod::Spec.new do |s|

  s.name         = "Kml.swift"
  s.version      = "0.3.0"
  s.summary      = "Simple KML parser for Swift."

  s.homepage     = "https://github.com/asus4/Kml.swift"
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = { "asus4" => "koki.ibukuro@gmail.com" }
  s.social_media_url   = "https://twitter.com/asus4"
  s.ios.deployment_target = '8.0'

  s.source = { :git => 'https://github.com/asus4/Kml.swift.git', :tag => s.version }
  s.source_files = 'Source/*.swift'
  
  s.dependency 'AEXML',   '4.1.0'

end
