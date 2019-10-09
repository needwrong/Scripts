require 'cocoapods-pt/gem_version'
require 'pry-nav'

module PT

    def dynamicSpecAdapter(podspec)
        # podspec.public_header_files = "**/*.h"
    end
end

module Pod
    class Specification
        attr_accessor :ttt

        # module DSL
        #     extend Pod::Specification::DSL::AttributeSupport

        #     # Deprecations must be required after include AttributeSupport
        #     require 'cocoapods-core/specification/dsl/deprecations'

        #     root_attribute :ttt
        # end
        # include Pod::Specification::DSL

        # class Consumer
        #     spec_attr_accessor :ttt
        # end

    end
end

# module Pod
#     class Spec
#         attr_accessor :ttt
#     end
# end
    
# module Pod
#     class Sandbox
#         class FileAccessor
#             def ttt
#                 paths_for_attribute(:ttt)
#             end
#         end
#     end
# end

module Pod
    class Installer
        alias _pt_install! install!
        alias _pt_analyze analyze


        def install!
            puts "plugin hook before install"

            _pt_install!
        end

        def analyze(analyzer = create_analyzer)
            _pt_analyze
            puts "plugin hook after analyzer"

            # @analysis_result.specifications[0].to_hash
        end
    end
end

# 解析podspec栈
# "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-core-1.7.5/lib/cocoapods-core/specification.rb:787:in `_eval_podspec'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-core-1.7.5/lib/cocoapods-core/specification.rb:695:in `block in from_string'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-core-1.7.5/lib/cocoapods-core/specification.rb:692:in `chdir'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-core-1.7.5/lib/cocoapods-core/specification.rb:692:in `from_string'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-core-1.7.5/lib/cocoapods-core/specification.rb:675:in `from_file'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/external_sources/abstract_external_source.rb:164:in `store_podspec'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/external_sources/path_source.rb:17:in `block in fetch'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/user_interface.rb:86:in `titled_section'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/external_sources/path_source.rb:11:in `fetch'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/installer/analyzer.rb:854:in `fetch_external_source'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/installer/analyzer.rb:833:in `block (2 levels) in fetch_external_sources'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/installer/analyzer.rb:832:in `each'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/installer/analyzer.rb:832:in `block in fetch_external_sources'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/user_interface.rb:64:in `section'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/installer/analyzer.rb:831:in `fetch_external_sources'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/installer/analyzer.rb:111:in `analyze'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/installer.rb:398:in `analyze'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-pt-0.0.1/lib/cocoapods-pt.rb:52:in `analyze'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/installer.rb:221:in `block in resolve_dependencies'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/user_interface.rb:64:in `section'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/installer.rb:220:in `resolve_dependencies'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/installer.rb:156:in `install!'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-pt-0.0.1/lib/cocoapods-pt.rb:48:in `install!'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/command/install.rb:51:in `run'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/claide-1.0.3/lib/claide/command.rb:334:in `run'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/lib/cocoapods/command.rb:52:in `run'",
#  "/Users/nidong/.rvm/gems/ruby-2.6.3/gems/cocoapods-1.7.5/bin/pod:55:in `<top (required)>'",
#

module Pod
    module ExternalSources
        class AbstractExternalSource
            include PT

            alias _pt_validate_podspec validate_podspec

            def validate_podspec(podspec)
                puts "dynamic adapt " + podspec.name

                dynamicSpecAdapter podspec

                _pt_validate_podspec podspec
            end
        end
    end
end



