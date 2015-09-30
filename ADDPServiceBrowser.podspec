Pod::Spec.new do |s|

  s.name         = "ADDPServiceBrowser"
  s.version      = "1.0"
  s.summary      = "Advanced Device Discovery Protocol (ADDP) library for iOS "

  s.description  = "This library returns a list of ADDP devices found within the network"

  s.homepage     = "https://github.com/DREEBIT/ADDPServiceBrowser"

  s.license      = { :type => 'The MIT License (MIT)', :file => 'LICENSE' }
  s.author             = { "Toni Moeckel" => "tonimoeckel@gmail.com" }
  s.social_media_url = "http://twitter.com/tonimoeckel"

  s.platform     = :ios, '8.0'
  s.source       = { :git => "https://github.com/DREEBIT/ADDPServiceBrowser.git", :tag => "1.0" }
  s.source_files  = 'ADDPServiceBrowser', 'ADDPServiceBrowser/**/*.{h,m}'
  s.requires_arc = true
  s.dependency = 'CocoaAsyncSocket'
end
