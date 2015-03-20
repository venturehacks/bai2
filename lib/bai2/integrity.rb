
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
      records = self.groups.map {|g| g.send(:assert_integrity!) }.reduce(0, &:+)

      unless expectation[:records] == (actual = records + 2)
        raise IntegrityError.new(
          "Record count invalid: file: #{expectation[:records]}, groups: #{actual}")
      end
    end


    public


    class Group
      private

      # Asserts integrity of a fully-parsed BaiFile by calculating checksums.
      #
      def assert_integrity!
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
        records = self.accounts.map {|a| a.send(:assert_integrity!) }.reduce(0, &:+)

        unless expectation[:records] == (actual = records + 2)
          raise IntegrityError.new(
            "Record count invalid: group: #{expectation[:records]}, accounts: #{actual}")
        end

        # Return record count
        records + 2
      end
    end


    class Account
      private

      def assert_integrity!
        expectation = {
          sum:      @trailer[:account_control_total],
          records:  @trailer[:number_of_records],
        }

        # Check sum vs. summary + transaction sums
        actual_sum = self.transactions.map(&:amount).reduce(0, &:+) \
          #+ self.summaries.map {|s| s[:amount] }.reduce(0, &:+)
          # TODO: ^ there seems to be a disconnect between what the spec defines
          # as the formula for the checksum and what SVB implements...

        unless expectation[:sum] == actual_sum
          raise IntegrityError.new(
            "Sums invalid: expected: #{expectation[:sum]}, actual: #{actual_sum}")
        end

        # Run children assertions, which return number of records. May raise.
        records = self.transactions.map do |tx|
          tx.instance_variable_get(:@record).physical_record_count
        end.reduce(0, &:+)

        unless expectation[:records] == (actual = records + 2)
          raise IntegrityError.new("Record count invalid: " \
            + "account: #{expectation[:records]}, transactions: #{actual}")
        end

        # Return record count
        records + 2
      end
    end
  end
end
