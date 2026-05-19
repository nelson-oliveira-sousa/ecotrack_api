# app/domains/fleet/forms/truck_form.rb
module Fleet
  module Forms
    class TruckForm
      include ActiveModel::Model

      attr_accessor :id, :tenant_id, :plate, :model, :capacity,
                    :renavam, :manufacture_year, :document_expiration_date

      attr_reader :truck

      alias resource truck

      # Validações de presença obrigatória
      validates :plate, :model, :capacity, :tenant_id, :manufacture_year, presence: true

      # Validações customizadas baseadas nas regras enviadas
      validate :validate_renavam
      validate :validate_mercosul_plate
      validates :document_expiration_date, future_date: { limit: 10.years }

      def save
        return false unless valid?

        # Busca o caminhão existente ou inicia um novo dentro do tenant
        @truck = find_or_initialize_truck
        return false if id.present? && @truck.nil?

        @truck.assign_attributes(truck_attributes)

        return true if @truck.save

        errors.merge!(@truck.errors)
        false
      end

      private

      def find_or_initialize_truck
        return Fleet::Truck.find_by(id: id, tenant_id: tenant_id) if id.present?

        Fleet::Truck.new(tenant_id: tenant_id)
      end

      def truck_attributes
        {
          tenant_id: tenant_id,
          plate: plate&.upcase&.gsub(/[^A-Z0-9]/, ""), # Limpa formatação da placa
          model: model,
          capacity: capacity,
          renavam: renavam&.gsub(/\D/, ""), # Mantém apenas números no RENAVAM
          manufacture_year: manufacture_year,
          document_expiration_date: document_expiration_date
        }
      end

      def validate_renavam
        return if renavam.blank?
        digits = renavam.gsub(/\D/, "")

        unless digits.length == 11
          errors.add(:renavam, "must contain 11 digits")
          return
        end

        base = digits[0, 10].chars.map(&:to_i)
        multipliers = [ 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ]
        sum = base.each_with_index.sum { |digit, index| digit * multipliers[index] }

        remainder = sum % 11
        check_digit = 11 - remainder
        check_digit = 0 if check_digit >= 10

        errors.add(:renavam, "is invalid") unless check_digit == digits[-1].to_i
      end

      def validate_mercosul_plate
        return if plate.blank?
        normalized = plate.upcase.gsub(/[^A-Z0-9]/, "")
        pattern = /\A[A-Z]{3}[0-9][A-Z][0-9]{2}\z/

        errors.add(:plate, "must be a valid Mercosul plate (ABC1D23)") unless normalized.match?(pattern)
      end
    end
  end
end
