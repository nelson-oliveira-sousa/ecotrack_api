class MqttBatchProcessorJob < ApplicationJob
  queue_as :default

  # Garante que apenas um worker processe esse lote por vez,
  # evitando que mensagens duplicadas ou fora de ordem causem inconsistência.
  limits_concurrency to: 1, key: "mqtt_batch_processor", duration: 5.minutes

  def perform
    # 1. Busca mensagens pendentes usando o scope e o prefixo de status
    messages = MqttMessage.status_new.ready_for_processing.limit(100)

    return if messages.empty?

    messages.each do |msg|
      process_message(msg)
    end

    # 2. Se ainda houver mensagens 'new', chama a si mesmo para continuar o fluxo
    MqttBatchProcessorJob.perform_later if MqttMessage.status_new.any?
  end

  private
  def process_message(msg)
    msg.status_processing!

    # tenant_code = msg.topic.split("/")[1]
    tenant_code = "MSPXRAKH" # FIXO PARA TESTE, DEPOIS VOLTA O DINÂMICO
    bin_id   = msg.payload["bin_id"]
    new_level   = msg.payload["level"]

    bin = Waste::Bin.joins(:tenant).find_by!(tenants: { code: tenant_code }, id: bin_id)

    batery_level = msg.payload["battery"] || 100

    # 🔥 ATUALIZAÇÃO SÊNIOR:
    # Usamos uma transação para garantir que ou salva tudo, ou nada.
    ActiveRecord::Base.transaction do
      # 1. Atualiza o "Estado Atual" (para o Dashboard ser rápido)
      bin.update!(level: new_level, battery: batery_level)

      # 2. Cria o "Histórico" (para a IA analisar)
      bin.readings.create!(
        level: new_level,
        status: bin.status, # O status já foi resolvido pelo callback before_save do bin,
        battery: batery_level
      )

      if bin.analysis_needed?
        Waste::AiAnalysisJob.perform_later(bin.id)
      end
    end

    msg.update!(status: :processed, processed_at: Time.current)
  rescue ActiveRecord::RecordNotFound
    # Erro específico: Evita travar o job se o ESP32 mandar lixo de um ID que não existe
    msg.update!(status: :failed, retry_count: msg.retry_count + 1)
    Rails.logger.error "❌ Lixeira ID #{payload['bin_id']} não encontrada para o tenant #{tenant_code}"
  rescue => e
    msg.update!(status: :failed, retry_count: msg.retry_count + 1)
    Rails.logger.error "❌ Erro no processamento: #{e.message}"
  end
end
