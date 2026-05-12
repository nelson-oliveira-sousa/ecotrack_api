# app/adapters/stream/postgres_client.rb
module Stream
  class PostgresClient
    PING_INTERVAL = 5 # Segundos

    def self.listen(channel:, stream:)
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.execute("LISTEN #{channel}")

        begin
          loop do
            # Aguarda eventos no canal
            connection.raw_connection.wait_for_notify(PING_INTERVAL) do |event, pid, payload|
              stream.write("event: alert\n")
              stream.write("data: #{payload}\n\n")
            end

            # Heartbeat para evitar que o Nginx/Proxy feche a ligação por inatividade
            stream.write("event: ping\ndata: {}\n\n")
          end
        rescue IOError, ActionController::Live::ClientDisconnected
          Rails.logger.info "[SSE] Cliente desconectado do canal: #{channel}"
        ensure
          connection.execute("UNLISTEN #{channel}")
          stream.close
        end
      end
    end

    def self.broadcast(channel:, payload:)
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        escaped_payload = connection.raw_connection.escape_string(payload.to_json)
        connection.execute("NOTIFY #{channel}, '#{escaped_payload}'")
      end
    end
  end
end
