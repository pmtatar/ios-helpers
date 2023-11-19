#
#  Be sure to run `pod spec lint MultiselectImagePicker.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "MultiselectImagePicker"
  spec.version      = "1.1.0"
  spec.summary      = "Multi-select Image picker that allows selecting multiple images."

  spec.homepage     = "https://github.com/pmtatar/ios-helpers"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "pmtatar" => "prathameshtatar@gmail.com" }
  spec.platform     = :ios, "11.0"
  spec.swift_versions = "5"
  spec.source       = { :git => "https://github.com/pmtatar/ios-helpers.git", :tag => "v" + spec.version.to_s }

  spec.source_files  = "MultiselectImagePicker/MultiselectImagePicker/ImagePicker/**/*.{swift}"

end
