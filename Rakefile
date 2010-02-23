require 'rake/clean'
require 'rake/rdoctask'
require 'spec/rake/spectask'

##############################################################################
# Packaging & Installation.
##############################################################################

CLEAN.include ['pkg', '*.gem', 'doc', 'coverage']

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name        = 'iniparse'
    gem.platform    = Gem::Platform::RUBY
    gem.summary     = 'A pure Ruby library for parsing INI documents.'
    gem.description = gem.summary
    gem.author      = 'Anthony Williams'
    gem.email       = 'anthony@ninecraft.com'
    gem.homepage    = 'http://github.com/antw/iniparse'

    gem.files       = %w(LICENSE README.rdoc Rakefile VERSION) +
                      Dir.glob("{lib,spec}/**/*")

    # rdoc
    gem.has_rdoc = true
    gem.extra_rdoc_files = %w(README.rdoc LICENSE VERSION)

    # Dependencies
    gem.add_dependency 'extlib', '>= 0.9.9'
    gem.add_development_dependency 'rspec', '>= 1.2.0'
  end

  Jeweler::GemcutterTasks.new
  Jeweler::RubyforgeTasks.new
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem ' \
       'install jeweler'
end

##############################################################################
# Documentation
##############################################################################

Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "iniparse #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

##############################################################################
# Tests & Metrics.
##############################################################################

desc "Run all examples"
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.spec_opts = ['-c -f p']
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.spec_opts = ['-c -f s']
  spec.rcov = true
  spec.rcov_opts = ['--exclude', 'spec']
end

task :spec => :check_dependencies
