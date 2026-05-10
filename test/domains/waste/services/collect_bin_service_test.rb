require "test_helper"

module Waste
  module Services
    class CollectBinServiceTest < ActiveSupport::TestCase
      test "coleta lixeira e retorna Result padronizado" do
        bin = waste_bins(:one)
        bin.update!(level: 80, status: "critical", battery: 70)

        result = Waste::Services::CollectBinService.call(bin: bin)

        assert result.success?
        assert_equal :ok, result.status
        assert_equal 0, bin.reload.level
        assert_equal "collected", bin.status
        assert_equal "collected", bin.readings.last.status
      end
    end
  end
end
