source ENV['GEM_SOURCE'] || "https://rubygems.org"

gem 'json_pure', '<2.0.2'

group :development, :test do
  gem 'puppetlabs_spec_helper',               :require => 'false'
  gem 'rspec-puppet', '~> 2.2.0',             :require => 'false'
  gem 'rspec-puppet-facts',                   :require => 'false'
end

group :system_tests do
  gem 'beaker-rspec',                 :require => 'false'
  gem 'beaker-puppet_install_helper', :require => 'false'
  gem 'r10k',                         :require => 'false'
end

if facterversion = ENV['FACTER_GEM_VERSION']
  gem 'facter', facterversion, :require => false
else
  gem 'facter', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby
