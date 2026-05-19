# app/lib/result.rb
class Result
  attr_reader :data, :errors, :status

  def initialize(success:, data: nil, errors: [], status: :ok)
    @success = success
    @data = data
    @errors = normalize_errors(errors)
    @status = status
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def self.success(data: nil, status: :ok)
    new(success: true, data: data, status: status)
  end

  def self.failure(errors: [], status: :unprocessable_entity)
    new(success: false, errors: errors, status: status)
  end

  private

  def normalize_errors(errors)
    Array(errors).map do |error|
      case error
      when String
        { message: error }
      when Hash
        error
      else
        { message: error.to_s }
      end
    end
  end
end
