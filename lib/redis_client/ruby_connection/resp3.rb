# frozen_string_literal: true

class String
  define_method(:raw_freeze, Object.instance_method(:freeze))
end

class RedisClient
  module RESP3
    module_function

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
      String.new(encoding: Encoding::BINARY, capacity: 127)
    end

    def dump_any(object, buffer)
      method = DUMP_TYPES.fetch(object.class) do |unexpected_class|
        if superclass = DUMP_TYPES.keys.find { |t| t > unexpected_class }
          DUMP_TYPES[superclass]
        else
          raise TypeError, "Unsupported command argument type: #{unexpected_class}"
        end
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
      case type = io.getbyte
      when 35 # '#'.ord
        parse_boolean(io)
      when 36 # '$'.ord
        parse_blob(io)
      when 43 # '+'.ord
        parse_string(io)
      when 61 # '='.ord
        parse_verbatim_string(io)
      when 45 # '-'.ord
        parse_error(io)
      when 58 # ':'.ord
        parse_integer(io)
      when 40 # '('.ord
        parse_integer(io)
      when 44 # ','.ord
        parse_double(io)
      when 95 # '_'.ord
        parse_null(io)
      when 42 # '*'.ord
        parse_array(io)
      when 37 # '%'.ord
        parse_map(io)
      when 126 # '~'.ord
        parse_set(io)
      when 62 # '>'.ord
        parse_array(io)
      else
        raise UnknownType, "Unknown sigil type: #{type.chr.inspect}"
      end
    end

    def parse_string(io)
      str = io.gets_chomp
      str.force_encoding(Encoding::BINARY) unless str.valid_encoding?
      str.freeze
    end

    def parse_error(io)
      CommandError.parse(parse_string(io))
    end

    def parse_boolean(io)
      case value = io.gets_chomp
      when "t"
        true
      when "f"
        false
      else
        raise SyntaxError, "Expected `t` or `f` after `#`, got: #{value}"
      end
    end

    def parse_array(io)
      parse_sequence(io, parse_integer(io))
    end

    def parse_set(io)
      parse_sequence(io, parse_integer(io))
    end

    def parse_map(io)
      # Array.new(io.gets_integer) do
      #   [parse(io).freeze, parse(io)]
      # end.to_h
      size = io.gets_integer
      hash = HiredisConnection.rb_hash_new_capa(size)
      while size > 0
        hash[parse(io).raw_freeze] = parse(io)
        size -= 1
      end
      hash
    end

    def parse_push(io)
      parse_array(io)
    end

    def parse_sequence(io, size)
      return if size < 0 # RESP2 nil

      array = Array.new(size)
      index = -1
      size -= 1
      while index < size
        array[index += 1] = parse(io)
      end
      array
    end

    def parse_integer(io)
      Integer(io.gets_chomp)
    end

    def parse_double(io)
      case value = io.gets_chomp
      when "nan"
        Float::NAN
      when "inf"
        Float::INFINITY
      when "-inf"
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
      bytesize = io.gets_integer
      return if bytesize < 0 # RESP2 nil type

      str = io.read_chomp(bytesize)
      str.force_encoding(Encoding::BINARY) unless str.valid_encoding?
      str
    end

    def parse_verbatim_string(io)
      blob = parse_blob(io)
      blob.byteslice(4..-1)
    end
  end
end
