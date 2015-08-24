Pod::Spec.new do |s|

  s.name = "FlurryLaunchOrigin"
  s.version = "0.0.1"
  s.summary = "App Launch Origin Tracker"

  s.description = <<-DESC
Handy library to instrument application cold and warm launches.
DESC

  s.homepage = "https://github.com/Flurry/FlurryLaunchOrigin"
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { "Daryl Low" => "dlow@yahoo-inc.com" }

  s.platform = :ios, '7.0'

  s.source = { :git => "https://github.com/flurry/FlurryLaunchOrigin.git", :tag => 'v' + s.version.to_s }

  s.requires_arc = true
  s.frameworks = 'Foundation', 'UIKit'
  s.default_subspec = 'FullSDK'
  
  s.subspec 'FullSDK' do |subspec|
      subspec.source_files = 'FlurryLaunchOrigin/**/*.{h,m}'
      subspec.public_header_files = "FlurryLaunchOrigin/Public/*.h"
  end
  
end
