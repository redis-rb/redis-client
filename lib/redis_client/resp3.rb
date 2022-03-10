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
    TYPES = {
      String => :dump_string,
      Integer => :dump_integer,
      Float => :dump_float,
      Array => :dump_array,
      Set => :dump_set,
      Hash => :dump_hash,
      TrueClass => :dump_true,
      FalseClass => :dump_false,
      NilClass => :dump_nil
    }.freeze
    PARSER_TYPES = {
      '#' => :parse_boolean,
      '$' => :parse_blob,
      '+' => :parse_string,
      '-' => :parse_string,
      ':' => :parse_integer,
      '(' => :parse_integer,
      ',' => :parse_double,
      '_' => :parse_null,
      '*' => :parse_array,
      '%' => :parse_map,
      '~' => :parse_set
    }.transform_keys(&:ord).freeze
    INTEGER_RANGE = ((((2**64) / 2) * -1)..(((2**64) / 2) - 1)).freeze

    def dump(object, buffer = new_buffer)
      send(TYPES.fetch(object.class), object, buffer)
    end

    def dump_all(objects, buffer = new_buffer)
      objects.each do |object|
        dump(object, buffer)
      end
      buffer
    end

    def load(io)
      parse(io)
    end

    private

    def new_buffer
      String.new(encoding: Encoding::BINARY, capacity: 128)
    end

    def dump_array(payload, buffer)
      buffer << '*' << payload.size.to_s << EOL
      payload.each do |item|
        dump(item, buffer)
      end
      buffer
    end

    def dump_set(payload, buffer)
      buffer << '~' << payload.size.to_s << EOL
      payload.each do |item|
        dump(item, buffer)
      end
      buffer
    end

    def dump_hash(payload, buffer)
      buffer << '%' << payload.size.to_s << EOL
      payload.each_pair do |key, value|
        dump(key, buffer)
        dump(value, buffer)
      end
      buffer
    end

    def dump_integer(payload, buffer)
      if INTEGER_RANGE.cover?(payload)
        buffer << ':' << payload.to_s << EOL
      else
        buffer << '(' << payload.to_s << EOL
      end
    end

    def dump_float(payload, buffer)
      buffer << ','
      buffer << case payload
      when Float::INFINITY
        'inf'
      when -Float::INFINITY
        '-inf'
      else
        payload.to_s
      end
      buffer << EOL
    end

    def dump_string(payload, buffer)
      buffer << '$' << payload.bytesize.to_s << EOL << payload << EOL
    end

    def dump_true(_payload, buffer)
      buffer << '#t' << EOL
    end

    def dump_false(_payload, buffer)
      buffer << '#f' << EOL
    end

    def dump_nil(_payload, buffer)
      buffer << '_' << EOL
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

    TRUE_BYTE = 't'.ord
    FALSE_BYTE = 'f'.ord
    def parse_boolean(io)
      case value = io.getbyte
      when TRUE_BYTE
        io.seek(EOL_SIZE, IO::SEEK_CUR)
        true
      when FALSE_BYTE
        io.seek(EOL_SIZE, IO::SEEK_CUR)
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
      io.seek(EOL_SIZE, IO::SEEK_CUR)
      nil
    end

    def parse_blob(io)
      bytesize = parse_integer(io)
      blob = io.read(bytesize)
      io.seek(EOL_SIZE, IO::SEEK_CUR)
      blob
    end
  end
end
