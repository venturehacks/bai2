require File.expand_path('../../autorun.rb', __FILE__)

require 'bai2'

class Bai2Test < Minitest::Test

  def setup
    @daily = Bai2::BaiFile.parse(File.expand_path('../../data/daily.bai2', __FILE__))
    @daily_with_summary = Bai2::BaiFile.parse(File.expand_path('../../data/daily_with_summary.bai2', __FILE__))

    @eod = Bai2::BaiFile.parse(File.expand_path('../../data/eod.bai2', __FILE__))
    @eod_no_as_of_time = Bai2::BaiFile.parse(File.expand_path('../../data/eod_without_as_of_time.bai2', __FILE__))
    @eod_with_slash_in_continuation = Bai2::BaiFile.parse(File.expand_path('../../data/eod_with_slash_in_text.bai2', __FILE__),
                                                          continuations_slash_delimit_end_of_line_only: true)

    @all_files = [@daily, @daily_with_summary, @eod, @eod_no_as_of_time, @eod_with_slash_in_continuation]
  end

  def test_parsing
    @all_files.each do |file|
      assert_kind_of(Bai2::BaiFile, file)
    end
  end

  def test_groups
    @all_files.each do |file|
      assert_kind_of(Array, file.groups)
      assert_equal(1, file.groups.count)
      group = file.groups.first
      assert_kind_of(Bai2::BaiFile::Group, group)
      assert_equal('121140399', group.originator)
    end
    assert_equal('9999999999', @daily.groups[0].destination)
    assert_equal('3333333333', @eod.groups[0].destination)
  end

  def test_accounts
    @all_files.each do |file|
      accounts = file.groups.first.accounts
      assert_kind_of(Array, accounts)
      assert_equal(1, accounts.count)
      assert_kind_of(Bai2::BaiFile::Account, accounts.first)
    end
  end

  def test_transactions
    all_txs = [@daily, @eod].flat_map(&:groups).flat_map(&:accounts).flat_map(&:transactions)
    assert_equal(2, all_txs.count)
    all_txs.each do |tx|
      assert_kind_of(Bai2::BaiFile::Transaction, tx)
    end
    first, second = all_txs
    assert_equal(first.type, {
      code: 174,
      transaction: :credit,
      scope: :detail,
      description: 'Other Deposit'
    })
    assert_equal(second.type, {
      code: 195,
      transaction: :credit,
      scope: :detail,
      description: 'Incoming Money Transfer'
    })
  end

  def test_integrity
    assert_raises Bai2::BaiFile::IntegrityError do
      # An invalid amount of records should raise an error
      Bai2::BaiFile.parse(File.expand_path('../../data/daily_with_missing_continuation.bai2', __FILE__))
    end
    assert_raises Bai2::BaiFile::IntegrityError do
      # An invalid amount checksum should raise an error
      Bai2::BaiFile.parse(File.expand_path('../../data/invalid_checksum_eod.bai2', __FILE__))
    end
  end
end
