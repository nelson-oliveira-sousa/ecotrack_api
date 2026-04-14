module Telemetry
  class RawReading < ApplicationRecord
    belongs_to :waste_bin, class_name: "Waste::Bin"
    validates :level, presence: true
  end
end
