#
#  Be sure to run `pod spec lint ImageLoader.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "ImageLoader"
  spec.version      = "1.0.0"
  spec.summary      = "An optimized image downloading library that allows caching images as well as network requests."

  spec.homepage     = "https://github.com/pmtatar/ios-helpers"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "pmtatar" => "prathameshtatar@gmail.com" }
  spec.platform     = :ios, "11.0"
  spec.swift_versions = "5"
  spec.source       = { :git => "https://github.com/pmtatar/ios-helpers.git", :tag => "v" + spec.version.to_s }

  spec.source_files  = "ImageLoader/ImageLoader/**/*.{swift}"

end
