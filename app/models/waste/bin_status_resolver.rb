# app/models/waste/bin_status_resolver.rb
module Waste
  class BinStatusResolver
    RULES = {
      critical: 80..100,
      warning: 50..79,
      normal: 0..49
    }.freeze

    def self.call(level, last_reading_at: nil)
      return :offline if offline?(last_reading_at)

      # Procura qual range cobre o nível atual
      status = RULES.find { |_status, range| range.cover?(level) }&.first
      status || :normal
    end

    private

    def self.offline?(last_reading_at)
      return false unless last_reading_at
      last_reading_at < 15.minutes.ago
    end
  end
end
