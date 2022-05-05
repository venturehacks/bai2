
module Bai2

  class BaiFile
    private

    # =========================================================================
    # Integrity verification
    #

    class IntegrityError < StandardError; end

    # Asserts integrity of a fully-parsed BaiFile by calculating checksums.
    #
    def assert_integrity!
      expectation = {
        sum:      @trailer[:file_control_total],
        children: @trailer[:number_of_groups],
        records:  @trailer[:number_of_records],
      }

      # Check children count
      unless expectation[:children] == (actual = self.groups.count)
        raise IntegrityError.new("Number of groups invalid: " \
          + "expected #{expectation[:children]}, actually: #{actual}")
      end

      # Check sum vs. group sums
      actual_sum = self.groups.map do |group|
        group.instance_variable_get(:@trailer)[:group_control_total]
      end.reduce(0, &:+)

      unless expectation[:sum] == actual_sum
        raise IntegrityError.new(
          "Sums invalid: file: #{expectation[:sum]}, groups: #{actual_sum}")
      end

      # Run children assertions, which return number of records. May raise.
      records = self.groups.map {|g| g.send(:assert_integrity!, @options) }.reduce(0, &:+)

      unless expectation[:records] == (actual_num_records = records + 2)
        raise IntegrityError.new(
          "Record count invalid: file: #{expectation[:records]}, groups: #{actual_num_records}")
      end

      actual_num_records
    end


    public


    class Group
      private

      # Asserts integrity of a fully-parsed BaiFile by calculating checksums.
      #
      def assert_integrity!(options)
        expectation = {
          sum:      @trailer[:group_control_total],
          children: @trailer[:number_of_accounts],
          records:  @trailer[:number_of_records],
        }

        # Check children count
        unless expectation[:children] == (actual = self.accounts.count)
          raise IntegrityError.new("Number of accounts invalid: " \
            + "expected #{expectation[:children]}, actually: #{actual}")
        end

        # Check sum vs. account sums
        actual_sum = self.accounts.map do |acct|
          acct.instance_variable_get(:@trailer)[:account_control_total]
        end.reduce(0, &:+)

        unless expectation[:sum] == actual_sum
          raise IntegrityError.new(
            "Sums invalid: file: #{expectation[:sum]}, groups: #{actual_sum}")
        end

        # Run children assertions, which return number of records. May raise.
        records = self.accounts.map {|a| a.send(:assert_integrity!, options) }.reduce(0, &:+)

        unless expectation[:records] == (actual_num_records = records + 2)
          raise IntegrityError.new(
            "Record count invalid: group: #{expectation[:records]}, accounts: #{actual_num_records}")
        end

        # Return record count
        actual_num_records
      end
    end


    class Account
      private

      def assert_integrity!(options)
        expectation = {
          sum:      @trailer[:account_control_total],
          records:  @trailer[:number_of_records],
        }

        # Check sum vs. summary + transaction sums
        summary_amounts_sum = self.summaries.map {|s| s[:amount] }.reduce(0, &:+)
        transaction_amounts_sum = self.transactions.map(&:amount).reduce(0, &:+)

        # Some banks differ from the spec (*cough* SVB) and do not include
        # the summary amounts in the control amount.
        actual_sum = if options[:account_control_ignores_summary_amounts]
                       transaction_amounts_sum
                     else
                       transaction_amounts_sum + summary_amounts_sum
                     end

        unless expectation[:sum] == actual_sum
          raise IntegrityError.new(
            "Sums invalid: expected: #{expectation[:sum]}, actual: #{actual_sum}")
        end

        # Run children assertions, which return number of records. May raise.
        records = self.transactions.map do |tx|
          tx.instance_variable_get(:@record).physical_record_count
        end.reduce(0, &:+)

        # Account for the account header and the account trailer records
        # and any additional summary records (Some banks use continuation records
        # for account summaries, others put the summary data on the same row as the header)
        trailer_records = 1
        additional_records = trailer_records + @header.physical_record_count
        actual_num_records = records + additional_records

        unless expectation[:records] == actual_num_records
          raise IntegrityError.new(
              "Record count invalid: account: #{expectation[:records]}, transactions: #{actual_num_records}")
        end

        # Return record count
        actual_num_records
      end
    end
  end
end
