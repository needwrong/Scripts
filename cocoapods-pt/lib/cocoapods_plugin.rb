require 'cocoapods-pt/command'
require_relative 'cocoapods-pt.rb'

module PT
    Pod::HooksManager.register('cocoapods-pt', :pre_install) do |context|
  #   	first_target_definition = context.podfile.target_definition_list.select{ |d| d.name != 'Pods' }.first
		# development_pod = first_target_definition.name.split('_').first unless first_target_definition.nil?

		# Pod::UI.section("Auto set share scheme for development pod: \'#{development_pod}\'") do
		# 	# carthage 需要 shared scheme 构建 framework
		# 	context.podfile.install!('cocoapods', :share_schemes_for_development_pods => [development_pod])
		# end unless development_pod.nil?
    end

    Pod::HooksManager.register('cocoapods-pt', :post_install) do |context|
        pt_internal = PT_internal.instance

        # PostInstallHooksContext
        context.pods_project.targets.each do |target|
            if target.name == "Pods-#{pt_internal.main_target_name}"
                target.build_configurations.each do |build_conf|
                    pathname = Pathname.new(context.pods_project.path.dirname + build_conf.base_configuration_reference.full_path)
                    config = Xcodeproj::Config.new(pathname)

                    pt_internal.l_names_using_binary.each do |name|
                        binary_version = pt_internal.l_versions_using_binary[name]

                        config.merge!('LIBRARY_SEARCH_PATHS' => "$(PODS_ROOT)/../#{pt_internal.lib_path}/#{name}/#{binary_version}", 'OTHER_LDFLAGS' => "-l#{name}")
                    end
                        
                    config.save_as(pathname)
                end
            end
        end
        
        Pod::UI.puts("libs using binary: #{pt_internal.l_names_using_binary}".cyan);

        # context.aggregate_targets.each do |aggregate_target|
        # if aggregate_target.name == "Pods-TBClient"
        #     aggregate_target.xcconfigs.each do |config_name, config_file|

        #         config_file.merge!('LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/../../tb-binary/GPUImage/0.0.1.0"', 'OTHER_LDFLAGS' => '-lGPUImage')
        #         xcconfig_path = aggregate_target.xcconfig_path(config_name)
        #         config_file.save_as(xcconfig_path)
        #     end
        # end
    end
    
    Pod::HooksManager.register('cocoapods-pt', :post_update) do |context|
    end

    Pod::HooksManager.register('cocoapods-pt', :post_build) do |context|
    end
    
end