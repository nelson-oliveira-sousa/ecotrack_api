class ApplicationService
  def self.call(*args, **kwargs, &block)
    new(*args, **kwargs, &block).call
  end

  protected

  def success(data = nil, status = :ok)
    Result.new(success: true, data: data, status: status)
  end

  def failure(error, status = :unprocessable_entity)
    Result.new(success: false, error: error, status: status)
  end
end
