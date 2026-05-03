# app/lib/result.rb
class Result
  attr_reader :data, :error, :status

  def initialize(success:, data: nil, error: nil, status: :ok)
    @success = success
    @data = data
    @error = error
    @status = status
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def to_h
    {
      success: success?,
      data: data,
      error: error
    }
  end
end
