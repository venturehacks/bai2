
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
      continuation:       %w[record_code continuation],
      # TODO: could continue any record at any point...
    }


    def initialize(line)
      @code = RECORD_CODES[line[0..1]]
      # clean / delimiter
      @raw = line.sub(/,\/.+$/, '').sub(/\/$/, '')
    end

    attr_reader :code, :raw

    # NOTE: fields is called upon first user, so as not to parse records right
    # away in case they might be merged with a continuation.
    #
    def fields
      @fields ||= parse_raw(@code, @raw)
    end

    private

    def parse_raw(code, line)

      fields = (SIMPLE_FIELD_MAP[code] || []).map(&:to_sym)
      if !fields.empty?
        Hash[fields.zip(line.split(',', fields.count).map(&:chomp))]
      elsif respond_to?("parse_#{code}_fields".to_sym, true)
        send("parse_#{code}_fields".to_sym, line)
      else
        raise BaiFile::ParseError.new('Unknown record code.')
      end
    end

    # Special cases need special implementations.
    #
    # The rules here are pulled from the specification at this URL:
    # http://www.bai.org/Libraries/Site-General-Downloads/Cash_Management_2005.sflb.ashx
    #
    def parse_transaction_detail_fields(record)

      # split out the constant bits
      record_code, type_code, amount, funds_type, rest = record.split(',', 5).map(&:chomp)

      common = {
        record_code: record_code,
        type_code:   type_code,
        amount:      amount,
        funds_type:  funds_type,
      }

      with_fund_availability = \
        case funds_type
        when 'S'
          now, next_day, later, rest = rest.split(',', 4).map(&:chomp)
          common.merge(
            availability: [
              {day: 0, amount: now},
              {day: 1, amount: now},
              {day: '>1', amount: now},
            ]
          )
        when 'V'
          value_date, value_hour, rest = rest.split(',', 3).map(&:chomp)
          value_hour = '2400' if value_hour == '9999'
          common.merge(
            value_dated: {date: value_date, hour: value_hour}
          )
        when 'D'
          field_count, rest = rest.split(',', 2).map(&:chomp)
          availability = field_count.to_i.times.map do
            days, amount, rest = rest.split(',', 3).map(&:chomp)
            {days: days.to_i, amount: amount}
          end
          common.merge(availability: availability)
        else
          common
        end

      bank_ref, customer_ref, text = rest.split(',', 3).map(&:chomp)

      with_fund_availability.merge(
        bank_reference: bank_ref,
        customer_reference: customer_ref,
        text: text,
      )
    end

  end
end
