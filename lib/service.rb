require 'log4r'
require 'log4r/configurator'

include Log4r

class Service

  # create logger named 'service.logger'
  Configurator.custom_levels('DETAIL', 'DEBUG', 'INFO',
                             'WARN', 'ERROR', 'FATAL')
  attr_reader :logger

  def initialize
    name = "#{self.class.name}"
    @logger = Log4r::Logger.new name.gsub("::",".")
    json_outputter = Log4r::Outputter.stdout
    json_outputter.formatter = json_formatter
    console_outputter = Log4r::Outputter.stderr
    console_outputter.formatter = console_formatter
    # TODO, have to make this stderr since we can't figure out
    # where the output is going when it's deployed.
    @logger.add(json_outputter)
  end

  # def log_debug, log_info, log_warn, etc.
  %w(detail debug info warn error fatal).each do |level|
    method_name = "log_#{level}".to_sym
      define_method(method_name) do |msg|
      logger.send level.to_sym, msg
    end
  end

  def set_level log_level
    @logger.level = log_level
  end

  private

  def json_formatter
    pattern = "{" +
      "\\\"level\\\": \\\"%l\\\","+
      "\\\"component\\\":\\\"%c\\\","+
      "\\\"timestamp\\\":\\\"%d\\\"," +
      "\\\"message\\\":\\\"%m\\\""+
      "}"
    return Log4r::PatternFormatter.new(:pattern => pattern)
  end

  def console_formatter
    pattern = "[%l] [%c] %d :: %m"
    return Log4r::PatternFormatter.new(:pattern => pattern)
  end



end
