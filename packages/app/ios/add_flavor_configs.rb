#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get existing configurations
debug_config = project.build_configurations.find { |c| c.name == 'Debug' }
release_config = project.build_configurations.find { |c| c.name == 'Release' }
profile_config = project.build_configurations.find { |c| c.name == 'Profile' }

puts "Found base configurations:"
puts "  - Debug: #{!debug_config.nil?}"
puts "  - Release: #{!release_config.nil?}"
puts "  - Profile: #{!profile_config.nil?}"

# Remove incorrectly named configs
malformed_configs = project.build_configurations.select { |c| c.name.include?('#{flavor}') }
if malformed_configs.any?
  puts "⚠️  Removing malformed configs:"
  malformed_configs.each do |config|
    puts "    - #{config.name}"
    # Remove from build configuration list
    project.build_configuration_list.build_configurations.delete(config)
    # Also remove from targets
    project.targets.each do |target|
      target.build_configuration_list.build_configurations.delete_if { |c| c.uuid == config.uuid }
    end
  end
end

# Create flavor configurations
flavors = ['dev', 'staging']

# Get Runner target
runner_target = project.targets.find { |t| t.name == 'Runner' }
runner_debug = runner_target.build_configurations.find { |c| c.name == 'Debug' }
runner_release = runner_target.build_configurations.find { |c| c.name == 'Release' }
runner_profile = runner_target.build_configurations.find { |c| c.name == 'Profile' }

puts "\nFound Runner target configurations:"
puts "  - Debug: #{!runner_debug.nil?}"
puts "  - Release: #{!runner_release.nil?}"
puts "  - Profile: #{!runner_profile.nil?}"

flavors.each do |flavor|
  puts "\nCreating configurations for flavor: #{flavor}"
  
  # Debug-flavor (Project level)
  debug_flavor_name = "Debug-#{flavor}"
  unless project.build_configurations.find { |c| c.name == debug_flavor_name }
    debug_flavor = project.add_build_configuration(debug_flavor_name, :debug)
    debug_flavor.build_settings.merge!(debug_config.build_settings)
    puts "  ✅ Created project #{debug_flavor_name}"
  else
    puts "  ⚠️  Project #{debug_flavor_name} already exists"
  end
  
  # Debug-flavor (Target level)
  unless runner_target.build_configurations.find { |c| c.name == debug_flavor_name }
    runner_debug_flavor = runner_target.add_build_configuration(debug_flavor_name, :debug)
    runner_debug_flavor.build_settings.merge!(runner_debug.build_settings)
    puts "  ✅ Created Runner target #{debug_flavor_name}"
  else
    puts "  ⚠️  Runner target #{debug_flavor_name} already exists"
  end
  
  # Release-flavor (Project level)
  release_flavor_name = "Release-#{flavor}"
  unless project.build_configurations.find { |c| c.name == release_flavor_name }
    release_flavor = project.add_build_configuration(release_flavor_name, :release)
    release_flavor.build_settings.merge!(release_config.build_settings)
    puts "  ✅ Created project #{release_flavor_name}"
  else
    puts "  ⚠️  Project #{release_flavor_name} already exists"
  end
  
  # Release-flavor (Target level)
  unless runner_target.build_configurations.find { |c| c.name == release_flavor_name }
    runner_release_flavor = runner_target.add_build_configuration(release_flavor_name, :release)
    runner_release_flavor.build_settings.merge!(runner_release.build_settings)
    puts "  ✅ Created Runner target #{release_flavor_name}"
  else
    puts "  ⚠️  Runner target #{release_flavor_name} already exists"
  end
  
  # Profile-flavor (Project level)
  profile_flavor_name = "Profile-#{flavor}"
  unless project.build_configurations.find { |c| c.name == profile_flavor_name }
    profile_flavor = project.add_build_configuration(profile_flavor_name, :release)
    profile_flavor.build_settings.merge!(profile_config.build_settings)
    puts "  ✅ Created project #{profile_flavor_name}"
  else
    puts "  ⚠️  Project #{profile_flavor_name} already exists"
  end
  
  # Profile-flavor (Target level)
  unless runner_target.build_configurations.find { |c| c.name == profile_flavor_name }
    runner_profile_flavor = runner_target.add_build_configuration(profile_flavor_name, :release)
    runner_profile_flavor.build_settings.merge!(runner_profile.build_settings)
    puts "  ✅ Created Runner target #{profile_flavor_name}"
  else
    puts "  ⚠️  Runner target #{profile_flavor_name} already exists"
  end
end

project.save
puts "\n✅ Build configurations saved to #{project_path}"
