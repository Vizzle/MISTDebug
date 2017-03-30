
Pod::Spec.new do |s|
  s.name             = 'MISTDebug'
  s.version          = '0.1.5'
  s.summary          = 'A framework for debugging MIST.'
  s.description      = <<-DESC
                       A framework for debugging MIST.
                       DESC
  s.homepage         = 'http://gitlab.alibaba-inc.com/KB-iOS-OpenSource/MISTDebug'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wuwen' => 'wuwen.xb@alibaba-inc.com' }
  s.source           = { :git => 'http://gitlab.alibaba-inc.com/KB-iOS-OpenSource/MISTDebug.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  s.dependency 'Tweaks'
  s.dependency 'CocoaHTTPServer'
  s.dependency 'CocoaAsyncSocket'

  s.source_files = 'MISTDebug/**/*'
end
