exec(*(["bundle", "exec", $PROGRAM_NAME] + ARGV)) if ENV['BUNDLE_GEMFILE'].nil?

task :default => :test

begin
	Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
	$stderr.puts e.message
	$stderr.puts "Run `bundle install` to install missing gems"
	exit e.status_code
end

spec = Bundler.load_gemspec("ore-rs.gemspec")

require "rubygems/package_task"

Gem::PackageTask.new(spec) do |pkg|
end

require "rake/extensiontask"

exttask = Rake::ExtensionTask.new("ore_rs", spec) do |ext|
  ext.lib_dir = "lib"
  ext.source_pattern = "*.{rs,toml}"
  ext.cross_compile  = true
  ext.cross_platform = %w[x86_64-linux x86_64-darwin arm64-darwin aarch64-linux]
end

namespace :gem do
  desc "Push any freshly-built gems to RubyGems"
  task :push do
    Rake::Task.tasks.select { |t| t.name =~ %r{^pkg/ore-rs-.*\.gem} }.each do |pkgtask|
      sh "gem", "push", pkgtask.name
    end
  end

  namespace :cross do
    task :prepare do
      require "rake_compiler_dock"
      sh "bundle package"
    end

    exttask.cross_platform.each do |platform|
      desc "Cross-compile all native gems in parallel"
      multitask :all => platform

      desc "Cross-compile a gem for #{platform}"
      task platform => :prepare do
        RakeCompilerDock.sh <<-EOT, platform: platform, image: "rbsys/rcd:#{platform}"
          set -e
          [[ "#{platform}" =~ ^a ]] && rustup default nightly
          # This re-installs the nightly version of the relevant target after
          # we so rudely switch the default toolchain
          [ "#{platform}" = "arm64-darwin" ] && rustup target add aarch64-apple-darwin
          [ "#{platform}" = "aarch64-linux" ] && rustup target add aarch64-unknown-linux-gnu

          bundle install
          rake native:#{platform} gem RUBY_CC_VERSION=3.1.0:3.0.0:2.7.0
        EOT
      end
    end
  end
end

task :release do
	sh "git release"
end

require 'yard'

YARD::Rake::YardocTask.new :doc do |yardoc|
	yardoc.files = %w{lib/**/*.rb - README.md}
end

desc "Run guard"
task :guard do
	sh "guard --clear"
end

namespace :rust do
  desc "Build Rust library"
  task :build do
    sh "cargo build --release"
  end
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new :test => :compile do |t|
	t.pattern = "spec/**/*_spec.rb"
end
