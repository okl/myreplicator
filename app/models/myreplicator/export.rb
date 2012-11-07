require 'exporter'

module Myreplicator
  class Export < ActiveRecord::Base
    attr_accessible(:source_schema, 
                    :destination_schema, 
                    :table_name, 
                    :incremental_column, 
                    :max_incremental_value, 
                    :export_to, 
                    :export_type,
                    :s3_path,
                    :cron, 
                    :last_run,
                    :state,
                    :error,
                    :active)

    attr_reader :filename
    
    def export
      exporter = MysqlExporter.new      
      exporter.export_table self
    end

    def filename
      @file_name ||= "#{source_schema}_#{table_name}_#{Time.now.to_i}"
    end

    def max_value
      sql = SqlCommands.max_value_sql(:incremental_col => self.incremental_column,
                                      :db => self.source_schema,
                                      :table => self.table_name)
      result = exec_on_source(sql)
      Kernel.p result.first.first

      return result.first.first
    end

    def update_max_val
      self.max_incremental_value = max_value
      self.save!
    end

    def exec_on_source sql
      result = SourceDb.exec_sql(self.source_schema, sql)
      return result
    end

    ##
    # Inner Class that connects to the source database 
    # Handles connecting to multiple databases
    ##

    class SourceDb < ActiveRecord::Base
      def self.connect db
        establish_connection(ActiveRecord::Base.configurations[db])
      end
      
      def self.exec_sql source_db,sql
        SourceDb.connect(source_db)
        return SourceDb.connection.execute(sql)
      end
    end
      
  end
end
