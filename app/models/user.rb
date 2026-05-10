# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  belongs_to :tenant, optional: true

  enum :role, {
    super_admin: "super_admin",
    vendedor:    "vendedor",
    suporte:     "suporte",

    admin:       "admin",
    manager:     "manager",
    driver:      "driver",
    collector:   "collector"
  }

  enum :status, {
    active: 1,
    inactive: 2,
    suspended: 0
  }, default: :active

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { scope: :tenant_id }
  validates :name, presence: true
  validates :force_password_change, inclusion: { in: [ true, false ] }

  validates_with Identity::Validators::PasswordFormatValidator, attributes: [ :password ], if: -> { new_record? || !password.nil? }

  def system_user?
    super_admin? || vendedor? || suporte?
  end

  def tenant_user?
    admin? || manager? || driver? || collector?
  end
end
