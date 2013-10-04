require "myreplicator"

module Myreplicator
  ##
  # Configuration class for avoiding load the yml file everytime and cleaner config settings
  ##
  class Configuration
    attr_accessor :loader_stg_path, :mysqldump, :mysql

    yml = YAML.load(Fitle.read("#{Myreplicator.app_root}/config/myreplicator.yml"))
    Kernel.p yml
    Kernel.p yml["myreplicator"]["loader_stg_path"]
    @@loader_stg_path = yml["myreplicator"]["loader_stg_path"]
    @@mysql = yml["myreplicator"]["mysql"]
    @@mysqldump = yml["myreplicator"]["mysqldump"]
  end

  def self.config(&block)
    @@config ||= Myreplicator::Configuration.new

    yield @@config if block

    return @@config
  end
end
