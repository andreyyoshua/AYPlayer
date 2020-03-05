Pod::Spec.new do |s|

  s.platform = :ios
  s.ios.deployment_target = '10.0'
  s.name = "AYPlayer"
  s.summary = "AYPlayer make you create a player."
  s.requires_arc = true
  
  s.version = "0.1.0"
  
  s.license = { :type => "MIT", :file => "LICENSE" }
  
  s.author = { "Andrey Yoshua" => "andrey.yoshua@gmail.com" }
  
  s.homepage = "https://github.com/andreyyoshua/AYPlayer"
  
  s.source = { :git => "https://github.com/andreyyoshua/AYPlayer" }
  s.default_subspec  = 'Source'

  s.subspec 'Source' do |source|
    source.source_files = 'AYPlayer/Sources/**/*'
  end
  
  s.framework = "AVFoundation"
  # s.dependency 'Alamofire', '~> 4.7'
  # s.dependency 'MBProgressHUD', '~> 1.1.0'
  
  # s.resources = "RWPickFlavor/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"
  
  s.swift_version = "5.0"
  
  end