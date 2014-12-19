
module Bai2

  # This crazy neat hack lets us implement a Struct-like superclass that lets us
  # abstract away common code to build a bunch of accessors for record fields.
  #
  class RecordFieldAccessor

    singleton_class.class_eval do
      alias :old_new :new
    end
    def self.new(type)

      # Code in here is as if it were written for each superclass' definition.
      Class.new(self) do

        singleton_class.class_eval do
          alias :new :old_new
        end

        # For each field for that type, define an accessor.
        Record::FIELDS[type].each do |field|

          define_method(field.to_sym) do
            self.record[field]
          end
        end unless Record::FIELDS[type].nil?
      end
    end

    def self.parse(node)
      self.new.tap do |g|
        g.send(:parse, node)
      end
    end

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
      account_identifier: %w[record_code customer_account_number currency_code
                             type_code amount item_count funds_type],
      transaction_detail: %w[record_code type_code amount funds_type
                             bank_reference_number customer_reference_number
                             text],
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

end
