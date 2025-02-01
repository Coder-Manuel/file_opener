#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint file_opener.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'file_opener'
  s.version          = '0.0.1'
  s.summary          = 'A file opener plugin.'
  s.description      = <<-DESC
A Flutter plugin for opening files with native apps.
                       DESC
  s.homepage         = 'https://github.com/Coder-Manuel/file_opener'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Coder Manuel' => 'https://github.com/Coder-Manuel' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/Flutter',
    'SWIFT_OBJC_BRIDGING_HEADER' => '${PODS_TARGET_SRCROOT}/Classes/file_opener-Bridging-Header.h'
  }

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.preserve_paths = 'Classes/module.modulemap'
  s.module_map = 'Classes/module.modulemap'
  s.public_header_files = 'Classes/**/*.h'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'file_opener_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
