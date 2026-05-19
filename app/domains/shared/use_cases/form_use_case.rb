# app/domains/shared/use_cases/form_use_case.rb
module Shared
  module UseCases
    class FormUseCase
      class << self
        def call(params = {})
          # O form_class é definido nas subclasses (ex: CreateTruck)
          form = form_class.new(params)

          return Result.success(resource_from(form), status: success_status) if form.save
          # Retorna Falha formatando os erros para o padrão { field, message }
          Result.failure(format_errors(form), status: :unprocessable_entity)
        end

        private

        # Retorna o objeto ActiveRecord através do alias 'resource' definido no Form
        def resource_from(form)
          form.resource
        end

        # Formata os erros do ActiveModel para o padrão da sua API
        def format_errors(form)
          form.errors.map do |error|
            {
              field: error.attribute,
              message: error.message
            }
          end
        end

        # Status padrão de sucesso (pode ser sobrescrito para :created)
        def success_status
          :ok
        end

        # Este método DEVE ser implementado na subclasse
        def form_class
          raise NotImplementedError, "#{self.name} deve implementar o método form_class"
        end
      end
    end
  end
end
