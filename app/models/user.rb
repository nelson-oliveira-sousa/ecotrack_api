# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  # 1. O vínculo agora é pelo ID (Chave Estrangeira)
  belongs_to :tenant

  enum :role, { admin: "admin", driver: "driver", manager: "manager" }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # 2. Mudança de :tenant_slug para :tenant_id no escopo de unicidade
  validates :email, uniqueness: { scope: :tenant_id }

  # 3. Validamos a presença do objeto tenant, não mais da string slug
  validates :tenant, presence: true

  # Sua validação de senha está perfeita, vamos mantê-la
  validates :password, format: {
    with: /\A(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}\z/,
    message: "deve conter pelo menos 8 caracteres, uma letra, um número e um caractere especial"
  }, if: -> { new_record? || !password.nil? }
end
