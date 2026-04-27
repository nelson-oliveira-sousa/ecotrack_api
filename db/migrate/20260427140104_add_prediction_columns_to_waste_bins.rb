class AddPredictionColumnsToWasteBins < ActiveRecord::Migration[8.1]
  def change
    add_column :waste_bins, :ai_prediction, :text
    add_column :waste_bins, :predicted_full_at, :datetime
    add_column :waste_bins, :last_analysis_at, :datetime
  end
end
