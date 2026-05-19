module Shared
  module Serializers
    class ApiResponseSerializer
      class << self
        def render(success, data: nil, errors: [])
          {
            success: success,
            data: data,
            errors: errors
          }
        end
      end
    end
  end
end
