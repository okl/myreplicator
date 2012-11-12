module Myreplicator
  module SqlCommands
    
    def self.mysqldump *args
      options = args.extract_options!
      options.reverse_merge! :flags => []
      db = options[:db]

      flags = ""

      self.dump_flags.each_pair do |flag, value|
        if options[:flags].include? flag
          flags += " --#{flag} "
        elsif value
          flags += " --#{flag} "
        end
      end

      cmd = Myreplicator.mysqldump
      cmd += "#{flags} -u#{db_configs(db)["username"]} -p#{db_configs(db)["password"]} "
      cmd += "-h#{db_configs(db)["host"]} " if db_configs(db)["host"]
      cmd += " -P#{db_configs(db)["port"]} " if db_configs(db)["port"]
      cmd += " #{db} "
      cmd += " #{options[:table_name]} "
      cmd += "--tab=#{options[:filepath]} "
      cmd += "--fields-enclosed-by=\'\"\' "
      cmd += "--fields-escaped-by=\'\\\\\' "

      puts cmd
      return cmd
    end

    def self.db_configs db
      ActiveRecord::Base.configurations[db]
    end
    
    def self.dump_flags
      {"add-locks" => true,
        "compact" => false,
        "lock-tables" => false,
        "no-create-db" => true,
        "no-data" => false,
        "quick" => true,
        "skip-add-drop-table" => true,
        "create-options" => false,
        "single-transaction" => false
      }
    end

    def self.mysql_export *args
      options = args.extract_options!
      options.reverse_merge! :flags => []
      db = options[:db]

      flags = ""

      self.mysql_flags.each_pair do |flag, value|
        if options[:flags].include? flag
          flags += " --#{flag} "
        elsif value
          flags += " --#{flag} "
        end
      end

      cmd = Myreplicator.mysql
      cmd += "#{flags} -u#{db_configs(db)["username"]} -p#{db_configs(db)["password"]} " 
      cmd += "-h#{db_configs(db)["host"]} -P#{db_configs(db)["port"]} "
      cmd += "--execute=\"#{options[:sql]}\" "
      cmd += "--tee=#{options[:filepath]} "
      
      puts cmd
      return cmd
    end

    def self.mysql_flags
      {"column-names" => false,
        "quick" => true,
        "reconnect" => true
      }    
    end

    def self.export_sql *args
      options = args.extract_options!
      sql = "SELECT * FROM #{options[:db]}.#{options[:table]} " 
      
      if options[:incremental_col] && options[:incremental_val]
        sql += "WHERE #{options[:incremental_col]} >= #{options[:incremental_val]}"
      end

      return sql
    end

    def self.max_value_sql *args
      options = args.extract_options!
      sql = ""

      if options[:incremental_col]
        sql = "SELECT max(#{options[:incremental_col]}) FROM #{options[:db]}.#{options[:table]}" 
      else
        raise Myreplicator::Exceptions::MissingArgs.new("Missing Incremental Column Parameter")
      end
      
      return sql
    end

    def self.mysql_export_outfile
      
    end

  end
end
