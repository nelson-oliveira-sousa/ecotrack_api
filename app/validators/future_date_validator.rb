# app/validators/future_date_validator.rb
class FutureDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    begin
      date = value.is_a?(Date) ? value : Date.parse(value.to_s)

      if date < Date.current
        record.errors.add(attribute, (options[:message] || "está vencido(a)"))
      end

      if options[:limit] && date > options[:limit].from_now.to_date
        record.errors.add(attribute, "está muito distante no futuro")
      end
    rescue ArgumentError
      record.errors.add(attribute, "não é uma data válida")
    end
  end
end
