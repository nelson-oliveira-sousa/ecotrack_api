module ApiResponder
  extend ActiveSupport::Concern

  private

  def respond_with_result(result, serializer: nil)
    render json: serialized_result(result, serializer),
           status: result.status
  end

  def serialized_result(result, serializer)
    Shared::Serializers::ApiResponseSerializer.render(
      success: result.success?,
      data: serialize_data(result.data, serializer),
      errors: result.errors
    )
  end

  def serialize_data(data, serializer)
    return nil if data.nil?

    if serializer
      serializer.render_as_hash(data)
    elsif data.respond_to?(:as_json)
      data.as_json
    else
      data
    end
  end
end
