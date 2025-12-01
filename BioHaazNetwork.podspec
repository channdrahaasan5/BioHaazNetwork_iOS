Pod::Spec.new do |spec|
  spec.name         = "BioHaazNetwork"
  spec.version      = "1.0.4"
  spec.summary      = "A powerful networking SDK for iOS with offline support and comprehensive logging"
  
  spec.description  = <<-DESC
    BioHaazNetwork is a feature-rich networking SDK for iOS applications that provides:
    - HTTP methods (GET, POST, PUT, DELETE) with full customization
    - Multi-environment support (dev, qa, uat, prod)
    - Offline queue management with automatic request queuing
    - Manual offline queue processing
    - Network monitoring and automatic queue processing
    - Enhanced logging with timestamps and file output
    - File upload/download with progress tracking
    - Image loading extensions for UIImageView
    - Configurable retry policies
    - Request/response interceptors
    - Performance tracking
    - Plugin system for extensibility
    - Full Objective-C compatibility
  DESC
  
  spec.homepage     = "https://github.com/channdrahaasan5/BioHaazNetwork_iOS"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "BioHaaz Team" => "support@biohaaz.com" }
  
  spec.platform     = :ios, "13.0"
  spec.swift_version = "5.0"
  
  spec.source       = { :git => "https://github.com/channdrahaasan5/BioHaazNetwork_iOS.git", :tag => "v#{spec.version}" }
  
  spec.source_files = "BioHaazNetwork/**/*.{swift,h}"
  spec.public_header_files = "BioHaazNetwork/**/*.h"
  
  spec.frameworks   = "Foundation", "UIKit", "Network", "Combine"
  spec.requires_arc = true
  
  spec.exclude_files = [
    "BioHaazNetwork/Info.plist",
    "BioHaazNetwork/SDKInitialization.md",
    "BioHaazNetwork/SDKTopics.md",
    "BioHaazNetwork/SDKUseCases.md"
  ]
end

