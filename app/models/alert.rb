# app/models/alert.rb
class Alert < ApplicationRecord
  belongs_to :tenant
  belongs_to :alertable, polymorphic: true, optional: true

  enum :severity, { info: 0, warning: 1, critical: 2 }, default: :warning
  enum :status, { pending: 0, resolved: 1 }, default: :pending
  enum :category, { bin_full: 0, low_battery: 1, truck_issue: 2, system: 3 }
end
