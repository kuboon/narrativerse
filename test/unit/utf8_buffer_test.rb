require "test_helper"

class Utf8BufferTest < ActiveSupport::TestCase
  def setup
    @buffer = MessagesController::Utf8Buffer.new
  end

  test "returns full string when valid utf-8" do
    assert_equal "hello", @buffer.append("hello")
  end

  test "buffers partial utf-8 and returns when complete" do
    char = "あ" # \xE3\x81\x82
    bytes = char.b

    # Send first 2 bytes
    assert_equal "", @buffer.append(bytes[0...2])

    # Send last byte
    assert_equal "あ", @buffer.append(bytes[2])
  end

  test "handles mixed valid and partial utf-8" do
    char = "あ"
    bytes = char.b

    # "hello" + first 2 bytes of "あ"
    assert_equal "hello", @buffer.append("hello".b + bytes[0...2])

    # last byte of "あ" + "world"
    assert_equal "あworld", @buffer.append(bytes[2] + "world".b)
  end

  test "handles 4-byte characters" do
    char = "𠮷" # \xF0\xA0\xAE\xB7
    bytes = char.b

    assert_equal "", @buffer.append(bytes[0...1])
    assert_equal "", @buffer.append(bytes[1...2])
    assert_equal "", @buffer.append(bytes[2...3])
    assert_equal "𠮷", @buffer.append(bytes[3...4])
  end
end

class FilteredLoggerTest < ActiveSupport::TestCase
  test "scrubs invalid utf-8 sequences" do
    base_logger = Logger.new(nil)
    logger = FilteredLogger.new(base_logger)

    invalid_string = "あ".b[0...2] # Incomplete "あ"

    # This should not raise "log writing failed" error and should be scrubbed
    assert_nothing_raised do
      logger.info(invalid_string)
    end
  end
end
