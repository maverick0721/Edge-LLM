#!/usr/bin/env ruby

require "pathname"
require "xcodeproj"

ROOT = Pathname(__dir__).join("..").realpath
IOS_DIR = ROOT.join("mobile", "ios")
PROJECT_PATH = IOS_DIR.join("EdgeLLMiOS.xcodeproj")
APP_NAME = "EdgeLLMiOS"
BUNDLE_ID = "com.edge.llm.ios"
DEPLOYMENT_TARGET = "26.0"

swift_files = %w[
  ChatMessage.swift
  EdgeLLMiOSApp.swift
  EdgeLLMOnDeviceChatView.swift
  EdgeLLMOnDeviceChatViewModel.swift
  OnDeviceChatEngine.swift
  ViewController.swift
]

PROJECT_PATH.rmtree if PROJECT_PATH.exist?

project = Xcodeproj::Project.new(PROJECT_PATH.to_s)
project.root_object.attributes["LastSwiftUpdateCheck"] = "2640"
project.root_object.attributes["LastUpgradeCheck"] = "2640"

main_group = project.main_group
ios_group = main_group.new_group("iOS", IOS_DIR.to_s)

target = project.new_target(:application, APP_NAME, :ios, DEPLOYMENT_TARGET)
target.product_reference.name = "#{APP_NAME}.app"

target.build_configurations.each do |config|
  settings = config.build_settings
  settings["PRODUCT_NAME"] = APP_NAME
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = BUNDLE_ID
  settings["MARKETING_VERSION"] = "1.0"
  settings["CURRENT_PROJECT_VERSION"] = "1"
  settings["GENERATE_INFOPLIST_FILE"] = "YES"
  settings["INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents"] = "YES"
  settings["INFOPLIST_KEY_UILaunchScreen_Generation"] = "YES"
  settings["INFOPLIST_KEY_UIStatusBarStyle"] = "UIStatusBarStyleDefault"
  settings["INFOPLIST_KEY_CFBundleDisplayName"] = "Edge LLM"
  settings["INFOPLIST_KEY_NSHumanReadableCopyright"] = "Copyright © 2026 Edge-LLM"
  settings["IPHONEOS_DEPLOYMENT_TARGET"] = DEPLOYMENT_TARGET
  settings["SWIFT_VERSION"] = "6.0"
  settings["SWIFT_EMIT_LOC_STRINGS"] = "YES"
  settings["TARGETED_DEVICE_FAMILY"] = "1,2"
  settings["SUPPORTS_MACCATALYST"] = "NO"
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["DEVELOPMENT_TEAM"] = ""
  settings["ENABLE_PREVIEWS"] = "YES"
end

swift_files.each do |file_name|
  file_ref = ios_group.new_file(IOS_DIR.join(file_name).to_s)
  target.add_file_references([file_ref])
end

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(PROJECT_PATH.to_s, APP_NAME, true)

project.save

puts "Generated #{PROJECT_PATH}"
