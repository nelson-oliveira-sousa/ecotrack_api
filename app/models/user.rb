class User < ApplicationRecord
  has_secure_password

  enum :role, { admin: "admin", driver: "driver", manager: "manager" }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :tenant_slug }
  validates :tenant_slug, presence: true

  # Exige mínimo de 8 caracteres, uma letra, um número e um caractere especial (só na criação ou troca de senha)
  validates :password, format: {
    with: /\A(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}\z/,
    message: "deve conter pelo menos 8 caracteres, uma letra, um número e um caractere especial"
  }, if: -> { new_record? || !password.nil? }
end
