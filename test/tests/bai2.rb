require File.expand_path('../../autorun.rb', __FILE__)

require 'bai2'

class Bai2Test < Minitest::Test

  def setup
    @daily = Bai2::BaiFile.parse(File.expand_path('../../data/daily.bai2', __FILE__))
    @eod = Bai2::BaiFile.parse(File.expand_path('../../data/eod.bai2', __FILE__))
  end

  def test_parsing
    assert_kind_of(Bai2::BaiFile, @daily)
    assert_kind_of(Bai2::BaiFile, @eod)
  end
end
