require 'cocoapods-pt/command'
require_relative 'cocoapods-pt.rb'

module PT
    Pod::HooksManager.register('cocoapods-pt', :pre_install) do |context|
    	first_target_definition = context.podfile.target_definition_list.select{ |d| d.name != 'Pods' }.first
		development_pod = first_target_definition.name.split('_').first unless first_target_definition.nil?
		    
		Pod::UI.section("Auto set share scheme for development pod: \'#{development_pod}\'") do
			# carthage 需要 shared scheme 构建 framework
			context.podfile.install!('cocoapods', :share_schemes_for_development_pods => [development_pod])
		end unless development_pod.nil?

        Pod::UI.puts "ttttttt pre_install"
    end

    Pod::HooksManager.register('cocoapods-pt', :post_install) do |context|    	
        Pod::UI.puts "ttttttt post_install"
    end
    
    Pod::HooksManager.register('cocoapods-pt', :post_update) do |context|
    	Pod::UI.puts "ttttttt post_update"
    end
end