#!/usr/bin/env ruby
# frozen_string_literal: true

# Idempotently configures ios/Runner.xcodeproj for system-audio capture ("内录"):
#   * BroadcastExtension target (ReplayKit Broadcast Upload Extension), embedded in Runner
#     through an "Embed Foundation Extensions" phase, Runner depends on it
#   * App Group entitlements for Runner and the extension (DR_APP_GROUP_IDENTIFIER build setting)
#   * the shared BroadcastProtocol.swift from the system_audio_capture plugin compiled into the extension
#   * localized InfoPlist.strings (en, zh-Hans) of Runner + knownRegions, when those files exist
#
# Usage (from mobile/): ruby tool/setup_ios_extension.rb
# Requires the `xcodeproj` gem (ships with CocoaPods; a Homebrew CocoaPods install is found
# automatically). Safe to re-run.
begin
  require 'xcodeproj'
rescue LoadError
  # Homebrew's CocoaPods keeps its gems in a private GEM_HOME (see the `pod` wrapper script).
  prefix = `brew --prefix cocoapods 2>/dev/null`.strip
  abort('xcodeproj gem not found: install CocoaPods (brew install cocoapods)') if prefix.empty?
  gem_home = File.join(prefix, 'libexec')
  Gem.paths = { 'GEM_HOME' => gem_home, 'GEM_PATH' => ([gem_home] + Gem.default_path).join(File::PATH_SEPARATOR) }
  require 'xcodeproj'
end

MOBILE = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(MOBILE, 'ios', 'Runner.xcodeproj')

APP_GROUP = 'group.cn.deeprespond.meeting'
EXT_NAME = 'BroadcastExtension'
EXT_BUNDLE_ID = 'cn.deeprespond.meeting.BroadcastExtension'
EXT_SOURCES = %w[SampleHandler.swift AudioMixing.swift].freeze
# Relative to the BroadcastExtension group (ios/BroadcastExtension).
SHARED_PROTOCOL = '../../packages/system_audio_capture/ios/system_audio_capture/Sources/system_audio_capture/BroadcastProtocol.swift'
EMBED_PHASE = 'Embed Foundation Extensions'
LOCALIZED_REGIONS = %w[en zh-Hans].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' } or abort('Runner target not found')
main_group = project.main_group
runner_group = main_group.children.find { |g| g.display_name == 'Runner' } or abort('Runner group not found')

def file_ref(group, path, **opts)
  group.files.find { |f| f.path == path } || group.new_reference(path, **opts)
end

# --- Shared build settings -------------------------------------------------------------------
project.build_configurations.each do |config|
  config.build_settings['DR_APP_GROUP_IDENTIFIER'] = APP_GROUP
end
deployment_target = runner.build_configurations.first.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] ||
                    project.build_configurations.first.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
abort('cannot determine IPHONEOS_DEPLOYMENT_TARGET') unless deployment_target

# --- Runner entitlements ---------------------------------------------------------------------
file_ref(runner_group, 'Runner.entitlements')
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# --- Extension group and files ---------------------------------------------------------------
ext_group = main_group.children.find { |g| g.display_name == EXT_NAME } ||
            main_group.new_group(EXT_NAME, EXT_NAME)
ext_files = EXT_SOURCES.map { |name| file_ref(ext_group, name) }
file_ref(ext_group, 'Info.plist')
file_ref(ext_group, "#{EXT_NAME}.entitlements")
file_ref(ext_group, 'BroadcastExtension.xcconfig')
protocol_ref = ext_group.files.find { |f| f.display_name == 'BroadcastProtocol.swift' } ||
               ext_group.new_reference(SHARED_PROTOCOL, :group)
protocol_ref.path = SHARED_PROTOCOL
protocol_ref.name = 'BroadcastProtocol.swift'
xcconfig_ref = ext_group.files.find { |f| f.path == 'BroadcastExtension.xcconfig' }

# --- Extension target ------------------------------------------------------------------------
ext = project.targets.find { |t| t.name == EXT_NAME }
unless ext
  ext = project.new_target(:app_extension, EXT_NAME, :ios, deployment_target, project.products_group, :swift)
end
ext.build_configurations.each do |config|
  config.base_configuration_reference = xcconfig_ref
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = EXT_BUNDLE_ID
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = "#{EXT_NAME}/Info.plist"
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_ENTITLEMENTS'] = "#{EXT_NAME}/#{EXT_NAME}.entitlements"
  s['IPHONEOS_DEPLOYMENT_TARGET'] = deployment_target
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['ENABLE_BITCODE'] = 'NO'
  s['CLANG_ENABLE_MODULES'] = 'YES'
  s['SWIFT_OPTIMIZATION_LEVEL'] = config.name == 'Debug' ? '-Onone' : '-O'
  s.delete('SWIFT_ACTIVE_COMPILATION_CONDITIONS') unless config.name == 'Debug'
end
sources = ext.source_build_phase
(ext_files + [protocol_ref]).each do |ref|
  sources.add_file_reference(ref, true) unless sources.files_references.include?(ref)
end
# System frameworks are autolinked by Swift `import`; explicit references would pin an SDK
# version path (…/iPhoneOS<ver>.sdk/…), so remove the one `new_target` adds.
ext.frameworks_build_phase.files.to_a.each do |build_file|
  ref = build_file.file_ref
  build_file.remove_from_project
  ref.remove_from_project if ref && ref.build_files.empty?
end
frameworks_group = main_group.children.find { |g| g.display_name == 'Frameworks' }
if frameworks_group
  frameworks_group.groups.each { |g| g.remove_from_project if g.children.empty? }
  frameworks_group.remove_from_project if frameworks_group.children.empty?
end

# --- Embed into Runner -----------------------------------------------------------------------
runner.add_dependency(ext) unless runner.dependencies.any? { |d| d.target == ext }
embed = runner.copy_files_build_phases.find { |p| p.name == EMBED_PHASE }
unless embed
  embed = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed.name = EMBED_PHASE
  embed.symbol_dst_subfolder_spec = :plug_ins
  embed.dst_path = ''
  # Must run before Flutter's "Thin Binary" script, otherwise Xcode reports a dependency cycle.
  thin = runner.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
  thin ? runner.build_phases.insert(thin, embed) : runner.build_phases << embed
end
unless embed.files_references.include?(ext.product_reference)
  build_file = embed.add_file_reference(ext.product_reference, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

# --- Localized InfoPlist.strings (provided by the auth/settings work) ------------------------
regions = LOCALIZED_REGIONS.select do |r|
  File.exist?(File.join(MOBILE, 'ios', 'Runner', "#{r}.lproj", 'InfoPlist.strings'))
end
unless regions.empty?
  variant = runner_group.children.find do |c|
    c.isa == 'PBXVariantGroup' && c.name == 'InfoPlist.strings'
  end
  unless variant
    variant = project.new(Xcodeproj::Project::Object::PBXVariantGroup)
    variant.name = 'InfoPlist.strings'
    variant.source_tree = '<group>'
    runner_group.children << variant
  end
  regions.each do |r|
    path = "#{r}.lproj/InfoPlist.strings"
    next if variant.children.any? { |f| f.path == path }

    ref = project.new(Xcodeproj::Project::Object::PBXFileReference)
    ref.name = r
    ref.path = path
    ref.source_tree = '<group>'
    ref.last_known_file_type = 'text.plist.strings'
    variant.children << ref
  end
  resources = runner.resources_build_phase
  resources.add_file_reference(variant, true) unless resources.files_references.include?(variant)
  project.root_object.known_regions = (project.root_object.known_regions | (%w[en Base] + regions))
end

project.save

# xcodeproj writes the comment of a local Swift package reference as its basename, while Flutter's
# SwiftPM integration looks for the full relative path in project.pbxproj — keep Xcode's form.
pbxproj = File.join(PROJECT_PATH, 'project.pbxproj')
content = File.read(pbxproj)
project.root_object.package_references.each do |ref|
  next unless ref.isa == 'XCLocalSwiftPackageReference' && ref.relative_path

  content = content.gsub("XCLocalSwiftPackageReference \"#{File.basename(ref.relative_path)}\"",
                         "XCLocalSwiftPackageReference \"#{ref.relative_path}\"")
end
File.write(pbxproj, content)
puts "Configured #{EXT_NAME} (#{EXT_BUNDLE_ID}), App Group #{APP_GROUP}, " \
     "localizations: #{regions.empty? ? 'none found' : regions.join(', ')}"
