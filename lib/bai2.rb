require 'bai2/version'
require 'bai2/record'
require 'bai2/parser'
require 'bai2/attr-reader-from-ivar-hash'

module Bai2


  # This class is the main wrapper around a Bai2 file.
  #
  class BaiFile

    # TODO:
    # - run checksums

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
      @groups = []
      parse(raw)
    end

    # This is the raw data. Probably not super important.
    attr_reader :raw

    # The groups contained within this file.
    attr_reader :groups


    # =========================================================================
    # Record reading
    #

    extend AttrReaderFromIvarHash

    # The transmitter and file recipient financial institutions.
    attr_reader_from_ivar_hash :@header, :sender, :receiver



    private


    # This delegates most of the work to Bai2::Parser to build the ParseNode
    # tree.
    #
    def parse(data)

      root = Parser.parse(data)

      # parse the file node; will descend tree and parse children
      parse_file_node(root)
    end


    # Parses the file_header root tree node, and creates the object hierarchy.
    #
    def parse_file_node(n)

      unless n.code == :file_header && n.records.count == 2 && \
          n.records.map(&:code) == [:file_header, :file_trailer]
        raise ParseError.new('Unexpected record.')
      end

      @header, @trailer = *n.records

      @groups = n.children.map {|child| Group.send(:parse, child) }
    end


    public

    class Group

      def initialize
        @accounts = []
      end

      attr_reader :accounts

      private
      def self.parse(node)
        self.new.tap do |g|
          g.send(:parse, node)
        end
      end

      def parse(n)

        unless n.code == :group_header && \
            n.records.map(&:code) == [:group_header, :group_trailer]
          raise ParseError.new('Unexpected record.')
        end

        @accounts = n.children.map {|child| Account.send(:parse, child) }
      end

    end


    class Account

      def initialize
        @transactions = []
      end

      attr_reader :transactions

      private
      def self.parse(node)
        self.new.tap do |g|
          g.send(:parse, node)
        end
      end

      def parse(n)

        unless n.code == :account_identifier && \
            n.records.map(&:code) == [:account_identifier, :account_trailer]
          raise ParseError.new('Unexpected record.')
        end

        @transactions = n.children.map {|child| Transaction.parse(child) }
      end

    end


    class Transaction

      def initialize
        @text = nil
      end

      attr_reader :record
      attr_reader :amount, :text, :type

      private
      def self.parse(node)
        self.new.tap do |g|
          g.send(:parse, node)
        end
      end

      def parse(n)
        head, *rest = *n.records

        unless head.code == :transaction_detail && rest.empty?
          raise ParseError.new('Unexpected record.')
        end

        @record = head

        @text = head.fields[:text]
        @amount = head.fields[:amount]

      end

    end

  end # BaiFile
end
