module StatusCatalog
  module_function

  ALIASES = {
    in_route: :processing,
    active: :active,
    available: :active,
    online: :active,
    normal: :active,
    warning: :pending,
    critical: :critical,
    collected: :completed,
    planned: :pending,
    pending: :pending,
    new: :pending,
    resolved: :resolved,
    completed: :completed,
    cancelled: :cancelled,
    failed: :failed,
    maintenance: :maintenance,
    inactive: :inactive,
    offline: :inactive,
    suspended: :inactive,
    processing: :processing
  }.freeze

  def normalize(value)
    return nil if value.nil?

    ALIASES.fetch(value.to_sym, value.to_s.underscore.to_sym).to_s
  end
end
