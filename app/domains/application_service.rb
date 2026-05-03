class ApplicationService
  def self.call(...)
    new(...).call
  end

  protected

  def success(data: nil, status: :ok)
    Result.new(success: true, data: data, status: status)
  end

  def failure(error: "Ocorreu um erro inesperado", status: :unprocessable_entity)
    Result.new(success: false, error: error, status: status)
  end
end
