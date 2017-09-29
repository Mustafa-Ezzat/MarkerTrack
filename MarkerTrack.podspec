Pod::Spec.new do |s|
  s.name = 'MarkerTrack'
  s.version = '1.0.0'
  s.license = 'MIT'
  s.summary = ‘Track your marker on google map’
  s.homepage = 'https://github.com/mustafa2010/MarkerTrack'
  s.social_media_url = 'http://twitter.com/mustafarov'
  s.authors = { 'Mustafa' => 'mustafa.fci.cs@gmail.con' }
  s.source = { :git => 'https://github.com/mustafa2010/MarkerTrack.git', :tag => s.version }

  s.ios.deployment_target = ’10.0’
  s.requires_arc = true

  s.source_files = 'Source/*'

  s.dependency 'Alamofire'
  s.dependency 'SwiftyJSON'
  s.dependency 'GooglePlaces'
  s.dependency 'GooglePlacePicker'
  s.dependency 'GoogleMaps'

end