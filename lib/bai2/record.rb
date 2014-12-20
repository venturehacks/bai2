
module Bai2

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
    SIMPLE_FIELD_MAP = {
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
      continuation:       %w[record_code continuation],
      # TODO: could continue any record at any point...
    }


    def initialize(line)
      @code = RECORD_CODES[line[0..1]]
      # clean / delimiter
      @raw = line.sub(/,\/.+$/, '').sub(/\/$/, '')
      @fields = parse_raw(@code, @raw)
    end

    attr_reader :code, :raw, :fields


    private

    def parse_raw(code, line)

      fields = (SIMPLE_FIELD_MAP[code] || []).map(&:to_sym)
      if !fields.empty?
        Hash[fields.zip(line.split(',', fields.count))]
      elsif respond_to?("parse_#{code}_fields".to_sym)
        send("parse_#{code}_fields".to_sym, line)
      else
        raise BaiFile::ParseError.new('Unknown record code.')
      end
    end

    # Special cases need special implementations.
    #
    def parse_account_indentifier_fields(record)

      record_code, amount, record = clean.split(',', 3)
      {}
    end

  end
end
