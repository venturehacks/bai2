require 'bai2/version'

module Bai2


  # This class is the main wrapper around a Bai2 file.
  #
  class BaiFile

    # Parse a file on disk:
    #
    #   f = BaiFile.parse('myfile.bai2')
    #
    def self.parse(path)
      self.new(File.read(path))
    end


    # Parse a Bai2 data buffer:
    #
    #   f = BaiFile.new(bai2_data)
    #
    def initialize(raw)
      @raw = raw
      parse(raw)
    end

    attr_reader :raw


    class ParseError < Exception; end

    private


    RECORD_CODES = {'01' => :file_header,
                    '02' => :group_header,
                    '03' => :account_identifier,
                    '16' => :transaction_detail,
                    '49' => :account_trailer,
                    '88' => :continuation,
                    '98' => :group_trailer,
                    '99' => :file_trailer }

    # Parsing is a two-step process:
    #
    # 1. Build a tree
    # 2. Parse the tree
    #
    def parse(data)

      # split records, handle stupid DOS-format files, extract type codes
      # out: [[code, record], ...]
      lines = data.split("\n").map(&:chomp).map do |r|
        [RECORD_CODES[r[0..1]], r]
      end

      root = parse_tree(lines)

    end


    # Builds the tree of nodes
    #
    # lines: an array of lines
    #
    #   [ [record_type, line],
    #     [:group_header, '...'],
    #     [...], ...]
    #
    # returns: a tree of nodes
    #
    def parse_tree(lines)

      # build tree, should return a file_header node
      first, *lines = *lines
      unless first[0] == :file_header
        raise ParseError.new('Expecting file header record (01).')
      end
      root = ParseNode.new(*first)
      stack = [root]

      lines.each do |type, line|
        raise ParseError.new('Unexpected record.') if stack.empty?

        case type

          # handling headers
        when :group_header, :account_identifier

          parent = {group_header:       :file_header,
                    account_identifier: :group_header}[type]
          unless stack.last.type == parent
            raise ParseError.new("Parsing #{type}, expecting #{parent} parent.")
          end

          n = ParseNode.new(type, line)
          stack.last.children << n
          stack << n

          # handling trailers
        when :account_trailer, :group_trailer, :file_trailer

          parent = {account_trailer: :account_identifier,
                    group_trailer:   :group_header,
                    file_trailer:    :file_header}[type]
          unless stack.last.type == parent
            raise ParseError.new("Parsing #{type}, expecting #{parent} parent.")
          end

          stack.last.records << line
          stack.pop

          # handling continuations
        when :continuation

          n = (stack.last.children.last || stack.last)
          n.records << line

          # handling transactions
        when :transaction_detail

          unless stack.last.type == :account_identifier
            raise ParseError.new("Parsing #{type}, expecting account_identifier parent.")
          end

          stack.last.children << ParseNode.new(type, line)

          # handling special known errors
        else # nil
          binding.pry
          raise ParseError.new('Unknown or unexpected record type.')
        end
      end

      unless stack == []
        raise ParseError.new('Reached unexpected end of input (EOF).')
      end

      # root now contains our parsed tree
      root
    end


    # Wrapper object to represent a tree node.
    #
    class ParseNode

      def initialize(type, record)
        @type, @records = type, [record]
        @children = []
      end
      attr_reader :type
      attr_accessor :records, :children
    end
  end

end
