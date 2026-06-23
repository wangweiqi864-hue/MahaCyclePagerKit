Pod::Spec.new do |s|
  s.name             = 'MahaCyclePagerKit'
  s.version          = '0.1.1'
  s.summary          = 'A private cycle pager component with cleaned-up public APIs.'

  s.description      = <<-DESC
MahaCyclePagerKit repackages the existing TYCyclePagerView implementation
into a private pod, keeps behavior compatibility, and exposes
cleaned-up public APIs for new code.
  DESC

  s.homepage         = 'https://github.com/wangweiqi864-hue/MahaCyclePagerKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wangweiqi864-hue' => 'wangweiqi864-hue@users.noreply.github.com' }
  s.source           = { :git => 'https://github.com/wangweiqi864-hue/MahaCyclePagerKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.source_files = 'MahaCyclePagerKit/Classes/**/*.{h,m}'
  s.requires_arc = true
end
