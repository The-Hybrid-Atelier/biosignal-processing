class CaptureToParticipant < ActiveRecord::Migration[5.1]
  def change
  	rename_column :captures, :user_id, :participant_id
  end
end
