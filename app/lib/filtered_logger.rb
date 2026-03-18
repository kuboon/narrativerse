# frozen_string_literal: true

require "logger"

class FilteredLogger
  attr_reader :inner_logger

  def initialize(logger)
    @inner_logger = logger
  end

  def add(severity, message = nil, progname = nil, &block)
    if message.nil?
      if block
        message = block.call
      else
        message = progname
        progname = nil
      end
    end

    message_text = message.to_s
    return true if message_text.empty?
    return true if excluded?(message_text)

    message2 = message.is_a?(String) ? mutate_message(message) : message

    @inner_logger.add(severity, message2, progname)
  end

  def debug(progname = nil, &block)
    add(::Logger::DEBUG, nil, progname, &block)
  end

  def info(progname = nil, &block)
    add(::Logger::INFO, nil, progname, &block)
  end

  def warn(progname = nil, &block)
    add(::Logger::WARN, nil, progname, &block)
  end

  def error(progname = nil, &block)
    add(::Logger::ERROR, nil, progname, &block)
  end

  def fatal(progname = nil, &block)
    add(::Logger::FATAL, nil, progname, &block)
  end

  def unknown(progname = nil, &block)
    add(::Logger::UNKNOWN, nil, progname, &block)
  end

  def method_missing(method, *args, **kwargs, &block)
    @inner_logger.send(method, *args, **kwargs, &block)
  end

  def respond_to_missing?(method, _include_private = false)
    @inner_logger.respond_to?(method)
  end

  private

  def excluded?(message)
    message.include?("solid_queue_processes")
    || message.include?("Scheduler::Manager")
    || message.include?('"schema_migrations"."version"')
    || message.include?('INSERT INTO "solid_cable_messages"')
    || message.include?('INSERT INTO "solid_queue_failed_executions"')
    || message.include?("TRANSACTION")
    || message.include?("SolidQueue::Job Create")
    # || message.start_with?("[cable]")
    # || message.start_with?("[jobs]")
  end

  GID_PREFIX = Base64.strict_encode64("gid://narrativerse").freeze
  def mutate_message(message)
    # Turbo::StreamsChannel is streaming from Z2lkOi8vbmFycmF0aXZlcnNlL1Bsb3QvNw
    # base64decode
    if message.include?(GID_PREFIX)
      encoded_part = message[/#{GID_PREFIX}([A-Za-z0-9\-_]+)=*/, 0]
      if encoded_part
        decoded_part = Base64.decode64(encoded_part) rescue nil
        if decoded_part
          return message.sub(encoded_part, decoded_part)
        end
      end
    end
    message
  end
end

puts "FilteredLogger initialized."
