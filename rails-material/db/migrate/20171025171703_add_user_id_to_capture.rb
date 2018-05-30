class AddUserIdToCapture < ActiveRecord::Migration[5.1]
  def change
  	add_column :captures, :user_id, :integer
  	add_column :captures, :privacy, :integer, :default => 0
  end
end
