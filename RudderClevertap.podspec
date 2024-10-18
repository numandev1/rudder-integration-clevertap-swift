clevertap_sdk_version = '~> 6.2.1'
Pod::Spec.new do |s|
  s.name             = 'RudderCleverTap'
  s.version          = '1.2.0'
  s.summary          = 'Privacy and Security focused Segment-alternative. CleverTap Native SDK integration support.'

  s.description      = <<-DESC
Rudder is a platform for collecting, storing and routing customer event data to dozens of tools. Rudder is open-source, can run in your cloud environment (AWS, GCP, Azure or even your data-centre) and provides a powerful transformation framework to process your event data on the fly.
                       DESC

  s.homepage         = 'https://github.com/numandev1/rudder-integration-clevertap-swift'
  s.license          = { :type => "Elastic License 2.0", :file => "LICENSE.md" }
  s.author           = { 'RudderStack' => 'muhammadnuman70@gmail.com' }
  s.source           = { :git => 'https://github.com/numandev1/rudder-integration-clevertap-swift.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '13.0'
  
  s.source_files = 'Sources/**/*{h,m,swift}'
  s.swift_version = '5.3'

  s.dependency 'Rudder', '~> 2.2.4'
  s.dependency 'CleverTap-iOS-SDK', '~> 4.7.0'
end
