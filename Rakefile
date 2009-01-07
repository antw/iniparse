require 'rubygems'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'
require 'spec/rake/spectask'

begin
  require 'hanna/rdoctask'
rescue LoadError
  require 'rake/rdoctask'
end

require 'lib/iniparse/version'

GEM = 'iniparse'
GEM_VERSION = IniParse::VERSION

##############################################################################
# Packaging & Installation
##############################################################################

CLEAN.include ['pkg', '*.gem', 'doc', 'coverage']

spec = Gem::Specification.new do |s|
  s.name        = GEM
  s.version     = GEM_VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = "A pure Ruby library for parsing INI documents."
  s.description = s.summary
  s.author      = 'Anthony Williams'
  s.email       = 'anthony@ninecraft.com'
  s.homepage    = 'http://github.com/anthonyw/iniparse'

  # rdoc
  s.has_rdoc = true
  s.extra_rdoc_files = %w(README.md LICENSE)

  # Uncomment this to add a dependency
  # s.add_dependency "foo"

  s.require_path = 'lib'
  s.files = %w(LICENSE README.md Rakefile) + Dir.glob("{lib,spec}/**/*")
end


Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Run :package and install the resulting .gem"
task :install => :package do
  sh %(gem install --local pkg/#{GEM}-#{GEM_VERSION}.gem)
end

desc "Run :clean and uninstall the .gem"
task :uninstall => :clean do
  sh %(gem uninstall #{GEM})
end

desc "Create a gemspec file"
task :make_spec do
  File.open("#{GEM}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

##############################################################################
# Documentation
##############################################################################
task :doc => ['doc:rdoc']
namespace :doc do

  Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_files.add(%w(LICENSE README.md lib/**/*.rb))
    rdoc.main = "README.md"
    rdoc.title = "IniParse API Documentation"
    rdoc.options << "--line-numbers" << "--inline-source"
    rdoc.rdoc_dir = 'doc'
  end

end

##############################################################################
# rSpec & rcov
##############################################################################

desc "Run all examples"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.spec_opts = ['-c -f s']
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('spec:rcov') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.spec_opts = ['-c -f s']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end
