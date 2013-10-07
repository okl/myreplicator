require "exporter"

module Myreplicator
  class Transporter < Service

    @queue = :myreplicator_transporter # Provided for Resque

    def initialize *args
      options = args.extract_options!
      super
    end

    class << self
      ##
      # Main method provided for resque
      # Reconnection provided for resque workers
      ##
      def perform
        Transporter.new.transfer # Kick off the load process
      end
    end

    ##
    # Schedules the transport job in Resque
    ##
    def schedule cron
      Resque.set_schedule("myreplicator_transporter", {
                            :cron => cron,
                            :class => "Myreplicator::Transporter",
                            :queue => "myreplicator_transporter"
                          })
    end

    ##
    # Connects to all unique database servers
    # downloads export files concurrently from multiple sources
    ##
    def transfer
      unique_jobs = Myreplicator::Export.where("active = 1").group("source_schema")
      log_info "Unique jobs: #{unique_jobs}"
      unique_jobs.each do |export|
        download export
      end
    end

    private


    def loader_stg_path
      if @loader_stg_path
        @loader_stg_path
      else
        path = Myreplicator.loader_stg_path
        Dir.mkdir(path) unless File.directory?(path)
        @loader_stg_path = path
        path
      end
    end

    def export_stg_dir source_schema
      Myreplicator.configs[source_schema]["export_stg_dir"]
    end


    ##
    # Connect to server via SSH
    # 1. Connects via SFTP
    # 2. Downloads metadata file first
    # 3. Gets dump file location from metadata
    # 4. Downloads dump file
    ##
    def download export
      log_info "Downloading files for #{export.source_schema}"
      download_dir_path = loader_stg_path
      files = completed_files(export)
      log_info "Files complete for #{export.source_schema}: #{files}"
      files.each do |f|
        export = f[:export]
        filename = f[:file]
        ActiveRecord::Base.verify_active_connections!
        ActiveRecord::Base.connection.reconnect!
        Log.run(:job_type => "transporter", :name => "metadata_file",
                :file => filename, :export_id => export.id ) do |log|
          sftp = export.sftp_to_source
          metadata = read_source_metadata(sftp, filename, download_dir_path)
          if export_completed?(metadata)
            src_export_path = metadata.export_path
            Log.run(:job_type => "transporter", :name => "export_file",
                    :file => src_export_path, :export_id => export.id) do |log|
              log_info "Downloading #{src_export_path}"
              tgt_export_path = File.join(download_dir_path, src_export_path.split("/").last)
              sftp.download!(src_export_path, tgt_export_path)
              # Clean up the file from the export server once the transport is complete
              remove!(export, json_file, src_export_path)
              #export.update_attributes!({:state => 'transport_completed'})
              # store back up as well
              unless metadata.store_in.blank?
                backup_files(metadata.backup_path, json_local_path, tgt_export_path)
              end
            end
          else
            log_info "The state of the export is not complete"
            # TO DO: remove metadata file of failed export
            remove!(export, json_file, "")
          end # end else
        end # end Log.run
      end # end files.each
    end

    def export_completed?(metadata)
      return metadata.state == "export_completed"
    end

    ##
    # Reads metadata file from the source machine
    # and returns an instantiated object
    ##
    def read_source_metadata(sftp, filename, download_dir_path)

      json_file = export_path(export, filename)
      json_local_path = File.join(download_dir_path,filename)
      log_info "Downloading metadata file #{json_file} to #{json_local_path}"
      sftp.download!(json_file, json_local_path)
      return metadata_from_file(json_local_path)
    end



    def backup_files location, metadata_path, dump_path
      FileUtils.cp(metadata_path, location)
      FileUtils.cp(dump_path, location)
    end

    def remove! export, json_file, dump_file
      ssh = export.ssh_to_source
      log_info "rm #{json_file} #{dump_file}"
      ssh.exec!("rm #{json_file} #{dump_file}")
    end

    ##
    # Gets all files ready to be exported from server
    ##
    def completed_files export
      ssh = export.ssh_to_source
      done_files = ssh.exec!(done_files_cmd(export))
      if done_files.blank?
        return []
      else
        files = done_files.split("\n")
        jobs = Export.where("active = 1 and source_schema = '#{export.source_schema}'")
        result = []
        files.each do |file|
          flag = nil
          jobs.each do |job|
            if file.include?(job.table_name)
              flag = job
              #job.update_attributes!({:state => 'transporting'})
            end
          end
          if flag
            result << {:file => file, :export => flag}
          end
        end # end files.each
        return result
      end# end else
    end # end completed_files

    def metadata_from_file json_path
      metadata = ExportMetadata.new(:metadata_path => json_path)
      return metadata
    end

    ##
    # Reads metadata file for the export path
    ##
    def get_dump_path json_path, metadata = nil
      metadata = metadata_from_file(json_path) if metadata.nil?
      return metadata.export_path
    end

    ##
    # Returns where path of dump files on remote server
    ##
    def export_path export, filename
      File.join(export_stg_dir(export.source_schema), filename)
    end

    private

    ##
    # Command for list of done files
    # Grep -s used to supress error messages
    ##
    def done_files_cmd export
      "cd #{export_stg_dir(export.source_schema)}; " +
        " grep -ls export_completed *.json"
    end

  end
end
