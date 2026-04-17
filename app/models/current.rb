# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  # Aqui definimos os atributos que queremos que fiquem
  # "pendurados" na thread da requisição.
  attribute :user, :tenant
end
