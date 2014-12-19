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

    # This is the raw data. Probably not super important.
    attr_reader :raw

    # The transmitter and file recipient financial institutions.
    attr_reader :sender, :recipient

    # The groups contained within this file.
    attr_reader :groups



    # =========================================================================
    # Parsing implementation
    #

    class ParseError < Exception; end

    private



    # Parsing is a two-step process:
    #
    # 1. Build a tree
    # 2. Parse the tree
    #
    def parse(data)

      # split records, handle stupid DOS-format files, instantiate records
      records = data.split("\n").map(&:chomp).map {|l| Record.new(l) }

      # build the tree
      @root = parse_tree(records)

      # parse the file node; will descend tree and parse children
      parse_file_node(@root)

    end


    # This class represents a record. It knows how to parse the single record
    # information, but has no knowledge of the structure of the file.
    #
    class Record


      RECORD_CODES = {'01' => :file_header,
                      '02' => :group_header,
                      '03' => :account_identifier,
                      '16' => :transaction_detail,
                      '49' => :account_trailer,
                      '88' => :continuation,
                      '98' => :group_trailer,
                      '99' => :file_trailer }
      FIELDS = {
        file_header:     %w[record_code sender_identification
                            receiver_identification file_creation_date
                            file_creation_time file_identification_number
                            physical_record_length block_size version_number],
        group_header:    %w[record_code ultimate_receiver_identification
                            originator_identification group_status as_of_date
                            as_of_time currency_code as_of_date_modifier],
        group_trailer:   %w[record_code group_control_total number_of_accounts
                            number_of_records],
        account_trailer: %w[record_code account_control_total number_of_records],
        file_trailer:    %w[record_code file_control_total number_of_groups
                            number_of_records],
      }


      def initialize(line)
        @code = RECORD_CODES[line[0..1]]
        @raw = line
        @fields = parse_raw(code, line)
      end

      attr_reader :code, :raw, :fields


      private

      def parse_raw(code, line)
        fields = (FIELDS[code] || []).map(&:to_sym)
        # TODO: raise ParseError
        return if fields.empty?
        # clean / delimiter
        clean = line.sub(/,\/.+$/, '').sub(/\/$/, '')
        Hash[fields.zip(clean.split(',', fields.count))]
      end
    end

    # Wrapper object to represent a tree node.
    #
    class ParseNode

      def initialize(record)
        @code, @records = record.code, [record]
        @children = []
      end
      attr_reader :code
      attr_accessor :records, :children


      def push_record(record)
        self
      end

      private
      def parse_record(record)
      end
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
          binding.pry
          raise ParseError.new('Unknown or unexpected record code.')
        end
      end

      unless stack == []
        raise ParseError.new('Reached unexpected end of input (EOF).')
      end

      # root now contains our parsed tree
      root
    end

    # Parses the file_header root tree node, and creates the object hierarchy.
    #
    def parse_file_node(n)
    end


  end

  class Group
  end
end
