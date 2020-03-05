Pod::Spec.new do |s|
  s.name             = 'AYPlayer'
  s.version          = '0.1.0'
  s.summary          = 'AYPlayer is an audio persistence AVPlayer wrapper'
  s.description      = <<-DESC
AYPlayer is an ongoing project that aims to create a more usable audio video player with readable status and network persistence option.
                       DESC
  s.homepage         = 'https://github.com/andreyyoshua/AYPlayer'
  # s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Andrey Yoshua' => 'andrey.yoshua@gmail.com' }
  s.source           = { :git => 'https://github.com/andreyyoshua/AYPlayer.git', :tag => s.version.to_s }
  s.default_subspec  = 'Core'

  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.subspec 'Core' do |core|
    core.source_files = 'AYPlayer/**/*'
  end

end
