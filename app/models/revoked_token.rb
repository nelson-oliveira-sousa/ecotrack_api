# app/models/revoked_token.rb
class RevokedToken < ApplicationRecord
  validates :jti, presence: true, uniqueness: true
end
