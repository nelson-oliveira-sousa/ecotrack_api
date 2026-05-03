# app/controllers/concerns/api_responder.rb
module ApiResponder
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

    # Dica Sênior: Se resgatar StandardError no ambiente de desenvolvimento,
    # você perde a tela vermelha do Rails que ajuda no debug.
    # O ideal é habilitar isso só em produção/staging.
    rescue_from StandardError, with: :internal_server_error unless Rails.env.development?
  end

  # Helper global para renderizar o objeto Result dos Services
  def render_result(result)
    render json: {
      success: result.success?,
      data: result.data,
      error: result.error
    }, status: result.status
  end

  private

  def record_not_found(exception)
    render json: {
      success: false,
      data: nil,
      error: "Registro não encontrado: #{exception.model}"
    }, status: :not_found
  end

  def record_invalid(exception)
    render json: {
      success: false,
      data: nil,
      error: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def internal_server_error(exception)
    # Sempre logue o erro real antes de mascará-lo para o usuário
    Rails.logger.error("[ServerError] #{exception.message}\n#{exception.backtrace.first(10).join("\n")}")

    render json: {
      success: false,
      data: nil,
      error: "Ocorreu um erro interno no servidor." # Nunca vaze detalhes técnicos (exception.message) para o client
    }, status: :internal_server_error
  end
end
