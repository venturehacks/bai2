require 'bai2/record'
require 'bai2/parser'
require 'bai2/integrity'
require 'bai2/attr-reader-from-ivar-hash'

module Bai2


  # This class is the main wrapper around a Bai2 file.
  #
  class BaiFile

    DEFAULT_OPTIONS = {
      account_control_ignores_summary_amounts: false,
      continuations_slash_delimit_end_of_line_only: false,
    }.freeze

    # Parse a file on disk:
    #
    #   f = BaiFile.parse('myfile.bai2')
    #
    def self.parse(path, options = {})
      self.new(File.read(path), options)
    end


    # Parse a Bai2 data buffer:
    #
    #   f = BaiFile.new(bai2_data)
    #
    def initialize(raw, options = {})
      @raw = raw
      @groups = []
      @options = DEFAULT_OPTIONS.merge(options)
      parse(raw, options)
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

    def file_creation_datetime
      @header[:file_creation_date] + @header[:file_creation_time]
    end


    private

    # This delegates most of the work to Bai2::Parser to build the ParseNode
    # tree.
    #
    def parse(data, options)

      root = Parser.parse(data, options)

      # parse the file node; will descend tree and parse children
      parse_file_node(root)

      # assert integrity
      assert_integrity!
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


    # =========================================================================
    # Entities
    #

    public

    class Group
      extend AttrReaderFromIvarHash

      def initialize
        @accounts = []
      end

      attr_reader :accounts

      attr_reader_from_ivar_hash :@header,
        :destination, :originator, :currency_code, :group_status

      def as_of_datetime
        @header[:as_of_date] + @header[:as_of_time]
      end

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

        @header, @trailer = *n.records

        @accounts = n.children.map {|child| Account.send(:parse, child) }
      end

    end


    class Account
      extend AttrReaderFromIvarHash

      def initialize
        @transactions = []
      end

      attr_reader :transactions

      attr_reader_from_ivar_hash :@header,
        :customer, :currency_code, :summaries

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

        @header, @trailer = *n.records

        @transactions = n.children.map {|child| Transaction.parse(child) }
      end

    end


    class Transaction
      extend AttrReaderFromIvarHash

      attr_reader_from_ivar_hash :@record,
        :amount, :text, :type, :bank_reference, :customer_reference

      def debit?
        type[:transaction] == :debit
      end

      def credit?
        type[:transaction] == :credit
      end

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
      end

    end

  end # BaiFile
end
