module Identity
  class PasswordFormatValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      return if value.blank?

      unless value.match?(/\A(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}\z/)
        record.errors.add(attribute, options[:message] || "deve conter pelo menos 8 caracteres, uma letra, um número e um caractere especial")
      end
    end
  end
end
