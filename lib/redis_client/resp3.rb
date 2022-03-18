# frozen_string_literal: true

require "set"

class RedisClient
  module RESP3
    extend self

    Error = Class.new(RedisClient::Error)
    UnknownType = Class.new(Error)
    SyntaxError = Class.new(Error)

    EOL = "\r\n".b.freeze
    EOL_SIZE = EOL.bytesize
    DUMP_TYPES = {
      String => :dump_string,
      Symbol => :dump_symbol,
      Integer => :dump_numeric,
      Float => :dump_numeric,
    }.freeze
    PARSER_TYPES = {
      '#' => :parse_boolean,
      '$' => :parse_blob,
      '+' => :parse_string,
      '=' => :parse_verbatim_string,
      '-' => :parse_error,
      ':' => :parse_integer,
      '(' => :parse_integer,
      ',' => :parse_double,
      '_' => :parse_null,
      '*' => :parse_array,
      '%' => :parse_map,
      '~' => :parse_set,
      '>' => :parse_array,
    }.transform_keys(&:ord).freeze
    INTEGER_RANGE = ((((2**64) / 2) * -1)..(((2**64) / 2) - 1)).freeze

    def dump(command, buffer = nil)
      buffer ||= new_buffer
      command = command.flat_map do |element|
        case element
        when Hash
          element.flatten
        when Set
          element.to_a
        else
          element
        end
      end
      dump_array(command, buffer)
    end

    def load(io)
      parse(io)
    end

    def new_buffer
      String.new(encoding: Encoding::BINARY, capacity: 128)
    end

    private

    def dump_any(object, buffer)
      method = DUMP_TYPES.fetch(object.class) do
        raise TypeError, "Unsupported command argument type: #{object.class}"
      end
      send(method, object, buffer)
    end

    def dump_array(array, buffer)
      buffer << '*' << array.size.to_s << EOL
      array.each do |item|
        dump_any(item, buffer)
      end
      buffer
    end

    def dump_set(set, buffer)
      buffer << '~' << set.size.to_s << EOL
      set.each do |item|
        dump_any(item, buffer)
      end
      buffer
    end

    def dump_hash(hash, buffer)
      buffer << '%' << hash.size.to_s << EOL
      hash.each_pair do |key, value|
        dump_any(key, buffer)
        dump_any(value, buffer)
      end
      buffer
    end

    def dump_numeric(numeric, buffer)
      dump_string(numeric.to_s, buffer)
    end

    def dump_string(string, buffer)
      string = string.b unless string.ascii_only?
      buffer << '$' << string.bytesize.to_s << EOL << string << EOL
    end

    if Symbol.method_defined?(:name)
      def dump_symbol(symbol, buffer)
        dump_string(symbol.name, buffer)
      end
    else
      def dump_symbol(symbol, buffer)
        dump_string(symbol.to_s, buffer)
      end
    end

    def parse(io)
      type = io.getbyte
      method = PARSER_TYPES.fetch(type) do
        raise UnknownType, "Unknown sigil type: #{type.chr.inspect}"
      end
      send(method, io)
    end

    def parse_string(io)
      io.gets(chomp: true)
    end

    def parse_error(io)
      CommandError.parse(parse_string(io))
    end

    TRUE_BYTE = 't'.ord
    FALSE_BYTE = 'f'.ord
    def parse_boolean(io)
      case value = io.getbyte
      when TRUE_BYTE
        io.skip(EOL_SIZE)
        true
      when FALSE_BYTE
        io.skip(EOL_SIZE)
        false
      else
        raise SyntaxError, "Expected `t` or `f` after `#`, got: #{value.chr.inspect}"
      end
    end

    def parse_array(io)
      parse_sequence(io, parse_integer(io))
    end

    def parse_set(io)
      parse_sequence(io, parse_integer(io)).to_set
    end

    def parse_map(io)
      Hash[*parse_sequence(io, parse_integer(io) * 2)]
    end

    def parse_push(io)
      parse_array(io)
    end

    def parse_sequence(io, size)
      array = Array.new(size)
      size.times do |index|
        array[index] = parse(io)
      end
      array
    end

    def parse_integer(io)
      Integer(io.gets)
    end

    def parse_double(io)
      case value = io.gets
      when "inf\r\n"
        Float::INFINITY
      when "-inf\r\n"
        -Float::INFINITY
      else
        Float(value)
      end
    end

    def parse_null(io)
      io.skip(EOL_SIZE)
      nil
    end

    def parse_blob(io)
      bytesize = parse_integer(io)
      blob = io.read(bytesize)
      io.skip(EOL_SIZE)
      blob
    end

    def parse_verbatim_string(io)
      bytesize = parse_integer(io)
      io.skip(4)
      blob = io.read(bytesize - 4)
      io.skip(EOL_SIZE)
      blob
    end
  end
end
