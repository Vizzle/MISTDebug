
Pod::Spec.new do |s|
  s.name             = 'MISTDebug'
  s.version          = '0.1.0'
  s.summary          = 'A framework for debugging MIST.'
  s.description      = <<-DESC
                       A framework for debugging MIST.
                       DESC
  s.homepage         = 'https://github.com/Vizzle/MISTDebug'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wuwen' => 'wuwen.xb@alibaba-inc.com' }
  s.source           = { :git => 'https://github.com/Vizzle/MISTDebug.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  s.dependency 'Tweaks'
  s.dependency 'CocoaHTTPServer'
  s.dependency 'CocoaAsyncSocket'

  s.source_files = 'MISTDebug/**/*'
end
