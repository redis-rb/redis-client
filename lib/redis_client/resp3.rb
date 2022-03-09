# frozen_string_literal: true

require "set"
require "strscan"

class RedisClient
  module RESP3
    extend self

    EOL = "\r\n"
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
      '+' => :read_line,
      '-' => :read_line,
      ':' => :parse_integer,
      '(' => :parse_integer,
      ',' => :parse_double,
      '_' => :parse_null,
      '*' => :parse_array,
      '%' => :parse_map,
      '~' => :parse_set
    }.freeze
    SIGILS = Regexp.union(PARSER_TYPES.keys.map { |sig| Regexp.new(Regexp.escape(sig)) })
    EOL_PATTERN = /\r\n/.freeze
    INTEGER_RANGE = ((((2**64) / 2) * -1)..(((2**64) / 2) - 1)).freeze

    def dump(payload, buffer = String.new(encoding: Encoding::BINARY, capacity: 128))
      send(TYPES.fetch(payload.class), payload, buffer)
    end

    def load(payload)
      parse(StringScanner.new(payload))
    end

    private

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

    def read_line(scanner)
      scanner.scan_until(EOL_PATTERN).byteslice(0..-3)
    end

    def parse(scanner)
      if type = scanner.scan(SIGILS)
        send(PARSER_TYPES.fetch(type), scanner)
      else
        raise UnknownType, "Unknown sigil type: #{scanner.peek(1).inspect}"
      end
    end

    def parse_boolean(scanner)
      case value = scanner.get_byte
      when 't'
        scanner.skip(EOL_PATTERN)
        true
      when 'f'
        scanner.skip(EOL_PATTERN)
        false
      else
        raise SyntaxError, "Expected `t` or `f` after `#`, got: #{value.inspect}"
      end
    end

    def parse_array(scanner)
      parse_sequence(scanner, parse_integer(scanner))
    end

    def parse_set(scanner)
      parse_sequence(scanner, parse_integer(scanner)).to_set
    end

    def parse_map(scanner)
      Hash[*parse_sequence(scanner, parse_integer(scanner) * 2)]
    end

    def parse_sequence(scanner, size)
      array = Array.new(size)
      size.times do |index|
        array[index] = parse(scanner)
      end
      array
    end

    def parse_integer(scanner)
      Integer(read_line(scanner))
    end

    def parse_double(scanner)
      case value = read_line(scanner)
      when 'inf'
        Float::INFINITY
      when '-inf'
        -Float::INFINITY
      else
        Float(value)
      end
    end

    def parse_null(scanner)
      scanner.skip(EOL_PATTERN)
      nil
    end

    def parse_blob(scanner)
      bytesize = parse_integer(scanner)
      blob = scanner.peek(bytesize)
      scanner.pos += bytesize
      scanner.skip(EOL_PATTERN)
      blob
    end
  end
end
