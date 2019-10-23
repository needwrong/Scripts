require 'cocoapods-pt/gem_version'
require 'pry-nav'
require 'singleton'

module PT

    class PT_internal
        include Singleton
        attr_accessor :l_names_using_source, :l_names_using_binary
        attr_accessor :l_versions_using_binary
        attr_accessor :lib_path
        attr_accessor :main_target_name

        def initialize
            @l_names_using_binary = []
            @l_names_using_source = []
            @l_versions_using_binary = {}
        end
    end

    class Config
        def self.keyword
            :tb_fast
        end
    end

    EXCLUDE_SOURCE_PATTERN = "**/*{.m,.mm,.i,.c,.cc,.cxx,.cpp,.c++,.swift,.ipp,.tpp,.def,.inl,.inc}"
end

module Pod
    class Specification
        attr_accessor :ttt
    end
end

module Pod

    class Installer
        alias _pt_resolve_dependencies resolve_dependencies

        include PT

        # modify spec before generating projects
        def resolve_dependencies
            _pt_resolve_dependencies

            puts "plugin hook after resolve_dependencies"

            pt_internal = PT_internal.instance


            specifications = analysis_result.specifications
            specs_to_modify = specifications.select do |s|
                pt_internal.l_names_using_binary.index(s.name)
            end

            specs_to_modify.map do |s|
                # :exclude_files has no getter
                exclude_files = [s.attributes_hash["exclude_files"]]

                s.exclude_files = [exclude_files, PT::EXCLUDE_SOURCE_PATTERN].flatten

                s.subspecs.each do |subs|
                    exclude_files = [subs.attributes_hash["exclude_files"]]
                    subs.exclude_files = [exclude_files, PT::EXCLUDE_SOURCE_PATTERN].flatten
                end

            end
        end
       
    end
end

module Pod
    module ExternalSources
        class AbstractExternalSource
            include PT

            alias _pt_validate_podspec validate_podspec

            def validate_podspec(podspec)

                pt_internal = PT_internal.instance
                if pt_internal.l_names_using_binary.include?(podspec.name)
                    lib_version = podspec.version.version
                    lib_path = "#{ENV["PWD"]}/#{pt_internal.lib_path}/#{podspec.name}/#{lib_version}/lib#{podspec.name}.a"

                    if File.exist?(lib_path)
                        pt_internal.l_versions_using_binary.merge!({podspec.name => lib_version})
                        podspec.script_phase = nil

                        UI.info("binary path for #{podspec.name}: #{lib_path}".green)
                    else
                        UI.info("lib config for #{podspec.name} error, #{lib_path} not exists, use source instead".red)
                        pt_internal.l_names_using_binary.delete(podspec.name)
                    end
                    
                end

                # pt_internal.l_names_using_binary = [] unless pt_internal.l_names_using_binary
                # pt_internal.l_names_using_binary << podspec.name if podspec.ttt

                # binding.pry
                # values = podspec.to_hash
                # pod_target_xcconfig = values["pod_target_xcconfig"]
                # pod_target_xcconfig = (values["pod_target_xcconfig"] = {}) unless pod_target_xcconfig

                # library_search_paths = pod_target_xcconfig["LIBRARY_SEARCH_PATHS"]
                # library_search_paths = (pod_target_xcconfig["LIBRARY_SEARCH_PATHS"] = "") unless library_search_paths

                # library_search_paths = library_search_paths + " $(SRCROOT)/../../tb-binary/GPUImage/0.0.1.0"
                # pod_target_xcconfig["LIBRARY_SEARCH_PATHS"] = library_search_paths
                # pod_target_xcconfig["OTHER_LDFLAGS"] = '-lGPUImage'

                # podspec.pod_target_xcconfig = pod_target_xcconfig
                # podspec.source_files  = "src/*.{h}"

                # podspec.public_header_files = "**/*.h"

                _pt_validate_podspec podspec
            end
        end
    end
end

module Pod
    class Podfile
        module DSL
            include PT

            def libConfig(options = {})
                pt_internal = PT_internal.instance
                pt_internal.lib_path = options[:path]

                UI.puts("binary library path: #{ENV["PWD"]}/#{pt_internal.lib_path}".cyan)
                unless pt_internal.lib_path && File.exist?("#{ENV["PWD"]}/#{pt_internal.lib_path}")
                    raise Informative, "invalid binary lib path provided"
                end

                pt_internal.main_target_name = options[:main_target]
                b_main_target_valid = false
                
                # use method in Podfile class to access current_target_definition
                current_target_definition.children.each do |target|
                    if target.name == pt_internal.main_target_name
                        b_main_target_valid = true;
                    end

                    target.dependencies.each do |dep|
                        # dep.to_s: "protobuf (from `lib/protobuf`)"
                        if dep.external_source && dep.external_source.delete(PT::Config.keyword)
                            pt_internal.l_names_using_binary << dep.name
                        end
                    end
                    # pt_get_hash_value('dependencies')
                end 

                unless b_main_target_valid
                    raise Informative, "invalid main_target #{pt_internal.main_target_name}."
                end

                UI.puts("libs using binary: #{pt_internal.l_names_using_binary}".cyan);
            end


#             old_pod_method = instance_method(:pod)

#             define_method(:pod) do |name, *args|
#                 pt_internal = PT_internal.instance

# binding.pry

#                 if !pt_internal.main_target_name
#                     old_pod_method.bind(self).(name, *args)
#                     return
#                 end
                
#                 local = false
#                 should_prebuild = true

#                 options = args.last
#                 if options.is_a?(Hash) and options[PT::Config.keyword] != nil
#                     should_prebuild = options[PT::Config.keyword]
#                     local = (options[:path] != nil)
#                 end
                
#                 if should_prebuild and (not local)

#                     if current_target_definition.platform == :watchos
#                         Pod::UI.warn "Binary doesn't support watchos currently: #{name}."
#                         return
#                     end

#                     options.remove(PT::Config.keyword)
#                     pt_internal.l_names_using_binary << dep.name
#                     UI.puts("remote libs using binary: #{dep.name}".cyan);

#                     old_pod_method.bind(self).(name, *args)
#                 end
#             end
        end
    end
end

module Pod
    class Podfile
        class TargetDefinition
            def pt_get_hash_value(key)
                get_hash_value(key)
            end
        end
    end
end


