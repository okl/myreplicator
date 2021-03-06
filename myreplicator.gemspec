$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "myreplicator/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "myreplicator"
  s.version     = Myreplicator::VERSION
  s.authors     = ["Sasan Padidar"]
  s.email       = ["sasan@raybeam.com"]
  s.homepage    = "https://github.com/okl/myreplicator"
  s.summary     = "File based replication for Mysql."
  s.description = "Mysql replication, could cause a number of issues if the tables that are being replicated are locked. Myreplicator is designed to replace Mysql's replication with a flat file based system. Myreplicator allows you to sync tables based on different frequencies and avoid using Mysql's built-in replication services."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.2.0"
  s.add_dependency "mysql2"
  s.add_dependency "json"
  s.add_dependency "net-ssh"
  s.add_dependency "net-sftp"
  s.add_dependency "resque"
  s.add_dependency "resque-scheduler"
  s.add_dependency "will_paginate", '~> 3.0'
  s.add_dependency "log4r", "~> 1.1"

  s.add_development_dependency "sqlite3"
  s.license = 'MIT'
end
