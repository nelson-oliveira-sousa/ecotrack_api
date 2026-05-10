module Api
  module V1
    class ShiftsController < ApiController
      def index
        render_result(Result.new(success: true, data: []))
      end
    end
  end
end
