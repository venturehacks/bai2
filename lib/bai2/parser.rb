require 'bai2/record'

module Bai2

  class ParseError < Exception; end

  module Parser

    # Wrapper object to represent a tree node.
    #
    class ParseNode

      def initialize(record)
        @code, @records = record.code, [record]
        @children = []
      end
      attr_reader :code
      attr_accessor :records, :children
    end


    class << self

      # Parsing is a two-step process:
      #
      # 1. Build a tree
      # 2. Parse the tree
      #
      def parse(data)

        # split records, handle stupid DOS-format files, instantiate records
        records = data.split("\n").map(&:chomp).map {|l| Record.new(l) }

        # merge continuations
        records = merge_continuations(records)

        # build the tree
        root = parse_tree(records)

        root
      end


      # =========================================================================
      # Parsing implementation
      #

      private

      # Merges continuations
      #
      def merge_continuations(records)
        merged = []
        records.each do |record|
          if record.code == :continuation
            last       = merged.pop
            new_record = Record.new(last.raw + ",\n" + record.fields[:continuation],
                                    last.physical_record_count + 1)
            merged << new_record
          else
            merged << record
          end
        end
        merged
      end


      # Builds the tree of nodes
      #
      def parse_tree(records)

        # build tree, should return a file_header node
        first, *records = *records
        unless first.code == :file_header
          raise ParseError.new('Expecting file header record (01).')
        end
        root = ParseNode.new(first)
        stack = [root]

        records.each do |record|
          raise ParseError.new('Unexpected record.') if stack.empty?

          case record.code

            # handling headers
          when :group_header, :account_identifier

            parent = {group_header:       :file_header,
                      account_identifier: :group_header}[record.code]
            unless stack.last.code == parent
              raise ParseError.new("Parsing #{record.code}, expecting #{parent} parent.")
            end

            n = ParseNode.new(record)
            stack.last.children << n
            stack << n

            # handling trailers
          when :account_trailer, :group_trailer, :file_trailer

            parent = {account_trailer: :account_identifier,
                      group_trailer:   :group_header,
                      file_trailer:    :file_header}[record.code]
            unless stack.last.code == parent
              raise ParseError.new("Parsing #{record.code}, expecting #{parent} parent.")
            end

            stack.last.records << record
            stack.pop

            # handling continuations
          when :continuation

            n = (stack.last.children.last || stack.last)
            n.records << record

            # handling transactions
          when :transaction_detail

            unless stack.last.code == :account_identifier
              raise ParseError.new("Parsing #{record.code}, expecting account_identifier parent.")
            end

            stack.last.children << ParseNode.new(record)

            # handling special known errors
          else # nil
            raise ParseError.new('Unknown or unexpected record code.')
          end
        end

        unless stack == []
          raise ParseError.new('Reached unexpected end of input (EOF).')
        end

        # root now contains our parsed tree
        root
      end

    end
  end
end
